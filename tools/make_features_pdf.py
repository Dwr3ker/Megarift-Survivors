"""Builds docs/Megarift-Survivors-features.pdf: the features of this port, with pictures.

The text comes from the README (the "What's new" and "Controls" tables), so updating the README updates the PDF.
The pictures come from docs/features.json, which maps a feature name (the bold name in the README table) to screenshots in
docs/screens/. Screenshots are made by tools/capture_docs.ps1 (it runs the game); this script only lays out what exists.

It runs from the pre-commit hook (.githooks/pre-commit) so the PDF in the repository is rebuilt on every commit. The output is
deterministic (no timestamps), so it only changes when the README, the manifest or a screenshot changes.

Usage: python tools/make_features_pdf.py      (needs: pip install reportlab)
"""
import json
import re
import sys
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (Image, KeepTogether, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle)

ROOT = Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
DOCS = ROOT / "docs"
OUT = DOCS / "Megarift-Survivors-features.pdf"
MANIFEST = DOCS / "features.json"
GOLD = colors.HexColor("#b8860b")
INK = colors.HexColor("#1b1733")
MUTED = colors.HexColor("#5b5675")


def clean(text: str) -> str:
    """Markdown -> the small subset of HTML that reportlab paragraphs understand, with characters Helvetica can draw."""
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)          # links -> their text
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"\*([^*]+)\*", r"<i>\1</i>", text)
    text = re.sub(r"`([^`]+)`", r"<font face='Courier'>\1</font>", text)
    for a, b in {"→": "->", "−": "-", "–": "-", "—": "-", "×": "x", "≈": "~", "…": "...", "’": "'", "“": '"', "”": '"', "·": "-", "≥": ">=", "≤": "<="}.items():
        text = text.replace(a, b)
    return text.encode("latin-1", "replace").decode("latin-1")


def table_rows(md: str, heading: str):
    """Rows (list of cells) of the first markdown table after the heading."""
    i = md.find(heading)
    if i < 0:
        return []
    rows = []
    started = False
    for line in md[i:].splitlines()[1:]:
        if line.strip().startswith("|"):
            started = True
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if all(set(c) <= set("-: ") for c in cells):
                continue
            rows.append(cells)
        elif started:
            break
    return rows


def main() -> int:
    md = README.read_text(encoding="utf-8")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    version = re.search(r'config/version="([^"]+)"', (ROOT / "project.godot").read_text(encoding="utf-8"))
    version = version.group(1) if version else ""

    ss = getSampleStyleSheet()
    title = ParagraphStyle("t", parent=ss["Title"], fontName="Helvetica-Bold", fontSize=30, leading=36, textColor=INK, alignment=TA_CENTER, spaceAfter=10)
    sub = ParagraphStyle("s", parent=ss["Normal"], fontSize=13, textColor=MUTED, alignment=TA_CENTER, leading=18)
    h1 = ParagraphStyle("h1", parent=ss["Heading1"], fontSize=19, textColor=GOLD, spaceBefore=4, spaceAfter=4)
    h2 = ParagraphStyle("h2", parent=ss["Heading2"], fontSize=14, textColor=INK, spaceBefore=10, spaceAfter=2)
    body = ParagraphStyle("b", parent=ss["Normal"], fontSize=10.5, leading=14.5, textColor=INK)
    small = ParagraphStyle("sm", parent=ss["Normal"], fontSize=8.5, leading=11, textColor=MUTED)
    cap = ParagraphStyle("cap", parent=small, alignment=TA_CENTER)

    story = [Spacer(1, 28 * mm), Paragraph("Megarift Survivors", title),
             Paragraph("Features of this port" + (" - version " + clean(version) if version else ""), sub), Spacer(1, 8 * mm)]
    intro = re.search(r"^A free, fan-made.*$", md, re.M)
    if intro:
        story.append(Paragraph(clean(intro.group(0)), body))
    fork = re.search(r"^This is a fork of.*$", md, re.M)
    if fork:
        story += [Spacer(1, 4 * mm), Paragraph(clean(fork.group(0)), body)]
    story += [Spacer(1, 6 * mm), Paragraph("Generated from README.md and docs/features.json on every commit.", small), PageBreak()]

    story.append(Paragraph("What's new compared with the base port", h1))
    feats = table_rows(md, "## What's new compared with the base port")
    shown = 0
    for cells in feats:
        if len(cells) < 2 or not cells[0].strip():
            continue   # the empty header row
        name_raw, desc = cells[0], cells[1]
        name = clean(name_raw)
        block = [Paragraph(name, h2), Paragraph(clean(desc), body)]
        for rel in manifest.get(re.sub(r"\*\*|\*\([^)]*\)\*", "", name_raw).strip(), []):
            f = DOCS / rel
            if not f.exists():
                continue
            from PIL import Image as PILImage
            w, h = PILImage.open(f).size
            width = 150 * mm
            block += [Spacer(1, 2 * mm), Image(str(f), width=width, height=width * h / w), Paragraph(clean(Path(rel).stem.replace("_", " ")), cap)]
        story.append(KeepTogether(block))
        shown += 1
    if shown == 0:
        story.append(Paragraph("(no feature table found in README.md)", body))

    ctrl = table_rows(md, "## Controls")
    if ctrl:
        story += [PageBreak(), Paragraph("Controls", h1)]
        cell = ParagraphStyle("c", parent=body, fontSize=9, leading=12)
        data = [[Paragraph(clean(c) if i else "<b>" + clean(c) + "</b>", cell) for c in row] for i, row in enumerate(ctrl)]
        t = Table(data, colWidths=[32 * mm, 45 * mm, 35 * mm, 60 * mm], repeatRows=1)
        t.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#c9c4de")), ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#efe9ff")),
                               ("VALIGN", (0, 0), (-1, -1), "TOP"), ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3)]))
        story.append(t)
        tail = re.search(r"^The gamepad layout.*$", md, re.M)
        if tail:
            story += [Spacer(1, 4 * mm), Paragraph(clean(tail.group(0)), body)]

    story += [Spacer(1, 10 * mm), Paragraph("Free, non-profit fan project. Sprites: PMD SpriteCollab (CC BY-NC 4.0), see CREDITS.md. "
                                            "Pokemon and its characters are trademarks of Nintendo, Creatures Inc. and GAME FREAK inc.", small)]

    DOCS.mkdir(exist_ok=True)

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(MUTED)
        canvas.drawString(18 * mm, 10 * mm, "Megarift Survivors - features")
        canvas.drawRightString(A4[0] - 18 * mm, 10 * mm, "Page %d" % doc.page)
        canvas.restoreState()

    doc = SimpleDocTemplate(str(OUT), pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=16 * mm, bottomMargin=18 * mm,
                            title="Megarift Survivors - features", author="Dwr3ker", invariant=1)
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print("wrote", OUT.relative_to(ROOT), "-", shown, "features,", sum(len(v) for v in manifest.values()), "pictures listed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
