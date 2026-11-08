"""Device registration for mobile-push, mounted at ``/api/plugins/mobile-push/``.

These routes sit behind the dashboard login, so only a signed-in Hermes Mobile
can point the agent's notifications at a phone.
"""

from __future__ import annotations

import importlib.util
import json
import sys
import time
import uuid
from pathlib import Path

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

_PLUGIN_DIR = Path(__file__).resolve().parent.parent


def _load(name: str):
    module_name = f"_hermes_mobile_push_{name}"
    if module_name in sys.modules:
        return sys.modules[module_name]
    spec = importlib.util.spec_from_file_location(module_name, _PLUGIN_DIR / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


devices = _load("devices")
webpush = _load("webpush")

router = APIRouter()


class DeviceIn(BaseModel):
    endpoint: str = Field(max_length=devices.MAX_ENDPOINT_LENGTH)
    label: str = Field(default="", max_length=200)
    p256dh: str = Field(default="", max_length=200)
    auth: str = Field(default="", max_length=100)


def _store():
    return devices.DeviceStore.default()


@router.get("/devices")
def list_devices() -> dict:
    return {
        "version": 1,
        "encryption": webpush.encryption_available(),
        "devices": [d.public() for d in _store().all()],
    }


@router.put("/devices/{device_id}")
def register_device(device_id: str, body: DeviceIn) -> dict:
    try:
        device = _store().upsert(device_id, endpoint=body.endpoint, label=body.label,
                                 p256dh=body.p256dh, auth=body.auth)
    except devices.DeviceError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from None
    return device.public()


@router.delete("/devices/{device_id}")
def remove_device(device_id: str) -> dict:
    return {"removed": _store().remove(device_id)}


@router.post("/devices/{device_id}/test")
def test_device(device_id: str) -> dict:
    device = _store().get(device_id)
    if device is None:
        raise HTTPException(status_code=404, detail="Aparelho não registrado.")
    payload = json.dumps({"v": 1, "id": uuid.uuid4().hex, "kind": "test", "ts": int(time.time())},
                         separators=(",", ":")).encode("utf-8")
    result = webpush.deliver(device.endpoint, payload, p256dh=device.p256dh, auth=device.auth)
    if result.gone:
        _store().remove(device.id, endpoint=device.endpoint)
    return {"ok": result.ok, "status": result.status, "encrypted": result.encrypted, "gone": result.gone}
