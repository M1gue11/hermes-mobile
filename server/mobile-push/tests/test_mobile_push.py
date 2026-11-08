"""Run from the plugin directory: ``uv run --no-project --with cryptography python -m unittest discover tests``."""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

PLUGIN_DIR = Path(__file__).resolve().parent.parent


def _load_package():
    name = "mobile_push_under_test"
    if name in sys.modules:
        return sys.modules[name]
    spec = importlib.util.spec_from_file_location(
        name, PLUGIN_DIR / "__init__.py", submodule_search_locations=[str(PLUGIN_DIR)])
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


pkg = _load_package()
devices = sys.modules["mobile_push_under_test.devices"]
notifier_mod = sys.modules["mobile_push_under_test.notifier"]
webpush = sys.modules["mobile_push_under_test.webpush"]

ENDPOINT = "https://ntfy.example.org/upAbCdEf123?up=1"


def decrypt(body: bytes, ua_private, auth_secret: bytes) -> bytes:
    """Receiver side of RFC 8291, the counterpart the phone's connector runs."""
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    from cryptography.hazmat.primitives.kdf.hkdf import HKDF

    salt, idlen = body[:16], body[20]
    as_public = body[21:21 + idlen]
    ciphertext = body[21 + idlen:]
    ua_public = ua_private.public_key().public_bytes(
        serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint)
    secret = ua_private.exchange(
        ec.ECDH(), ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), as_public))

    def hkdf(s, info, n, ikm):
        return HKDF(algorithm=hashes.SHA256(), length=n, salt=s, info=info).derive(ikm)

    ikm = hkdf(auth_secret, b"WebPush: info\x00" + ua_public + as_public, 32, secret)
    cek = hkdf(salt, b"Content-Encoding: aes128gcm\x00", 16, ikm)
    nonce = hkdf(salt, b"Content-Encoding: nonce\x00", 12, ikm)
    plain = AESGCM(cek).decrypt(nonce, ciphertext, None)
    return plain.rstrip(b"\x00")[:-1]


@unittest.skipUnless(webpush.encryption_available(), "cryptography not installed")
class WebPushTest(unittest.TestCase):
    def test_rfc8291_appendix_a_vector(self):
        from cryptography.hazmat.primitives.asymmetric import ec

        as_private = ec.derive_private_key(
            int.from_bytes(webpush.b64url_decode("yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw"), "big"),
            ec.SECP256R1())
        body = webpush.encrypt(
            b"When I grow up, I want to be a watermelon",
            "BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4",
            "BTBZMqHH6r4Tts7J_aSIgg",
            salt=webpush.b64url_decode("DGv6ra1nlYgDCS1FRnbzlw"),
            private_key=as_private,
        )
        self.assertEqual(
            webpush.b64url_encode(body),
            "DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLoc"
            "InmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLV"
            "WGNWQexSgSxsj_Qulcy4a-fN",
        )

    def test_round_trip_with_fresh_keys(self):
        import os
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric import ec

        ua_private = ec.generate_private_key(ec.SECP256R1())
        p256dh = webpush.b64url_encode(ua_private.public_key().public_bytes(
            serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint))
        auth = os.urandom(16)
        payload = json.dumps({"kind": "turn.completed", "session_id": "s1"}).encode()
        body = webpush.encrypt(payload, p256dh, webpush.b64url_encode(auth))
        self.assertNotIn(b"turn.completed", body)
        self.assertEqual(decrypt(body, ua_private, auth), payload)

    def test_request_is_encrypted_only_with_both_keys(self):
        request, encrypted = webpush.build_request(ENDPOINT, b"{}")
        self.assertFalse(encrypted)
        self.assertEqual(request.get_header("Content-type"), "application/json")


class DeviceStoreTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.store = devices.DeviceStore(Path(self.tmp.name) / "devices.json")

    def tearDown(self):
        self.tmp.cleanup()

    def test_upsert_round_trips_and_hides_keys(self):
        self.store.upsert("phone-0001", endpoint=ENDPOINT, label="  Meu   Pixel ", p256dh="k", auth="a")
        self.store.upsert("phone-0001", endpoint=ENDPOINT + "x", label="Pixel")
        [device] = self.store.all()
        self.assertEqual(device.endpoint, ENDPOINT + "x")
        self.assertEqual(device.p256dh, "")
        public = device.public()
        self.assertEqual(public["endpoint_host"], "ntfy.example.org")
        self.assertNotIn("p256dh", public)
        self.assertNotIn("endpoint", public)

    def test_endpoint_rules(self):
        for ok in (ENDPOINT, "http://100.101.102.103/upX?up=1", "http://ntfy.tail1234.ts.net/upX",
                   "http://192.168.0.10:8080/upX"):
            self.assertEqual(devices.validate_endpoint(ok), ok)
        for bad in ("http://ntfy.sh/upX", "ftp://x/y", "https://user:pw@ntfy.sh/upX", "", "https://"):
            with self.assertRaises(devices.DeviceError):
                devices.validate_endpoint(bad)

    def test_rejects_bad_ids_half_keys_and_too_many_devices(self):
        with self.assertRaises(devices.DeviceError):
            self.store.upsert("../etc", endpoint=ENDPOINT)
        with self.assertRaises(devices.DeviceError):
            self.store.upsert("phone-0001", endpoint=ENDPOINT, p256dh="only")
        for i in range(devices.MAX_DEVICES):
            self.store.upsert(f"phone-{i:04d}", endpoint=ENDPOINT)
        with self.assertRaises(devices.DeviceError):
            self.store.upsert("phone-9999", endpoint=ENDPOINT)

    def test_remove_with_endpoint_guard_keeps_renewed_registration(self):
        self.store.upsert("phone-0001", endpoint=ENDPOINT + "new")
        self.assertFalse(self.store.remove("phone-0001", endpoint=ENDPOINT))
        self.assertTrue(self.store.remove("phone-0001", endpoint=ENDPOINT + "new"))
        self.assertEqual(self.store.all(), [])

    def test_corrupt_file_reads_as_empty(self):
        self.store.path.write_text("{not json", encoding="utf-8")
        self.assertEqual(self.store.all(), [])


class NotifierTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.store = devices.DeviceStore(Path(self.tmp.name) / "devices.json")
        self.store.upsert("phone-0001", endpoint=ENDPOINT)
        self.config = {}
        self.sent = []
        self.status = 201

        def sender(device, payload, urgency):
            self.sent.append((device.id, json.loads(payload), urgency))
            return webpush.DeliveryResult(self.status, False)

        self.notifier = notifier_mod.Notifier(
            lambda key, default: self.config.get(key, default),
            store=self.store, sender=sender, title_lookup=lambda sid: "Refatorar  backup",
            background=False,
        )

    def tearDown(self):
        self.tmp.cleanup()

    def end(self, **kwargs):
        base = {"session_id": "sess-1", "turn_id": "turn-1", "completed": True, "platform": "tui"}
        self.notifier.on_session_end(**{**base, **kwargs})

    def test_completed_turn_sends_minimal_envelope_once(self):
        self.end(assistant_response="segredo", user_message="outro segredo")
        self.end()
        self.assertEqual(len(self.sent), 1)
        _, body, urgency = self.sent[0]
        self.assertEqual(urgency, "normal")
        self.assertEqual(body["kind"], "turn.completed")
        self.assertEqual(body["session_id"], "sess-1")
        self.assertEqual(body["title"], "Refatorar backup")
        self.assertEqual(set(body), {"v", "id", "kind", "session_id", "ts", "title"})

    def test_outcomes_and_default_toggles(self):
        self.end(turn_id="t-fail", completed=False, failed=True)
        self.end(turn_id="t-int", completed=False, interrupted=True)
        self.end(turn_id="t-none", completed=False)
        self.assertEqual([b["kind"] for _, b, _ in self.sent], ["turn.failed", "turn.failed"])
        self.config["notify_interrupted"] = "true"
        self.end(turn_id="t-int-2", completed=False, interrupted=True)
        self.assertEqual(self.sent[-1][1]["kind"], "turn.interrupted")

    def test_skipped_platforms_and_missing_ids(self):
        self.end(platform="cron")
        self.end(turn_id="t2", platform="Subagent")
        self.end(turn_id=None)
        self.end(turn_id="t3", session_id="")
        self.assertEqual(self.sent, [])

    def test_title_can_be_turned_off(self):
        self.config["include_title"] = False
        self.end()
        self.assertNotIn("title", self.sent[0][1])

    def test_input_request_is_high_priority_without_prompt_and_resolves(self):
        self.notifier.on_human_input_resolved(request_id="r-unknown", session_id="sess-1")
        self.notifier.on_human_input_request(kind="approval", request_id="r1", session_id="sess-1",
                                             platform="tui", prompt="rm -rf /srv/segredo")
        self.notifier.on_human_input_resolved(request_id="r1", session_id="sess-1", outcome="once")
        self.notifier.on_human_input_resolved(request_id="r1", session_id="sess-1")
        self.assertEqual([b["kind"] for _, b, _ in self.sent], ["input.requested", "input.resolved"])
        _, request, urgency = self.sent[0]
        self.assertEqual(urgency, "high")
        self.assertEqual((request["input"], request["request_id"]), ("approval", "r1"))
        self.assertNotIn("segredo", json.dumps([b for _, b, _ in self.sent]))

    def test_unknown_input_kind_and_disabled_toggle(self):
        self.notifier.on_human_input_request(kind="secret", request_id="r1", session_id="s")
        self.config["notify_input"] = "off"
        self.notifier.on_human_input_request(kind="clarify", request_id="r2", session_id="s")
        self.assertEqual(self.sent, [])

    def test_gone_endpoint_removes_device(self):
        self.status = 410
        self.end()
        self.assertEqual(self.store.all(), [])

    def test_no_devices_sends_nothing(self):
        self.store.remove("phone-0001")
        self.end()
        self.assertEqual(self.sent, [])


class RegisterTest(unittest.TestCase):
    def test_register_wires_observer_hooks(self):
        hooks = {}

        class Ctx:
            def get_config(self, key, default=None):
                return default

            def register_hook(self, name, fn):
                hooks[name] = fn

        pkg.register(Ctx())
        self.assertEqual(set(hooks), {"on_session_end", "on_human_input_request", "on_human_input_resolved"})
        manifest = (PLUGIN_DIR / "plugin.yaml").read_text(encoding="utf-8")
        self.assertIn("provides_hooks: [on_session_end, on_human_input_request, on_human_input_resolved]",
                      manifest)


if __name__ == "__main__":
    unittest.main()
