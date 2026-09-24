"""Add public OGP images and locale-specific share pages to a Godot Web export."""

from __future__ import annotations

import html
import re
import shutil
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
WEB_EXPORT = PROJECT_ROOT / "builds" / "web"
OGP_SOURCE = PROJECT_ROOT / "assets" / "ogp"
SITE_ORIGIN = "https://noxsum.netlify.app"
OGP_MARKERS = ("<!-- NOXSUM_OGP_START -->", "<!-- NOXSUM_OGP_END -->")

PAGES = {
    "en": {
        "html_lang": "en",
        "locale": "en_US",
        "alternate_locale": "ja_JP",
        "title": "NOXSUM — Reconstruct the Past from the Shadows",
        "description": "NOX is gone. The shadows remember.",
        "image": "noxsum-en.png",
        "image_alt": "NOXSUM: Reconstruct the Past from the Shadows. NOX is gone. The shadows remember.",
    },
    "ja": {
        "html_lang": "ja",
        "locale": "ja_JP",
        "alternate_locale": "en_US",
        "title": "NOXSUM — 光と影の論理パズル",
        "description": "NOXはいない。影は覚えている。影から、過去を組み立てる。",
        "image": "noxsum-ja.png",
        "image_alt": "月明かりの街を眺めるNOXとNOXSUMのロゴ。NOXはいない。影は覚えている。",
    },
}


def meta_block(locale: str, page: dict[str, str]) -> str:
    url = f"{SITE_ORIGIN}/{locale}/"
    image_url = f"{SITE_ORIGIN}/ogp/{page['image']}"
    attrs = {
        "og:type": "website",
        "og:site_name": "NOXSUM",
        "og:title": page["title"],
        "og:description": page["description"],
        "og:url": url,
        "og:locale": page["locale"],
        "og:locale:alternate": page["alternate_locale"],
        "og:image": image_url,
        "og:image:width": "1731",
        "og:image:height": "909",
        "og:image:alt": page["image_alt"],
        "twitter:card": "summary_large_image",
        "twitter:title": page["title"],
        "twitter:description": page["description"],
        "twitter:image": image_url,
    }
    tags = [
        f'<meta property="{html.escape(key, quote=True)}" content="{html.escape(value, quote=True)}">'
        for key, value in attrs.items()
    ]
    tags.append(f'<link rel="canonical" href="{html.escape(url, quote=True)}">')
    return "\n\t".join((OGP_MARKERS[0], *tags, OGP_MARKERS[1]))


def localized_page(export_html: str, locale: str, page: dict[str, str]) -> str:
    marker_pattern = re.compile(
        re.escape(OGP_MARKERS[0]) + r".*?" + re.escape(OGP_MARKERS[1]), re.DOTALL
    )
    localized, marker_count = marker_pattern.subn(meta_block(locale, page), export_html)
    if marker_count != 1:
        raise ValueError("Expected one NOXSUM OGP marker block in the exported HTML shell.")

    localized, lang_count = re.subn(
        r'<html\s+lang="[^"]*">',
        f'<html lang="{page["html_lang"]}">',
        localized,
        count=1,
    )
    if lang_count != 1:
        raise ValueError("Expected an html lang attribute in the exported HTML shell.")

    locale_marker = "const noxsumLocale = null;"
    if localized.count(locale_marker) != 1:
        raise ValueError("Expected one NOXSUM locale marker in the exported HTML shell.")
    return localized.replace(locale_marker, f'const noxsumLocale = "{locale}";', 1)


def main() -> None:
    source_html = WEB_EXPORT / "index.html"
    if not source_html.is_file():
        raise SystemExit(f"Missing {source_html}. Export the NOXSUM Web preset first.")

    export_html = source_html.read_text(encoding="utf-8")
    for locale, page in PAGES.items():
        source_image = OGP_SOURCE / page["image"]
        if not source_image.is_file():
            raise SystemExit(f"Missing OGP image: {source_image}")

        public_image = WEB_EXPORT / "ogp" / page["image"]
        public_image.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_image, public_image)

        localized = localized_page(export_html, locale, page)
        output_html = WEB_EXPORT / locale / "index.html"
        output_html.parent.mkdir(parents=True, exist_ok=True)
        output_html.write_text(localized, encoding="utf-8")
        print(f"Wrote /{locale}/ and /ogp/{page['image']}")


if __name__ == "__main__":
    main()