"""Turns the PNG screenshots in docs/screens/ into JPEGs (max 1280 px wide) so the repository and the PDF stay small."""
from pathlib import Path
from PIL import Image

SCREENS = Path(__file__).resolve().parent.parent / "docs" / "screens"
n = 0
for png in sorted(SCREENS.glob("*.png")):
    im = Image.open(png).convert("RGB")
    if im.width > 1280:
        im = im.resize((1280, round(im.height * 1280 / im.width)), Image.LANCZOS)
    im.save(png.with_suffix(".jpg"), quality=84, optimize=True, progressive=False)
    png.unlink()
    n += 1
print("optimized", n, "screenshots")
