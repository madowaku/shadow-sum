#!/usr/bin/env python3
"""Audit NOXSUM Web export exclusions and report measured Web payload sizes.

Run before export for a static reference check, and again after export:
    python tools/audit_noxsum_web_payload.py
    python tools/audit_noxsum_web_payload.py --baseline-pck-mib 46.7

This cannot prove that dynamically constructed paths are unused. It also cannot
determine the actual compressed HTTP transfer size from local files.
"""

from __future__ import annotations

import argparse
import fnmatch
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PRESET = ROOT / "export_presets.cfg"
PROTECTED = (
    "assets/nox/v0.6/archive_puzzle_window.png",
    "assets/nox/v0.6/app_icon.png",
    "assets/nox/v0.4/archive_window.png",  # Referenced by the stage layout.
    "assets/fonts/NotoSansJP-VF.ttf",
    "assets/bgm/the_most_human_computer.mp3",
)


def web_exclusion_patterns() -> list[str]:
    text = PRESET.read_text(encoding="utf-8")
    web_preset = re.search(r"(?ms)^\[preset\.1\]\s*\n(.*?)(?=^\[|\Z)", text)
    if not web_preset or 'name="NOXSUM Web"' not in web_preset.group(1):
        raise RuntimeError("Could not locate the NOXSUM Web export preset")
    match = re.search(r'^exclude_filter="([^"]*)"$', web_preset.group(1), re.M)
    if not match:
        raise RuntimeError("Web exclude_filter is missing")
    return [s.strip() for s in match.group(1).split(",") if s.strip()]


def runtime_sources() -> list[Path]:
    paths = [ROOT / "project.godot"]
    for folder, extensions in (
        ("src", {".gd"}),
        ("scenes", {".tscn", ".tres"}),
        ("theme", {".tres"}),
        ("assets", {".tres"}),
    ):
        directory = ROOT / folder
        paths.extend(p for p in directory.rglob("*") if p.is_file() and p.suffix in extensions)
    return paths


def audit_exclusions() -> tuple[int, int]:
    patterns = web_exclusion_patterns()
    excluded_assets = [
        p for p in (ROOT / "assets").rglob("*")
        if p.is_file() and p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".mp3", ".ttf", ".otf"}
        and any(fnmatch.fnmatch(p.relative_to(ROOT).as_posix(), pattern) for pattern in patterns)
    ]
    for path in PROTECTED:
        if any(fnmatch.fnmatch(path, pattern) for pattern in patterns):
            raise RuntimeError(f"Protected runtime asset would be excluded: {path}")

    source_texts = {
        p.relative_to(ROOT).as_posix(): p.read_text(encoding="utf-8")
        for p in runtime_sources()
    }
    referenced = []
    for asset in excluded_assets:
        literal = "res://" + asset.relative_to(ROOT).as_posix()
        for source, text in source_texts.items():
            if literal in text:
                referenced.append((literal, source))
    if referenced:
        raise RuntimeError("Excluded assets still have direct runtime references:\n" +
                           "\n".join(f"  {asset} in {source}" for asset, source in referenced))

    bytes_total = sum(p.stat().st_size for p in excluded_assets)
    print(f"Unreferenced source exclusions: {len(excluded_assets)} assets / {bytes_total / 1048576:.2f} MiB raw source")
    print("NOTE: Raw source bytes are not a prediction of exported PCK savings.")
    return len(excluded_assets), bytes_total


def report_web_payload(web_dir: Path, baseline_mib: float | None) -> None:
    if not web_dir.is_dir():
        print(f"Web export not present: {web_dir} (Godot release export still required)")
        return
    sizes = {}
    for name in ("index.pck", "index.wasm", "index.js", "index.html"):
        file = web_dir / name
        if not file.is_file():
            raise RuntimeError(f"Missing Web runtime asset: {file}")
        sizes[name] = file.stat().st_size
        print(f"{name:12} {sizes[name] / 1048576:8.2f} MiB")
    total = sum(sizes.values())
    print(f"Four-file payload (uncompressed): {total / 1048576:.2f} MiB")
    if baseline_mib is not None:
        delta = baseline_mib - sizes["index.pck"] / 1048576
        print(f"PCK difference vs supplied {baseline_mib:.2f} MiB baseline: {delta:+.2f} MiB")
    index = (web_dir / "index.html").read_text(encoding="utf-8")
    print(f"Exported loader with onProgress: {'yes' if 'onProgress' in index and 'noxsum-loading' in index else 'no'}")
    print("HTTP Content-Encoding must be checked separately in browser Network tools.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--web-dir", type=Path, default=ROOT / "builds" / "web")
    parser.add_argument("--baseline-pck-mib", type=float)
    args = parser.parse_args()
    audit_exclusions()
    report_web_payload(args.web_dir, args.baseline_pck_mib)


if __name__ == "__main__":
    main()
