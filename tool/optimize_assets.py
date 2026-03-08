from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT / "assets"
PNG_SUFFIX = ".png"
WEBP_SUFFIX = ".webp"


def convert_png_to_webp(png_path: Path) -> bool:
    webp_path = png_path.with_suffix(WEBP_SUFFIX)

    if webp_path.exists() and webp_path.stat().st_mtime >= png_path.stat().st_mtime:
        return False

    with Image.open(png_path) as image:
        image.save(
            webp_path,
            format="WEBP",
            quality=82,
            method=6,
        )

    return True


def main() -> int:
    converted = 0

    for png_path in sorted(ASSETS_DIR.rglob(f"*{PNG_SUFFIX}")):
        if convert_png_to_webp(png_path):
            converted += 1
            print(
                f"optimized {png_path.relative_to(ROOT)} -> "
                f"{png_path.with_suffix(WEBP_SUFFIX).relative_to(ROOT)}"
            )

    if converted == 0:
        print("assets already optimized")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
