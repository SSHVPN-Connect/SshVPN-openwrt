"""Offline checks for the Windows client's SSH Tunnel invitation format."""
import base64
import importlib.util
import json
from pathlib import Path
import unittest

from cryptography.hazmat.primitives.ciphers.aead import AESGCM


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "luci-proto-ssh-tunnel" / "files" / "ssh-tunnel-invite.py"
spec = importlib.util.spec_from_file_location("ssh_tunnel_invite", HELPER)
invite = importlib.util.module_from_spec(spec)
spec.loader.exec_module(invite)


def encode(value):
    return base64.urlsafe_b64encode(value).decode().rstrip("=")


def make_ticket():
    public_blob = b"\x00\x00\x00\x0bssh-ed25519\x00\x00\x00\x20" + bytes(range(32))
    return {
        "server": "vpn.example.com",
        "user": "stv_0123456789abcdef",
        "host_key": "ssh-ed25519 " + base64.b64encode(public_blob).decode(),
        "temporary_key": "-----BEGIN OPENSSH PRIVATE KEY-----\nexample\n-----END OPENSSH PRIVATE KEY-----\n",
    }


def make_invitation(ticket=None):
    key = bytes(range(32))
    nonce = bytes(range(12))
    plaintext = json.dumps(ticket or make_ticket(), separators=(",", ":")).encode()
    encrypted = AESGCM(key).encrypt(nonce, plaintext, invite.VERSION.encode())
    return f"{invite.VERSION}:{encode(nonce + encrypted)}:{encode(key)}", encode(key)


class InvitationCodeTests(unittest.TestCase):
    def test_combined_share_code(self):
        combined, _ = make_invitation()
        ticket = invite.read_ticket(combined)
        self.assertEqual(ticket["user"], "stv_0123456789abcdef")
        self.assertEqual(ticket["server"], "vpn.example.com")

    def test_incomplete_invitation_is_rejected(self):
        combined, _ = make_invitation()
        encoded, _, _ = combined.rpartition(":")
        with self.assertRaises(ValueError):
            invite.read_ticket(encoded)

    def test_wrong_key_is_rejected(self):
        combined, _ = make_invitation()
        with self.assertRaises(ValueError):
            invite.read_ticket(combined.rpartition(":")[0] + ":" + encode(bytes(reversed(range(32)))))

    def test_malformed_account_is_rejected(self):
        bad_ticket = make_ticket()
        bad_ticket["user"] = "root"
        combined, _ = make_invitation(bad_ticket)
        with self.assertRaises(ValueError):
            invite.read_ticket(combined)


if __name__ == "__main__":
    unittest.main()
