"""Turn and human-input events -> minimal push envelopes for registered phones.

Event selection follows hermes-signal-notify (MIT, Drew Brosnan): one push per
``turn_id``, toggles per event, platforms to skip. Unlike it, nothing the agent
or the person wrote leaves the server: the envelope names the event, the
session and, optionally, the conversation title. The app shows the rest only
after an authenticated read.
"""

from __future__ import annotations

import json
import logging
import threading
import time
import uuid
from collections import OrderedDict
from collections.abc import Callable
from typing import Any, Optional

from .devices import Device, DeviceStore
from .webpush import DeliveryResult, deliver

logger = logging.getLogger("mobile_push")

ENVELOPE_VERSION = 1
MAX_TRACKED = 64
MAX_TITLE_CHARS = 80
FALSE_WORDS = {"", "0", "false", "off", "no"}
DEFAULTS: dict[str, Any] = {
    "notify_completed": True,
    "notify_failed": True,
    "notify_interrupted": False,
    "notify_input": True,
    "include_title": True,
    "skip_platforms": ["cron", "subagent"],
}
TURN_TOGGLES = {
    "turn.completed": "notify_completed",
    "turn.failed": "notify_failed",
    "turn.interrupted": "notify_interrupted",
}
INPUT_KINDS = {"approval", "clarify", "sudo"}


def as_bool(value: Any, default: bool) -> bool:
    if isinstance(value, str):
        return value.strip().lower() not in FALSE_WORDS
    return default if value is None else bool(value)


def as_list(value: Any, default: list) -> list:
    if isinstance(value, str):
        return [part.strip() for part in value.split(",") if part.strip()]
    if isinstance(value, (list, tuple, set)):
        return [str(part).strip() for part in value]
    return list(default)


def turn_kind(completed: bool, failed: bool, interrupted: bool) -> str:
    if failed or not (completed or interrupted):
        return "turn.failed"
    return "turn.interrupted" if interrupted else "turn.completed"


def envelope(kind: str, session_id: str, *, title: Optional[str] = None,
             input_kind: Optional[str] = None, request_id: Optional[str] = None,
             now: Optional[float] = None) -> dict[str, Any]:
    body: dict[str, Any] = {
        "v": ENVELOPE_VERSION,
        "id": uuid.uuid4().hex,
        "kind": kind,
        "session_id": session_id,
        "ts": int(now if now is not None else time.time()),
    }
    if title:
        body["title"] = " ".join(title.split())[:MAX_TITLE_CHARS]
    if input_kind:
        body["input"] = input_kind
    if request_id:
        body["request_id"] = request_id
    return body


def _remember(store: "OrderedDict[str, Any]", key: str, value: Any = True) -> None:
    store[key] = value
    store.move_to_end(key)
    while len(store) > MAX_TRACKED:
        store.popitem(last=False)


def _session_title(session_id: str) -> Optional[str]:
    db = None
    try:
        from hermes_state import SessionDB
        db = SessionDB(read_only=True)
        return db.get_session_title(session_id)
    except Exception:  # an absent title is fine; a broken DB must not stop the push
        logger.debug("mobile-push: title lookup failed", exc_info=True)
        return None
    finally:
        if db is not None:
            try:
                db.close()
            except Exception:
                pass


Sender = Callable[[Device, bytes, str], DeliveryResult]


def _send(device: Device, payload: bytes, urgency: str) -> DeliveryResult:
    return deliver(device.endpoint, payload, p256dh=device.p256dh, auth=device.auth, urgency=urgency)


class Notifier:
    def __init__(
        self,
        get_config: Callable[[str, Any], Any],
        store: Optional[DeviceStore] = None,
        sender: Sender = _send,
        title_lookup: Callable[[str], Optional[str]] = _session_title,
        background: bool = True,
    ):
        self._get_config = get_config
        self._store = store
        self._sender = sender
        self._title_lookup = title_lookup
        self._background = background
        self._reported_turns: OrderedDict[str, bool] = OrderedDict()
        self._pending_inputs: OrderedDict[str, bool] = OrderedDict()
        self._lock = threading.Lock()

    def _devices(self) -> DeviceStore:
        if self._store is None:
            self._store = DeviceStore.default()
        return self._store

    def _setting(self, key: str) -> Any:
        value = self._get_config(key, DEFAULTS[key])
        if key == "skip_platforms":
            return as_list(value, DEFAULTS[key])
        return as_bool(value, DEFAULTS[key])

    def _skipped(self, platform: str) -> bool:
        return (platform or "").lower() in {p.lower() for p in self._setting("skip_platforms")}

    def _title(self, session_id: str) -> Optional[str]:
        if not self._setting("include_title"):
            return None
        return self._title_lookup(session_id)

    def _publish(self, body: dict[str, Any], urgency: str) -> None:
        devices = self._devices().all()
        if not devices:
            return
        payload = json.dumps(body, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        if not self._background:
            self._deliver_all(devices, payload, urgency, body["kind"])
            return
        threading.Thread(
            target=self._deliver_all, args=(devices, payload, urgency, body["kind"]),
            name="mobile-push", daemon=True,
        ).start()

    def _deliver_all(self, devices: list[Device], payload: bytes, urgency: str, kind: str) -> None:
        for device in devices:
            result = self._sender(device, payload, urgency)
            if result.gone:
                self._devices().remove(device.id, endpoint=device.endpoint)
                logger.info("mobile-push: endpoint gone, device %s removed", device.id[-6:])
            elif not result.ok:
                logger.warning("mobile-push: %s to device %s failed (HTTP %s)", kind, device.id[-6:], result.status)

    def on_session_end(
        self,
        session_id: str = "",
        completed: bool = False,
        failed: bool = False,
        interrupted: bool = False,
        platform: str = "",
        turn_id: Optional[str] = None,
        **_: Any,
    ) -> None:
        if not session_id or not turn_id:
            return
        with self._lock:
            if turn_id in self._reported_turns:
                return
            _remember(self._reported_turns, turn_id)
        kind = turn_kind(completed, failed, interrupted)
        if self._skipped(platform) or not self._setting(TURN_TOGGLES[kind]):
            return
        self._publish(envelope(kind, session_id, title=self._title(session_id)), "normal")

    def on_human_input_request(
        self, kind: str = "", request_id: str = "", session_id: str = "", platform: str = "", **_: Any
    ) -> None:
        if kind not in INPUT_KINDS or not request_id or not session_id:
            return
        if self._skipped(platform) or not self._setting("notify_input"):
            return
        with self._lock:
            _remember(self._pending_inputs, request_id)
        body = envelope("input.requested", session_id, title=self._title(session_id),
                        input_kind=kind, request_id=request_id)
        self._publish(body, "high")

    def on_human_input_resolved(self, request_id: str = "", session_id: str = "", **_: Any) -> None:
        with self._lock:
            if self._pending_inputs.pop(request_id, None) is None:
                return
        self._publish(envelope("input.resolved", session_id, request_id=request_id), "normal")
