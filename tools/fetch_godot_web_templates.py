#!/usr/bin/env python3
"""Fetch only Godot's single-threaded Web templates from the official release."""

from __future__ import annotations

import argparse
import io
import json
import os
import re
import shutil
import sys
import tempfile
import urllib.error
import urllib.request
import zipfile
from collections import OrderedDict
from pathlib import Path
from typing import BinaryIO, Optional


USER_AGENT = "NOXSUM-Godot-Web-template-fetcher/1.0"
TEMPLATE_FILENAMES = (
    "web_nothreads_debug.zip",
    "web_nothreads_release.zip",
)


def get_json(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


class RemoteRangeFile(io.RawIOBase):
    """Read a remote file via validated HTTP range requests for zipfile."""

    def __init__(self, url: str, size: int) -> None:
        super().__init__()
        self.url = url
        self.size = size
        self.position = 0
        self.block_size = 1024 * 1024
        self.cache: OrderedDict[int, bytes] = OrderedDict()
        self.etag: Optional[str] = None

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self.position

    def seek(self, offset: int, whence: int = io.SEEK_SET) -> int:
        if whence == io.SEEK_SET:
            position = offset
        elif whence == io.SEEK_CUR:
            position = self.position + offset
        elif whence == io.SEEK_END:
            position = self.size + offset
        else:
            raise ValueError("invalid whence")
        if position < 0:
            raise ValueError("negative seek position")
        self.position = position
        return position

    def _fetch_block(self, block_index: int) -> bytes:
        cached = self.cache.get(block_index)
        if cached is not None:
            self.cache.move_to_end(block_index)
            return cached

        start = block_index * self.block_size
        end = min(start + self.block_size, self.size) - 1
        request = urllib.request.Request(
            self.url,
            headers={"User-Agent": USER_AGENT, "Range": f"bytes={start}-{end}"},
        )
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError(
                    f"Server did not honor range request (HTTP {response.status})."
                )
            expected_range = f"bytes {start}-{end}/{self.size}"
            if response.headers.get("Content-Range") != expected_range:
                raise RuntimeError(
                    "Unexpected Content-Range: "
                    f"{response.headers.get('Content-Range')!r}; "
                    f"expected {expected_range!r}."
                )
            current_etag = response.headers.get("ETag")
            if self.etag is not None and current_etag != self.etag:
                raise RuntimeError("The release asset changed during download.")
            self.etag = current_etag
            data = response.read()
        if len(data) != end - start + 1:
            raise RuntimeError("The server returned an incomplete byte range.")

        self.cache[block_index] = data
        while len(self.cache) > 8:
            self.cache.popitem(last=False)
        return data

    def read(self, size: int = -1) -> bytes:
        if self.position >= self.size:
            return b""
        if size is None or size < 0:
            size = self.size - self.position
        size = min(size, self.size - self.position)
        output = bytearray()
        while size > 0:
            block_index = self.position // self.block_size
            block = self._fetch_block(block_index)
            offset = self.position % self.block_size
            count = min(size, len(block) - offset)
            output.extend(block[offset : offset + count])
            self.position += count
            size -= count
        return bytes(output)


def default_target_dir(version: str) -> Path:
    appdata = os.environ.get("APPDATA")
    if appdata:
        root = Path(appdata)
    else:
        root = Path.home() / "AppData" / "Roaming"
    return root / "Godot" / "export_templates" / version


def fetch_templates(tag: str, target_dir: Path, install: bool) -> int:
    release_url = f"https://api.github.com/repos/godotengine/godot-builds/releases/tags/{tag}"
    release = get_json(release_url)
    asset_name = f"Godot_v{tag}_export_templates.tpz"
    asset = next((item for item in release["assets"] if item["name"] == asset_name), None)
    if asset is None:
        raise RuntimeError(f"Official release asset {asset_name} was not found.")

    size = int(asset["size"])
    digest = asset.get("digest") or "not provided by release API"
    print(f"Official asset: {asset_name} ({size:,} bytes; {digest})")

    with RemoteRangeFile(asset["browser_download_url"], size) as remote:
        with zipfile.ZipFile(remote) as package:
            infos = {
                Path(info.filename).name: info
                for info in package.infolist()
                if Path(info.filename).name in TEMPLATE_FILENAMES
            }
            missing = [name for name in TEMPLATE_FILENAMES if name not in infos]
            if missing:
                raise RuntimeError(
                    "The official package is missing expected single-threaded Web "
                    f"templates: {', '.join(missing)}."
                )
            for name in TEMPLATE_FILENAMES:
                info = infos[name]
                print(f"{name}: {info.file_size:,} bytes (CRC-32 checked by zipfile)")

            if not install:
                print("Inspection only. Pass --install to place these files in the Godot template folder.")
                return 0

            existing = [name for name in TEMPLATE_FILENAMES if (target_dir / name).exists()]
            if existing:
                raise RuntimeError(
                    "Refusing to overwrite existing template(s): " + ", ".join(existing)
                )

            target_dir.mkdir(parents=True, exist_ok=True)
            for name in TEMPLATE_FILENAMES:
                info = infos[name]
                fd, partial_name = tempfile.mkstemp(
                    prefix=f".{name}.", suffix=".partial", dir=target_dir
                )
                os.close(fd)
                partial_path = Path(partial_name)
                try:
                    with package.open(info, "r") as source, partial_path.open("wb") as target:
                        shutil.copyfileobj(source, target, length=1024 * 1024)
                    if not zipfile.is_zipfile(partial_path):
                        raise RuntimeError(f"Downloaded template {name} is not a valid zip file.")
                    os.replace(partial_path, target_dir / name)
                    print(f"Installed: {target_dir / name}")
                finally:
                    if partial_path.exists():
                        partial_path.unlink()

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", default="4.7-stable", help="Godot release tag (default: 4.7-stable)")
    parser.add_argument(
        "--version-dir",
        default="4.7.stable",
        help="Godot export-template version folder (default: 4.7.stable)",
    )
    parser.add_argument(
        "--target-dir",
        type=Path,
        help="Override the template install directory (default: %%APPDATA%%/Godot/export_templates/<version>)",
    )
    parser.add_argument(
        "--install",
        action="store_true",
        help="Download and install the two single-threaded Web templates; otherwise only inspect the package.",
    )
    args = parser.parse_args()
    target_dir = args.target_dir or default_target_dir(args.version_dir)
    try:
        return fetch_templates(args.tag, target_dir, args.install)
    except (OSError, urllib.error.URLError, zipfile.BadZipFile, RuntimeError, KeyError, ValueError) as error:
        print(f"Template setup failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
