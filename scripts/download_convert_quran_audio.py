#!/usr/bin/env python3
"""
Download all Quran verse audio files from islamic.network and convert them to PCM.

Source pattern:
    https://cdn.islamic.network/quran/audio/64/ar.alafasy/{GLOBAL_VERSE_NUMBER}.mp3
where GLOBAL_VERSE_NUMBER goes from 1..6236 (inclusive).

Output layout (created if missing):
    assets/audio/surah_001/verse_001.pcm
    assets/audio/surah_001/verse_002.pcm
    ...
    assets/audio/surah_002/verse_001.pcm

We group by surah using a verse count table. Raw mp3 files are optional (not stored by default).

Features:
- Safe resume: skips conversion if target .pcm file already exists.
- Optional keeping mp3 (--keep-mp3), otherwise mp3 saved to a temp file and removed after conversion.
- Retry with exponential backoff on network failures.
- Throttling option (--sleep) to sleep N milliseconds between requests.
- Concurrency option (--workers) for parallel downloads (default 4). Can lower for slow connections.

Dependencies: Python 3.8+, ffmpeg installed and in PATH.

Usage examples:
  python scripts/download_convert_quran_audio.py --limit 50
  python scripts/download_convert_quran_audio.py --start 1000 --workers 8
  python scripts/download_convert_quran_audio.py --keep-mp3 --pcm-rate 16000

Recommended full run (may take a while):
  python scripts/download_convert_quran_audio.py

Notes:
- Default PCM: 16-bit signed little-endian mono, 16 kHz sample rate.
- Adjust sample rate with --pcm-rate (e.g., 22050 or 8000).
- If you interrupt, just rerun; existing .pcm files are skipped.
"""
from __future__ import annotations
import argparse
import concurrent.futures
import math
import os
import sys
import time
import subprocess
from pathlib import Path
from typing import List, Tuple
import urllib.request
import urllib.error

BASE_URL = "https://cdn.islamic.network/quran/audio/64/ar.alafasy"
TOTAL_AYAHS = 6236
# Verse counts per surah (114 entries)
SURAH_VERSE_COUNTS: List[int] = [
    # Canonical Kufan/Hafs verse counts by surah (1..114), sum = 6236
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
]
if len(SURAH_VERSE_COUNTS) != 114 or sum(SURAH_VERSE_COUNTS) != TOTAL_AYAHS:
    raise ValueError("Surah counts table invalid; please verify the verse counts.")

# Precompute ayah global index ranges per surah: list of (surah_number, start_global, end_global)
SURAH_RANGES: List[Tuple[int,int,int]] = []
_running = 0
for i, count in enumerate(SURAH_VERSE_COUNTS, start=1):
    start = _running + 1
    end = _running + count
    SURAH_RANGES.append((i, start, end))
    _running = end

ASSETS_ROOT = Path("assets/audio")

class DownloadError(Exception):
    pass

def global_to_surah_ayah(global_index: int) -> Tuple[int,int]:
    """Map global verse number to (surah_number, verse_in_surah)."""
    # Binary search could be used; linear is fine (114 entries only)
    for surah, start, end in SURAH_RANGES:
        if start <= global_index <= end:
            return surah, global_index - start + 1
    raise ValueError(f"Global ayah index out of range: {global_index}")

def fetch_mp3(global_index: int, dest: Path, retries: int = 4, backoff: float = 0.75) -> None:
    url = f"{BASE_URL}/{global_index}.mp3"
    attempt = 0
    while True:
        try:
            with urllib.request.urlopen(url) as resp, open(dest, 'wb') as f:
                f.write(resp.read())
            if dest.stat().st_size == 0:
                raise DownloadError("Empty file downloaded")
            return
        except (urllib.error.URLError, urllib.error.HTTPError, DownloadError) as e:
            attempt += 1
            if attempt > retries:
                raise DownloadError(f"Failed after {retries} retries: {e}")
            sleep_time = backoff * (2 ** (attempt - 1)) + (0.05 * attempt)
            time.sleep(sleep_time)

def convert_to_pcm(mp3_path: Path, pcm_path: Path, sample_rate: int) -> None:
    cmd = [
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(mp3_path),
        "-f", "s16le", "-acodec", "pcm_s16le", "-ac", "1", "-ar", str(sample_rate), str(pcm_path)
    ]
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"ffmpeg conversion failed for {mp3_path}: {e}")

def process_ayah(global_index: int, args) -> Tuple[int, bool, str]:
    surah, verse_in_surah = global_to_surah_ayah(global_index)
    surah_dir = ASSETS_ROOT / f"surah_{surah:03d}"
    surah_dir.mkdir(parents=True, exist_ok=True)
    pcm_path = surah_dir / f"verse_{verse_in_surah:03d}.pcm"
    if pcm_path.exists():
        return global_index, False, "skip (exists)"
    # Temp mp3 path: when keeping mp3, name it verse_.. otherwise use a tmp file per global index
    mp3_path = surah_dir / f"verse_{verse_in_surah:03d}.mp3" if args.keep_mp3 else surah_dir / f"._tmp_{global_index}.mp3"
    try:
        fetch_mp3(global_index, mp3_path)
        convert_to_pcm(mp3_path, pcm_path, args.pcm_rate)
        if not args.keep_mp3:
            try:
                mp3_path.unlink(missing_ok=True)
            except Exception:
                pass
        return global_index, True, "ok"
    except Exception as e:
        # Clean partial files
        if mp3_path.exists() and not args.keep_mp3:
            try: mp3_path.unlink()
            except Exception: pass
        if pcm_path.exists():
            try: pcm_path.unlink()
            except Exception: pass
        return global_index, False, f"error: {e}"

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Download and convert Quran verse audio to PCM.")
    p.add_argument("--start", type=int, default=1, help="Global verse start index (1..6236)")
    p.add_argument("--end", type=int, default=TOTAL_AYAHS, help="Global verse end index (inclusive)")
    p.add_argument("--limit", type=int, default=None, help="Limit total count (for testing)")
    p.add_argument("--workers", type=int, default=4, help="Concurrent download workers")
    p.add_argument("--keep-mp3", action="store_true", help="Keep original mp3 files")
    p.add_argument("--pcm-rate", type=int, default=16000, help="Target PCM sample rate (Hz)")
    p.add_argument("--sleep", type=int, default=0, help="Sleep milliseconds between scheduling tasks to reduce server load")
    return p.parse_args()

def main():
    args = parse_args()
    if args.start < 1 or args.end > TOTAL_AYAHS or args.start > args.end:
        print("Invalid range", file=sys.stderr)
        return 1
    indices = list(range(args.start, args.end + 1))
    if args.limit:
        indices = indices[:args.limit]
    print(f"Processing {len(indices)} ayahs (global indices {indices[0]}..{indices[-1]})")
    ASSETS_ROOT.mkdir(parents=True, exist_ok=True)
    completed = 0
    errors = 0
    t0 = time.time()
    # Use ThreadPoolExecutor (network + subprocess IO bound)
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as ex:
        fut_map = {}
        for idx in indices:
            fut = ex.submit(process_ayah, idx, args)
            fut_map[fut] = idx
            if args.sleep:
                time.sleep(args.sleep / 1000.0)
        for fut in concurrent.futures.as_completed(fut_map):
            global_idx, changed, status = fut.result()
            if status.startswith("error"):
                errors += 1
                print(f"[{global_idx}] {status}")
            else:
                if changed:
                    completed += 1
                if completed % 50 == 0 and changed:
                    elapsed = time.time() - t0
                    print(f"Converted {completed} new ayahs in {elapsed:.1f}s (errors={errors})")
    elapsed = time.time() - t0
    print(f"Done. New conversions: {completed}. Errors: {errors}. Elapsed: {elapsed:.1f}s")
    return 0 if errors == 0 else 2

if __name__ == "__main__":
    raise SystemExit(main())
