"""Package the latest NOXSUM Release Web export for itch.io HTML5 upload."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import zipfile
from datetime import date
from pathlib import Path, PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "builds" / "web"
RUNTIME_FILES = (
    "index.html",
    "index.js",
    "index.pck",
    "index.wasm",
    "index.png",
    "index.icon.png",
    "index.apple-touch-icon.png",
    "index.audio.worklet.js",
    "index.audio.position.worklet.js",
)
LICENSE_FILES = {
    "licenses/CormorantGaramond-OFL.txt": ROOT / "assets/fonts/CormorantGaramond-OFL.txt",
    "licenses/Manrope-OFL.txt": ROOT / "assets/fonts/Manrope-OFL.txt",
    "licenses/NotoSansJP-OFL.txt": ROOT / "assets/fonts/NotoSansJP-OFL.txt",
}
MAX_ARCHIVE_FILES = 1000
MAX_ARCHIVE_SIZE = 500 * 1024 * 1024
MAX_SINGLE_FILE_SIZE = 200 * 1024 * 1024


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--date", default=date.today().isoformat(), help="Date suffix for the ZIP filename (YYYY-MM-DD).")
    parser.add_argument("--output", type=Path, help="Optional ZIP destination; defaults to builds/NOXSUM_Grant_Itchio_<date>.zip.")
    args = parser.parse_args()

    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", args.date):
        parser.error("--date must use YYYY-MM-DD format")
    output = args.output or ROOT / "builds" / f"NOXSUM_Grant_Itchio_{args.date}.zip"
    if not output.is_absolute():
        output = ROOT / output

    entries: dict[str, bytes] = {}
    for name in RUNTIME_FILES:
        source = WEB / name
        if not source.is_file():
            raise SystemExit(f"Missing Release Web file: {source}. Export the NOXSUM Web Release preset first.")
        entries[name] = source.read_bytes()
    for archive_name, source in LICENSE_FILES.items():
        if not source.is_file():
            raise SystemExit(f"Missing font license: {source}")
        entries[archive_name] = source.read_bytes()

    index = entries["index.html"]
    base_tag = b'<base href="/">'
    if index.count(base_tag) != 1:
        raise SystemExit("Expected exactly one <base href=\"/\"> tag in the exported index.html.")
    entries["index.html"] = index.replace(base_tag, b'<base href="./">', 1)

    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for archive_name, data in entries.items():
            archive.writestr(archive_name, data)

    with zipfile.ZipFile(output) as archive:
        names = archive.namelist()
        bad_member = archive.testzip()
        if bad_member:
            raise SystemExit(f"ZIP CRC check failed for {bad_member}")
        if names.count("index.html") != 1 or names[0] != "index.html":
            raise SystemExit("index.html must be present at the ZIP root.")
        if set(names) != set(entries) or len(names) != len(entries):
            raise SystemExit("ZIP contents differ from the explicit runtime and license allowlist.")

        extracted_size = 0
        for info in archive.infolist():
            safe_name = PurePosixPath(info.filename)
            if safe_name.is_absolute() or ".." in safe_name.parts or "\\" in info.filename:
                raise SystemExit(f"Unsafe ZIP member path: {info.filename}")
            if len(info.filename) > 240:
                raise SystemExit(f"ZIP member path exceeds itch.io limit: {info.filename}")
            if info.file_size > MAX_SINGLE_FILE_SIZE:
                raise SystemExit(f"ZIP member exceeds itch.io size limit: {info.filename}")
            extracted_size += info.file_size
            if archive.read(info.filename) != entries[info.filename]:
                raise SystemExit(f"Unexpected ZIP payload: {info.filename}")

    if len(entries) > MAX_ARCHIVE_FILES or extracted_size > MAX_ARCHIVE_SIZE:
        raise SystemExit("ZIP exceeds itch.io HTML5 archive limits.")
    if b'<base href="./">' not in entries["index.html"]:
        raise SystemExit("The itch.io index.html does not use a relative base URL.")

    digest = hashlib.sha256(output.read_bytes()).hexdigest().upper()
    print(json.dumps({
        "ok": True,
        "output": str(output),
        "sha256": digest,
        "zip_bytes": output.stat().st_size,
        "extracted_bytes": extracted_size,
        "file_count": len(entries),
        "index_at_root": True,
        "zip_crc": "ok",
        "relative_base_href": True,
    }, indent=2))


if __name__ == "__main__":
    main()
