"""``uv run --no-project --with cryptography --with fastapi --with httpx python -m unittest discover tests``."""

import importlib.util
import sys
import tempfile
import types
import unittest
from pathlib import Path

try:
    from fastapi import FastAPI
    from fastapi.testclient import TestClient
except ImportError:  # pragma: no cover
    FastAPI = None

API_FILE = Path(__file__).resolve().parent.parent / "dashboard" / "plugin_api.py"
ENDPOINT = "https://ntfy.example.org/upAbCdEf123?up=1"


@unittest.skipIf(FastAPI is None, "fastapi not installed")
class PluginApiTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        fake = types.ModuleType("hermes_constants")
        fake.get_hermes_home = lambda: Path(self.tmp.name)
        sys.modules["hermes_constants"] = fake
        spec = importlib.util.spec_from_file_location("plugin_api_under_test", API_FILE)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.api = module
        app = FastAPI()
        app.include_router(module.router, prefix="/api/plugins/mobile-push")
        self.client = TestClient(app)

    def tearDown(self):
        sys.modules.pop("hermes_constants", None)
        self.tmp.cleanup()

    def test_register_list_and_remove(self):
        put = self.client.put("/api/plugins/mobile-push/devices/phone-0001",
                              json={"endpoint": ENDPOINT, "label": "Pixel", "p256dh": "k", "auth": "a"})
        self.assertEqual(put.status_code, 200)
        self.assertTrue(put.json()["encrypted"])
        listed = self.client.get("/api/plugins/mobile-push/devices").json()
        self.assertEqual([d["id"] for d in listed["devices"]], ["phone-0001"])
        self.assertNotIn("p256dh", listed["devices"][0])
        self.assertEqual(self.client.delete("/api/plugins/mobile-push/devices/phone-0001").json(),
                         {"removed": True})
        self.assertEqual(self.client.get("/api/plugins/mobile-push/devices").json()["devices"], [])

    def test_rejected_endpoint_is_400_with_message(self):
        response = self.client.put("/api/plugins/mobile-push/devices/phone-0001",
                                   json={"endpoint": "http://ntfy.sh/upX"})
        self.assertEqual(response.status_code, 400)
        self.assertIn("https", response.json()["detail"])

    def test_test_push_for_unknown_device_is_404(self):
        self.assertEqual(self.client.post("/api/plugins/mobile-push/devices/phone-0404/test").status_code, 404)

    def test_test_push_reports_delivery_result(self):
        self.client.put("/api/plugins/mobile-push/devices/phone-0001", json={"endpoint": ENDPOINT})
        sent = []

        def fake_deliver(endpoint, payload, **_):
            sent.append(payload)
            return self.api.webpush.DeliveryResult(410, False)

        original = self.api.webpush.deliver
        self.api.webpush.deliver = fake_deliver
        try:
            result = self.client.post("/api/plugins/mobile-push/devices/phone-0001/test").json()
        finally:
            self.api.webpush.deliver = original
        self.assertEqual(result, {"ok": False, "status": 410, "encrypted": False, "gone": True})
        self.assertIn(b'"kind":"test"', sent[0])
        self.assertEqual(self.client.get("/api/plugins/mobile-push/devices").json()["devices"], [])


if __name__ == "__main__":
    unittest.main()
