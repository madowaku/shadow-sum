#!/usr/bin/env python3
"""Build or check the subset of Noto Sans JP that NOXSUM ships.

The full variable font is ~9.6 MB (~6.9 MB inside index.pck) and is the
largest single file the Web build downloads before the HOME screen. The game
only displays a few hundred Japanese characters, so it ships a subset that
keeps every character found in the game's text sources plus ASCII, kana and
common CJK punctuation. The wght axis and layout features are kept.

    python3 tools/subset_noxsum_japanese_font.py          # rebuild the subset
    python3 tools/subset_noxsum_japanese_font.py --check  # fail if text needs
                                                          # a glyph it lacks

Run the build again whenever new Japanese text is added; CI runs --check.
Requires: pip install fonttools
"""

from __future__ import annotations

import argparse
import glob
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_FONT = ROOT / "assets/fonts/NotoSansJP-VF.ttf"
SUBSET_FONT = ROOT / "assets/fonts/NotoSansJP-VF-subset.ttf"
TEXT_SOURCES = ("src/**/*.gd", "scenes/**/*.tscn", "theme/**/*", "data/*.json", "web/*.html")
EXTRA_CHARS = "・…—–‐‘’“”〜×÷←→↑↓○●◎△▲▽▼□■◇◆☆★"


def required_characters() -> set[str]:
    chars: set[str] = set()
    for pattern in TEXT_SOURCES:
        for name in glob.glob(str(ROOT / pattern), recursive=True):
            path = Path(name)
            if not path.is_file():
                continue
            try:
                chars |= set(path.read_text(encoding="utf-8"))
            except UnicodeDecodeError:
                continue
    chars = {c for c in chars if ord(c) >= 0x20}
    chars |= {chr(c) for c in range(0x20, 0x7F)}
    chars |= {chr(c) for c in range(0x3000, 0x3100)}  # CJK punctuation, kana
    chars |= {chr(c) for c in range(0xFF01, 0xFF9F)}  # full/half-width forms
    chars |= set(EXTRA_CHARS)
    return chars


def build(chars: set[str]) -> None:
    from fontTools import subset

    options = subset.Options()
    options.layout_features = ["*"]
    options.hinting = False
    font = subset.load_font(str(SOURCE_FONT), options)
    subsetter = subset.Subsetter(options)
    subsetter.populate(text="".join(sorted(chars)))
    subsetter.subset(font)
    subset.save_font(font, str(SUBSET_FONT), options)
    print(f"Wrote {SUBSET_FONT.relative_to(ROOT)}: {SUBSET_FONT.stat().st_size:,} bytes, "
          f"{len(chars)} characters (source {SOURCE_FONT.stat().st_size:,} bytes)")


def check(chars: set[str]) -> int:
    from fontTools.ttLib import TTFont

    source = set(TTFont(str(SOURCE_FONT)).getBestCmap())
    shipped = set(TTFont(str(SUBSET_FONT)).getBestCmap())
    # Characters the full font cannot draw either (emoji, symbols drawn by
    # other fonts) are not the subset's job.
    missing = sorted(c for c in chars if ord(c) in source and ord(c) not in shipped)
    if missing:
        print("NotoSansJP subset lacks glyphs used by game text: " + "".join(missing))
        print("Run: python3 tools/subset_noxsum_japanese_font.py")
        return 1
    print(f"NotoSansJP subset covers all {len(chars)} required characters.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="verify coverage instead of rebuilding")
    args = parser.parse_args()
    chars = required_characters()
    if args.check:
        return check(chars)
    build(chars)
    return check(chars)


if __name__ == "__main__":
    sys.exit(main())
