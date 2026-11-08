"""Registered phones: one UnifiedPush endpoint (and its WebPush keys) per device.

Shared by the gateway hooks and the dashboard routes, which can run in
different processes, so the registry is a small JSON file replaced atomically.
"""

from __future__ import annotations

import ipaddress
import json
import os
import re
import tempfile
import threading
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Optional
from urllib.parse import urlsplit

DEVICE_ID = re.compile(r"^[A-Za-z0-9_-]{8,64}$")
MAX_DEVICES = 8
MAX_ENDPOINT_LENGTH = 2048
MAX_LABEL_LENGTH = 60
_lock = threading.Lock()


class DeviceError(ValueError):
    """Rejected registration; the message is safe to show to the person."""


@dataclass
class Device:
    id: str
    endpoint: str
    label: str = ""
    p256dh: str = ""
    auth: str = ""
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)

    def public(self) -> dict:
        """What the dashboard returns: never the keys, only the endpoint host."""
        return {
            "id": self.id,
            "label": self.label,
            "endpoint_host": urlsplit(self.endpoint).hostname or "",
            "encrypted": bool(self.p256dh and self.auth),
            "created_at": self.created_at,
            "updated_at": self.updated_at,
        }


def _private_host(host: str) -> bool:
    if host == "localhost" or host.endswith(".ts.net") or host.endswith(".local"):
        return True
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        return False
    # 100.64.0.0/10 is the Tailscale CGNAT range.
    return address.is_private or address.is_loopback or address in ipaddress.ip_network("100.64.0.0/10")


def validate_endpoint(endpoint: str) -> str:
    endpoint = (endpoint or "").strip()
    if not endpoint or len(endpoint) > MAX_ENDPOINT_LENGTH:
        raise DeviceError("Endpoint de push ausente ou longo demais.")
    parts = urlsplit(endpoint)
    host = (parts.hostname or "").lower()
    if not host or parts.username or parts.password:
        raise DeviceError("Endpoint de push inválido.")
    if parts.scheme == "https":
        return endpoint
    if parts.scheme == "http" and _private_host(host):
        return endpoint
    raise DeviceError("O endpoint de push precisa ser https (http só em rede privada).")


class DeviceStore:
    def __init__(self, path: Path):
        self.path = path

    @classmethod
    def default(cls) -> "DeviceStore":
        from hermes_constants import get_hermes_home
        return cls(get_hermes_home() / "mobile-push" / "devices.json")

    def _read(self) -> list[Device]:
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            return []
        except (OSError, ValueError):
            return []
        devices = []
        for item in raw.get("devices", []) if isinstance(raw, dict) else []:
            try:
                devices.append(Device(**{k: item[k] for k in Device.__dataclass_fields__ if k in item}))
            except (TypeError, KeyError):
                continue
        return devices

    def _write(self, devices: list[Device]) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        payload = json.dumps({"version": 1, "devices": [asdict(d) for d in devices]}, indent=2)
        fd, tmp = tempfile.mkstemp(dir=self.path.parent, prefix=".devices-", suffix=".json")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                handle.write(payload)
            os.chmod(tmp, 0o600)
            os.replace(tmp, self.path)
        except BaseException:
            try:
                os.unlink(tmp)
            except OSError:
                pass
            raise

    def all(self) -> list[Device]:
        with _lock:
            return self._read()

    def get(self, device_id: str) -> Optional[Device]:
        return next((d for d in self.all() if d.id == device_id), None)

    def upsert(self, device_id: str, *, endpoint: str, label: str = "",
               p256dh: str = "", auth: str = "") -> Device:
        if not DEVICE_ID.match(device_id or ""):
            raise DeviceError("Identificador de aparelho inválido.")
        endpoint = validate_endpoint(endpoint)
        label = " ".join((label or "").split())[:MAX_LABEL_LENGTH]
        if bool(p256dh) != bool(auth):
            raise DeviceError("Chaves de criptografia incompletas.")
        with _lock:
            devices = self._read()
            current = next((d for d in devices if d.id == device_id), None)
            if current is None:
                if len(devices) >= MAX_DEVICES:
                    raise DeviceError(f"Limite de {MAX_DEVICES} aparelhos atingido.")
                current = Device(id=device_id, endpoint=endpoint)
                devices.append(current)
            current.endpoint, current.label = endpoint, label
            current.p256dh, current.auth = p256dh or "", auth or ""
            current.updated_at = time.time()
            self._write(devices)
            return current

    def remove(self, device_id: str, *, endpoint: str | None = None) -> bool:
        """Drop a device. With ``endpoint``, only if it still points there, so a
        stale 410 cannot remove a registration the phone has since renewed."""
        with _lock:
            devices = self._read()
            kept = [d for d in devices
                    if d.id != device_id or (endpoint is not None and d.endpoint != endpoint)]
            if len(kept) == len(devices):
                return False
            self._write(kept)
            return True
