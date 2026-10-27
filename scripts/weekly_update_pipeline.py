#!/usr/bin/env python3
"""
scripts/weekly_update_pipeline.py
VeroApp Weekly Threat Database Automated Update Pipeline (FAZA 7)

Execution steps:
  1. Executes scripts/spam_db_builder.py (refreshes open-source intelligence)
  2. Executes scripts/turkey_spam_collector.py (gathers local Turkish updates)
  3. Calculates delta differences (newly discovered numbers & domains)
  4. Calls scripts/prepare_threat_update.py to build 'threat_db_v{X}.bin' delta package
  5. Formats release notes:
     "Haftalık güncelleme: +X numara, +Y domain, Toplam: Z kayıt"
"""

import os
import re
import struct
import subprocess
import sys
from typing import Set, Tuple

def get_db_stats(numbers_path: str, domains_path: str) -> Tuple[int, int]:
    num_count = 0
    if os.path.exists(numbers_path):
        size = os.path.getsize(numbers_path)
        num_count = size // 8

    dom_count = 0
    if os.path.exists(domains_path):
        with open(domains_path, "r", encoding="utf-8", errors="ignore") as f:
            dom_count = sum(1 for line in f if line.strip())

    return num_count, dom_count

def run_pipeline(target_version: int = 2):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(base_dir, ".."))

    spam_builder = os.path.join(base_dir, "spam_db_builder.py")
    turkey_collector = os.path.join(base_dir, "turkey_spam_collector.py")
    prepare_update = os.path.join(base_dir, "prepare_threat_update.py")

    num_file = os.path.join(project_root, "assets", "spam_db", "spam_numbers.bin")
    dom_file = os.path.join(project_root, "assets", "spam_db", "phishing_domains.bin")

    before_nums, before_doms = get_db_stats(num_file, dom_file)
    print(f"[*] Baseline DB State: {before_nums:,} numbers, {before_doms:,} domains")

    # 1. Run spam_db_builder.py
    print("\n--- Step 1: Running spam_db_builder.py ---")
    res1 = subprocess.run([sys.executable, spam_builder], check=False)
    if res1.returncode != 0:
        print("[!] Warning: spam_db_builder returned non-zero code.")

    # 2. Run turkey_spam_collector.py
    print("\n--- Step 2: Running turkey_spam_collector.py ---")
    res2 = subprocess.run([sys.executable, turkey_collector], check=False)
    if res2.returncode != 0:
        print("[!] Warning: turkey_spam_collector returned non-zero code.")

    after_nums, after_doms = get_db_stats(num_file, dom_file)
    diff_nums = max(0, after_nums - before_nums)
    diff_doms = max(0, after_doms - before_doms)
    total_records = after_nums + after_doms

    print(f"\n[*] Delta Analysis:")
    print(f"    New Numbers: +{diff_nums:,}")
    print(f"    New Domains: +{diff_doms:,}")
    print(f"    Total Threat Signatures: {total_records:,}")

    # 3. Create delta update package threat_db_v{X}.bin
    out_pkg = os.path.join(project_root, "assets", "spam_db", f"threat_db_v{target_version}.bin")
    print(f"\n--- Step 3: Generating threat_db_v{target_version}.bin delta package ---")
    res3 = subprocess.run([
        sys.executable,
        prepare_update,
        "--version", str(target_version),
        "--out", out_pkg
    ], check=False)

    # 4. Generate release notes
    release_note = (
        f"Haftalık güncelleme: +{diff_nums:,} numara, +{diff_doms:,} domain, "
        f"Toplam: {total_records:,} kayıt (Versiyon {target_version})"
    )

    release_note_file = os.path.join(base_dir, "latest_release_note.txt")
    with open(release_note_file, "w", encoding="utf-8") as f:
        f.write(release_note + "\n")

    print("\n[OK] Weekly Pipeline Completed Successfully!")
    print(f"     Release Note: \"{release_note}\"")
    print(f"     Package: {out_pkg}")
    print(f"     Note saved to: {release_note_file}")

    return {
        "version": target_version,
        "new_numbers": diff_nums,
        "new_domains": diff_doms,
        "total_records": total_records,
        "release_note": release_note,
    }

if __name__ == "__main__":
    v = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    run_pipeline(v)
