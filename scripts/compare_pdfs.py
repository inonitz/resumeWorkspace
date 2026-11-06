#!/usr/bin/env python3
"""Compare two PDFs page by page, pixel by pixel.

Each page is rendered to an image with pdftoppm (from poppler-utils), and the
images are compared with Pillow. The script prints only page counts and the
number of differing pixels. It never prints the content of the PDFs.

Usage:
    scripts/compare_pdfs.py expected.pdf actual.pdf

Exit status:
    0  the PDFs render identically
    1  the PDFs differ
    2  wrong usage
"""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops

RESOLUTION_DPI = 150


def render_pages(pdf: Path, output_dir: Path) -> list[Path]:
    """Render each page of `pdf` to a PNG file, and return the files in page order."""
    subprocess.run(
        ["pdftoppm", "-r", str(RESOLUTION_DPI), "-png", str(pdf), str(output_dir / "page")],
        check=True,
    )
    # pdftoppm pads page numbers to one width (page-01 ... page-12),
    # so alphabetical order is page order.
    return sorted(output_dir.glob("page-*.png"))


def count_differing_pixels(expected_page: Path, actual_page: Path) -> int | None:
    """Return the number of pixels that differ, or None if the page sizes differ."""
    with Image.open(expected_page) as expected, Image.open(actual_page) as actual:
        expected_rgb = expected.convert("RGB")
        actual_rgb = actual.convert("RGB")

    if expected_rgb.size != actual_rgb.size:
        return None

    # A pixel differs if any of its three color channels differs.
    red, green, blue = ImageChops.difference(expected_rgb, actual_rgb).split()
    largest_channel_difference = ImageChops.lighter(ImageChops.lighter(red, green), blue)

    # Histogram bucket 0 holds the identical pixels; all other buckets differ.
    return sum(largest_channel_difference.histogram()[1:])


def compare(expected_pdf: Path, actual_pdf: Path) -> bool:
    """Print a per-page report, and return True if the PDFs render identically."""
    with tempfile.TemporaryDirectory() as expected_dir, tempfile.TemporaryDirectory() as actual_dir:
        expected_pages = render_pages(expected_pdf, Path(expected_dir))
        actual_pages = render_pages(actual_pdf, Path(actual_dir))

        print(f"pages: {len(expected_pages)} expected, {len(actual_pages)} actual")
        identical = len(expected_pages) == len(actual_pages)

        for page_number, (expected_page, actual_page) in enumerate(
            zip(expected_pages, actual_pages), start=1
        ):
            differing_pixels = count_differing_pixels(expected_page, actual_page)

            if differing_pixels is None:
                print(f"page {page_number}: page sizes differ")
                identical = False
            else:
                print(f"page {page_number}: {differing_pixels} differing pixels")
                if differing_pixels > 0:
                    identical = False

    return identical


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2

    identical = compare(Path(sys.argv[1]), Path(sys.argv[2]))
    print("result: identical" if identical else "result: different")
    return 0 if identical else 1


if __name__ == "__main__":
    sys.exit(main())
