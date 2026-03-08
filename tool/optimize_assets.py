from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT / "assets"
PNG_SUFFIX = ".png"
WEBP_SUFFIX = ".webp"
MOBILE_WEBP_SUFFIX = "_mobile.webp"
EXCLUDED_WEBP_STEMS = {"rs_icon"}

MOBILE_MAX_DIMENSIONS: dict[str, tuple[int, int]] = {
    "rs_man": (240, 480),
    "rs_woman": (240, 480),
    "rs_other": (240, 480),
    "rs_fall_1": (192, 192),
    "rs_fall_2": (192, 192),
    "rs_fall_3": (192, 192),
    "rs_fall_4": (192, 192),
    "rs_fall_5": (192, 192),
    "rs_fall_6": (192, 192),
    "rs_fall_7": (192, 192),
}


def convert_png_to_webp(png_path: Path) -> bool:
    if png_path.stem in EXCLUDED_WEBP_STEMS:
        return False

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


def convert_png_to_mobile_webp(png_path: Path) -> bool:
    max_dimensions = MOBILE_MAX_DIMENSIONS.get(png_path.stem)
    if max_dimensions is None:
        return False

    mobile_webp_path = png_path.with_name(f"{png_path.stem}{MOBILE_WEBP_SUFFIX}")

    if (
        mobile_webp_path.exists()
        and mobile_webp_path.stat().st_mtime >= png_path.stat().st_mtime
    ):
        return False

    max_width, max_height = max_dimensions

    with Image.open(png_path) as image:
        image.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)
        image.save(
            mobile_webp_path,
            format="WEBP",
            quality=80,
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
        if convert_png_to_mobile_webp(png_path):
            converted += 1
            print(
                f"optimized {png_path.relative_to(ROOT)} -> "
                f"{png_path.with_name(f'{png_path.stem}{MOBILE_WEBP_SUFFIX}').relative_to(ROOT)}"
            )

    if converted == 0:
        print("assets already optimized")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
