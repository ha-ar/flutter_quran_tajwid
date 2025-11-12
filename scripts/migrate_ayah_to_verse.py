#!/usr/bin/env python3
"""Migration helper: rename downloaded files from ayah_### to verse_###.

This script scans `assets/audio/surah_XXX` directories and renames files:
  ayah_001.pcm -> verse_001.pcm
  ayah_001.mp3 -> verse_001.mp3

Run with --dry-run to see planned changes. Use --yes to apply.
"""
from pathlib import Path
import argparse
import sys

ASSETS = Path("assets/audio")

def find_renames(root: Path):
    renames = []
    if not root.exists():
        return renames
    for surah_dir in sorted(root.iterdir()):
        if not surah_dir.is_dir():
            continue
        for p in sorted(surah_dir.iterdir()):
            if p.name.startswith("ayah_"):
                new = p.with_name(p.name.replace("ayah_", "verse_", 1))
                renames.append((p, new))
    return renames

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true", help="Show planned renames but don't perform them")
    p.add_argument("--yes", action="store_true", help="Apply changes without prompting")
    args = p.parse_args()

    ops = find_renames(ASSETS)
    if not ops:
        print("No ayah_ files found to migrate.")
        return 0
    print(f"Found {len(ops)} files to rename:")
    for src, dst in ops:
        print(f"{src} -> {dst}")

    if args.dry_run:
        print("Dry run; no changes made.")
        return 0

    if not args.yes:
        ans = input("Apply these renames? [y/N]: ").strip().lower()
        if ans != "y":
            print("Aborted.")
            return 2

    for src, dst in ops:
        try:
            if dst.exists():
                print(f"Skipping {src}: target {dst} already exists")
                continue
            src.rename(dst)
            print(f"Renamed: {src} -> {dst}")
        except Exception as e:
            print(f"Failed to rename {src}: {e}")

    print("Migration complete.")
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
