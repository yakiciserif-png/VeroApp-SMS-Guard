#!/usr/bin/env python3
"""
VeroApp SMS Guard — Ed25519 Offline License Tool
Used by the developer/admin to generate mathematically signed offline licenses
for Family (4 members) and Enterprise plans.

The private key is stored ONLY locally and NEVER committed to the repo.
The app verifies signatures using ONLY the embedded public key.
"""

import os
import sys
import json
import time
import base64
import uuid
import argparse
from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PRIVATE_KEY_PATH = os.path.join(SCRIPT_DIR, '.ed25519_private.key')
PUBLIC_KEY_PATH = os.path.join(SCRIPT_DIR, 'ed25519_public.key')

def get_or_create_keypair():
    if os.path.exists(PRIVATE_KEY_PATH):
        with open(PRIVATE_KEY_PATH, 'rb') as f:
            priv_bytes = f.read()
        priv_key = ed25519.Ed25519PrivateKey.from_private_bytes(priv_bytes)
    else:
        priv_key = ed25519.Ed25519PrivateKey.generate()
        priv_bytes = priv_key.private_bytes(
            encoding=serialization.Encoding.Raw,
            format=serialization.PrivateFormat.Raw,
            encryption_algorithm=serialization.NoEncryption()
        )
        with open(PRIVATE_KEY_PATH, 'wb') as f:
            f.write(priv_bytes)
        os.chmod(PRIVATE_KEY_PATH, 0o600)
        print(f"[+] Yeni Ed25519 Özel Anahtar üretildi: {PRIVATE_KEY_PATH}")

    pub_key = priv_key.public_key()
    pub_bytes = pub_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw
    )
    with open(PUBLIC_KEY_PATH, 'wb') as f:
        f.write(pub_bytes)
    return priv_key, pub_key

def b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode('ascii').rstrip('=')

def b64url_decode(s: str) -> bytes:
    pad = len(s) % 4
    if pad:
        s += '=' * (4 - pad)
    return base64.urlsafe_b64decode(s)

def generate_license(tier: str, seats: int, days: int) -> str:
    priv_key, pub_key = get_or_create_keypair()
    now = int(time.time())
    expires = now + (days * 86400)
    lic_id = f"VERO-{str(uuid.uuid4())[:8].upper()}"

    payload = {
        "tier": tier.lower(),
        "seats": seats,
        "iat": now,
        "exp": expires,
        "id": lic_id,
    }

    payload_json = json.dumps(payload, separators=(',', ':'), sort_keys=True)
    payload_bytes = payload_json.encode('utf-8')

    signature = priv_key.sign(payload_bytes)

    tier_tag = "FAM" if tier.lower() == "family" else "ENT"
    code = f"VERO-{tier_tag}-{b64url_encode(payload_bytes)}.{b64url_encode(signature)}"
    return code, payload

def verify_license(code: str) -> dict:
    _, pub_key = get_or_create_keypair()
    parts = code.strip().split('-', 2)
    if len(parts) < 3 or parts[0] != "VERO":
        raise ValueError("Gecersiz lisans formati (VERO- on eki eksik)")

    body = parts[2]
    if '.' not in body:
        raise ValueError("Gecersiz imza ayraci (.)")

    payload_b64, sig_b64 = body.split('.', 1)
    payload_bytes = b64url_decode(payload_b64)
    signature = b64url_decode(sig_b64)

    pub_key.verify(signature, payload_bytes)
    payload = json.loads(payload_bytes.decode('utf-8'))

    now = int(time.time())
    if payload.get("exp", 0) < now:
        raise ValueError(f"Lisansin suresi dolmus (Sona erme: {payload.get('exp')})")

    return payload

def main():
    parser = argparse.ArgumentParser(description="VeroApp Ed25519 Offline Lisans Aracı")
    subparsers = parser.add_subparsers(dest="command")

    gen_parser = subparsers.add_parser("generate", help="Yeni imzalı lisans üret")
    gen_parser.add_argument("--tier", choices=["family", "enterprise"], default="family", help="Plan türü")
    gen_parser.add_argument("--seats", type=int, default=4, help="Kullanıcı/Cihaz kontenjanı (Aile için 4)")
    gen_parser.add_argument("--days", type=int, default=365, help="Geçerlilik süresi (gün)")

    ver_parser = subparsers.add_parser("verify", help="Lisansı açık anahtarla doğrula")
    ver_parser.add_argument("code", help="Doğrulanacak lisans kodu")

    info_parser = subparsers.add_parser("pubkey", help="Açık anahtarı Base64 olarak yazdır")

    args = parser.parse_args()

    if args.command == "generate":
        code, payload = generate_license(args.tier, args.seats, args.days)
        print("====================================================================")
        print("[KEY] VEROAPP IMZALI OFFLINE LISANS KODU:")
        print(code)
        print("====================================================================")
        print("Icerik:", json.dumps(payload, indent=2))
    elif args.command == "verify":
        try:
            payload = verify_license(args.code)
            print("[OK] LISANS GECERLI VE IMZASI TEYIT EDILDI:")
            print(json.dumps(payload, indent=2))
        except Exception as e:
            print(f"[ERROR] LISANS GECERSIZ / REDDEDILDI: {e}")
            sys.exit(1)
    elif args.command == "pubkey":
        _, pub_key = get_or_create_keypair()
        raw = pub_key.public_bytes(
            encoding=serialization.Encoding.Raw,
            format=serialization.PublicFormat.Raw
        )
        print("Public Key (Base64):", base64.b64encode(raw).decode('ascii'))
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
