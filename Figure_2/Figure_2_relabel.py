"""Relabel Figure 2 panels (Log->Pro, Q->Qui, colored per Figure 5 convention) and compose A|B."""
import sys
from PIL import Image, ImageDraw, ImageFont
import matplotlib.font_manager as fm

src_dir, out_path = sys.argv[1], sys.argv[2]
BOLD = fm.findfont(fm.FontProperties(family="DejaVu Sans", weight="bold"))
REG = fm.findfont(fm.FontProperties(family="DejaVu Sans"))

PRO, QUI, INK = "#F3756B", "#37C0BF", "#000000"   # Figure_5_assemble.R a_text_cols
COLS = [(4, 431), (436, 864), (869, 1298), (1302, 1730)]   # grid columns (px)
HEADERS = [("Pro", PRO, "Rich"), ("Qui", QUI, "Rich"),
           ("Pro", PRO, "Minimal"), ("Qui", QUI, "Minimal")]
BASE1, BASE2 = 167, 286      # baselines of the original two header lines
FONT = ImageFont.truetype(BOLD, 84)   # sized so "Minimal" fits within a column


def relabel(path, grid_top):
    im = Image.open(path).convert("RGB")
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 1735, grid_top - 4], fill="white")   # clear old column headers only
    for (x0, x1), (state, col, medium) in zip(COLS, HEADERS):
        cx = (x0 + x1) / 2
        d.text((cx, BASE1), state, font=FONT, fill=col, anchor="ms")
        d.text((cx, BASE2), medium, font=FONT, fill=INK, anchor="ms")
    return im


a = relabel(f"{src_dir}/image1.jpg", 304)   # panel A: mCherry-AUT7
b = relabel(f"{src_dir}/image2.jpg", 309)   # panel B: mCherry-SFC1

margin, gap, top = 170, 170, 60
W = margin + a.width + gap + b.width + 40
H = top + max(a.height, b.height) + 40
fig = Image.new("RGB", (W, H), "white")
fig.paste(a, (margin, top))
fig.paste(b, (margin + a.width + gap, top))
d = ImageDraw.Draw(fig)
letter = ImageFont.truetype(REG, 140)
d.text((30, top + 20), "A", font=letter, fill=INK, anchor="lt")
d.text((margin + a.width + 30, top + 20), "B", font=letter, fill=INK, anchor="lt")
fig.save(out_path, dpi=(300, 300))
print(out_path, fig.size)
