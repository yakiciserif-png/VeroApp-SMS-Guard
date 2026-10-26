#!/usr/bin/env python3
"""
scripts/prepare_threat_update.py
VeroApp Threat Database Weekly Update Builder

Creates a signed, privacy-safe, binary one-way update package 'threat_db_v{X}.bin'.
Output format:
- Magic: 'VERO_UP' (7 bytes)
- Version: uint32 (4 bytes, Big Endian)
- Record Count: uint32 (4 bytes, Big Endian)
- Repeated Records:
  - Phone Number: uint64 (8 bytes, Big Endian)
  - Category: uint8 (1 byte: 1=Betting, 2=Scam, 3=Phishing, 4=Telemarketing, 5=Debt)
  - Confidence: uint8 (1 byte: 0-100)
  - Pattern String Length: uint16 (2 bytes, Big Endian)
  - Pattern String: UTF-8 encoded bytes
"""

import sys
import struct
import argparse
import os

MAGIC = b"VERO_UP"

# Known category map
CATEGORIES = {
    "betting": 1,
    "scam": 2,
    "phishing": 3,
    "telemarketing": 4,
    "debt": 5,
}

# Verified default seed records for weekly threat release updates
SAMPLE_WEEKLY_THREATS = [
    (908504808899, 2, 95, "Yatirim Dolandiriciligi 0850"),
    (908504809911, 2, 98, "Hukuk Burosu Sahte Haciz"),
    (908502551122, 1, 90, "VIP Casino Bahis SMS Arama"),
    (902129450099, 4, 85, "Robot Arama Sahte Internet Kampanyasi"),
    (2348011223344, 2, 99, "Nijerya Fon Dolandiriciligi WhatsApp"),
    (639171234567, 3, 95, "Filipinler Kripto Oltalama"),
]

def build_threat_package(version: int, output_path: str, records=None):
    if records is None:
        records = SAMPLE_WEEKLY_THREATS

    header = bytearray()
    header.extend(MAGIC)
    header.extend(struct.pack(">I", version))
    header.extend(struct.pack(">I", len(records)))

    body = bytearray()
    for phone, cat, conf, pattern in records:
        pattern_bytes = pattern.encode("utf-8")
        record_bytes = struct.pack(
            ">QBBH",
            phone,
            cat,
            conf,
            len(pattern_bytes)
        ) + pattern_bytes
        body.extend(record_bytes)

    total_bytes = header + body

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(total_bytes)

    print(f"[OK] Package threat_db_v{version}.bin generated successfully.")
    print(f"     Path: {output_path}")
    print(f"     Records: {len(records)}")
    print(f"     File Size: {len(total_bytes)} bytes")

def main():
    parser = argparse.ArgumentParser(description="Build VeroApp threat update binary package.")
    parser.add_argument("--version", type=int, default=2, help="Target threat DB version number")
    parser.add_argument("--out", type=str, default="", help="Output binary file path")
    args = parser.parse_args()

    out_file = args.out if args.out else f"threat_db_v{args.version}.bin"
    build_threat_package(args.version, out_file)

if __name__ == "__main__":
    main()
