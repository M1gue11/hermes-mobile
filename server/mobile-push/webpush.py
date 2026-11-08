"""WebPush delivery to a UnifiedPush endpoint (RFC 8030 + RFC 8291 ``aes128gcm``).

The device's distributor (the ntfy app) hands out an endpoint URL and the
connector library generates the P-256 key pair and auth secret, so a payload
encrypted here is opaque to the ntfy server in between. Without those keys, or
without ``cryptography``, the payload goes out as plain JSON.
"""

from __future__ import annotations

import base64
import logging
import os
import struct
import urllib.error
import urllib.request
from dataclasses import dataclass

logger = logging.getLogger("mobile_push")

SEND_TIMEOUT_SECONDS = 15
RECORD_SIZE = 4096
DEFAULT_TTL_SECONDS = 24 * 60 * 60


def b64url_decode(value: str) -> bytes:
    value = value.strip()
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def b64url_encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def encryption_available() -> bool:
    try:
        import cryptography  # noqa: F401
    except ImportError:
        return False
    return True


def encrypt(plaintext: bytes, p256dh: str, auth: str, *, salt: bytes | None = None,
            private_key=None) -> bytes:
    """RFC 8291 single-record ``aes128gcm`` body: header (salt, rs, keyid) + ciphertext.

    ``salt`` and ``private_key`` exist for the RFC test vector; production calls
    leave them random.
    """
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    from cryptography.hazmat.primitives.kdf.hkdf import HKDF

    ua_public = b64url_decode(p256dh)
    auth_secret = b64url_decode(auth)
    if len(ua_public) != 65 or len(auth_secret) != 16:
        raise ValueError("invalid WebPush subscription keys")
    if len(plaintext) > RECORD_SIZE - 17:  # 16-byte tag + delimiter
        raise ValueError("payload too large for a single record")

    as_private = private_key or ec.generate_private_key(ec.SECP256R1())
    as_public = as_private.public_key().public_bytes(
        serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint)
    ua_key = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP256R1(), ua_public)
    ecdh_secret = as_private.exchange(ec.ECDH(), ua_key)

    def hkdf(salt_: bytes, info: bytes, length: int, ikm: bytes) -> bytes:
        return HKDF(algorithm=hashes.SHA256(), length=length, salt=salt_, info=info).derive(ikm)

    ikm = hkdf(auth_secret, b"WebPush: info\x00" + ua_public + as_public, 32, ecdh_secret)
    salt = salt or os.urandom(16)
    cek = hkdf(salt, b"Content-Encoding: aes128gcm\x00", 16, ikm)
    nonce = hkdf(salt, b"Content-Encoding: nonce\x00", 12, ikm)
    # 0x02 marks the last (and only) record; no extra padding.
    ciphertext = AESGCM(cek).encrypt(nonce, plaintext + b"\x02", None)
    header = salt + struct.pack("!IB", RECORD_SIZE, len(as_public)) + as_public
    return header + ciphertext


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


_opener = urllib.request.build_opener(_NoRedirect)


@dataclass(frozen=True)
class DeliveryResult:
    status: int
    encrypted: bool

    @property
    def ok(self) -> bool:
        return 200 <= self.status < 300

    @property
    def gone(self) -> bool:
        """The distributor dropped this endpoint; the device must register again."""
        return self.status in (404, 410)


def build_request(endpoint: str, payload: bytes, *, p256dh: str = "", auth: str = "",
                  urgency: str = "normal", ttl: int = DEFAULT_TTL_SECONDS) -> tuple[urllib.request.Request, bool]:
    headers = {"TTL": str(ttl), "Urgency": urgency}
    encrypted = bool(p256dh and auth) and encryption_available()
    if encrypted:
        body = encrypt(payload, p256dh, auth)
        headers["Content-Type"] = "application/octet-stream"
        headers["Content-Encoding"] = "aes128gcm"
    else:
        body = payload
        headers["Content-Type"] = "application/json"
    return urllib.request.Request(endpoint, data=body, headers=headers, method="POST"), encrypted


def deliver(endpoint: str, payload: bytes, *, p256dh: str = "", auth: str = "",
            urgency: str = "normal") -> DeliveryResult:
    """POST once. Status 0 means the request never got an HTTP answer."""
    request, encrypted = build_request(endpoint, payload, p256dh=p256dh, auth=auth, urgency=urgency)
    try:
        with _opener.open(request, timeout=SEND_TIMEOUT_SECONDS) as response:
            return DeliveryResult(getattr(response, "status", 200), encrypted)
    except urllib.error.HTTPError as exc:
        return DeliveryResult(exc.code, encrypted)
    except Exception as exc:  # a dead endpoint must never reach the agent loop
        logger.warning("mobile-push: delivery failed: %s", type(exc).__name__)
        return DeliveryResult(0, encrypted)
