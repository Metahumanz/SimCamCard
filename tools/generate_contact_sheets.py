#!/usr/bin/env python3
"""Generate 4 contact-sheet PNGs for human visual review of the 34 dataset cards.

Each cell shows the card image scaled down, labeled with card ID + filename.
GT identity is NOT included in cells to avoid biasing visual review.

Read-only: does not modify any dataset file.

Usage:
    python3 tools/generate_contact_sheets.py
"""

from __future__ import annotations

import math
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    raise SystemExit("Pillow required: pip install Pillow")

ROOT = Path(__file__).resolve().parent.parent
CARDS_DIR = ROOT / "dataset" / "cards"
OUT_DIR = ROOT / "ai" / "validation" / "dataset-integrity"

CELL_W, CELL_H = 400, 280
LABEL_H = 40
COLS = 3
MARGIN = 10
BG = (30, 30, 30)
LABEL_COLOR = (220, 220, 220)

# Group definitions: (start_id, end_id)
GROUPS = [(1, 9), (10, 18), (19, 27), (28, 34)]


def make_sheet(start: int, end: int, out_path: Path) -> None:
    pngs = sorted(
        p for p in CARDS_DIR.glob("card-*.png")
        if start <= int(p.stem.split("-")[1]) <= end
    )
    rows = math.ceil(len(pngs) / COLS)
    sheet_w = COLS * (CELL_W + MARGIN) + MARGIN
    sheet_h = rows * (CELL_H + LABEL_H + MARGIN) + MARGIN

    sheet = Image.new("RGB", (sheet_w, sheet_h), BG)
    draw = ImageDraw.Draw(sheet)

    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 13)
    except (OSError, IOError):
        font = ImageFont.load_default()

    for idx, png_path in enumerate(pngs):
        col = idx % COLS
        row = idx // COLS
        x = MARGIN + col * (CELL_W + MARGIN)
        y = MARGIN + row * (CELL_H + LABEL_H + MARGIN)

        img = Image.open(png_path).convert("RGB")
        img.thumbnail((CELL_W, CELL_H), Image.LANCZOS)
        # Center the thumbnail in the cell.
        ix = x + (CELL_W - img.width) // 2
        iy = y + (CELL_H - img.height) // 2
        sheet.paste(img, (ix, iy))

        # Label: card-XXX filename
        card_id = png_path.stem.split("-")[1]
        label = f"card-{card_id}  {png_path.name}"
        draw.text((x, y + CELL_H + 4), label, fill=LABEL_COLOR, font=font)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_path, "PNG")
    print(f"Saved: {out_path.name} ({len(pngs)} cards, {sheet_w}x{sheet_h})")


def main() -> None:
    for start, end in GROUPS:
        out = OUT_DIR / f"cards-{start:03d}-{end:03d}.png"
        make_sheet(start, end, out)
    print("Done.")


if __name__ == "__main__":
    main()
