#!/usr/bin/env python3
"""Check and validate PCM files under assets/audio.

Features:
- Walks assets/audio and reports each .pcm file size and inferred duration (size / (channels*bytes_per_sample*sample_rate)).
- Optionally probes the file with ffmpeg to attempt a conversion to WAV (in-memory) to verify it's decodable.
- Can report only files below a size threshold.

Usage:
  python scripts/check_pcm_files.py --min-bytes 100
  python scripts/check_pcm_files.py --ffmpeg-validate --sample-rate 16000
"""
from pathlib import Path
import argparse
import subprocess
import sys

ASSETS = Path("assets/audio")

def find_pcm_files(root: Path):
    for p in root.rglob("*.pcm"):
        yield p

def infer_duration_bytes(nbytes: int, sample_rate: int, channels: int =1, bytes_per_sample: int =2) -> float:
    # bytes_per_sample default 2 for s16le
    return nbytes / (sample_rate * channels * bytes_per_sample)

def ffmpeg_validate(p: Path, sample_rate: int) -> bool:
    # Attempt to decode PCM assuming s16le mono at sample_rate to WAV (written to /dev/null)
    cmd = [
        "ffmpeg", "-f", "s16le", "-ar", str(sample_rate), "-ac", "1",
        "-i", str(p), "-f", "wav", "-"
    ]
    try:
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True, timeout=15)
        return True
    except Exception:
        return False

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--min-bytes", type=int, default=1, help="Only show files >= this size in bytes")
    p.add_argument("--sample-rate", type=int, default=16000, help="Sample rate used when inferring duration and validating")
    p.add_argument("--ffmpeg-validate", action="store_true", help="Run ffmpeg to validate decoding of pcm files (may be slow)")
    args = p.parse_args()

    if not ASSETS.exists():
        print("No assets/audio directory found.")
        return 1

    total = 0
    bad = 0
    for f in find_pcm_files(ASSETS):
        try:
            n = f.stat().st_size
        except Exception as e:
            print(f"{f}: stat error: {e}")
            continue
        if n < args.min_bytes:
            continue
        dur = infer_duration_bytes(n, args.sample_rate)
        line = f"{f} | {n} bytes | ~{dur:.2f}s"
        if args.ffmpeg_validate:
            ok = ffmpeg_validate(f, args.sample_rate)
            line += " | ffmpeg: OK" if ok else " | ffmpeg: FAIL"
            if not ok:
                bad += 1
        print(line)
        total += 1

    print(f"Scanned {total} files; ffmpeg failures: {bad}")
    return 0 if bad == 0 else 2

if __name__ == '__main__':
    raise SystemExit(main())
