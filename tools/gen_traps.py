# Usage: python tools/gen_traps.py assets/world
# Trap plates: an oval stone pressure plate set into the ground (same angle as the spring), with a recessed core
# in the trap's colour and its sign. 28x18 pixel art, drawn at WTex.SC like the other world objects.
from PIL import Image
import sys

OUT = sys.argv[1]
W, H = 28, 18
CX, CY = 13.5, 8.5

def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

INK = hexc("#15131f")
RIM_HI = hexc("#c9ccd6")
RIM = hexc("#9297a6")
RIM_MID = hexc("#6d7282")
RIM_LO = hexc("#4a4e5c")
SEAM = hexc("#3a3d49")

TYPES = {
    # base (core), deep (core shadow), hi (sign), glow (brightest)
    "poison": ("#5b2a82", "#341450", "#c27cff", "#f0d2ff"),
    "ice": ("#3f7a2a", "#24491a", "#a8ec62", "#e8ffc8"),      # sticky goo: slows
    "fire": ("#7a250c", "#45110a", "#ff8a2e", "#ffe27a"),
    "freeze": ("#2a6a9e", "#163d63", "#bfeeff", "#ffffff"),
    "shock": ("#6e5a0c", "#3d3106", "#ffe14d", "#fffbd0"),
    "sleep": ("#3c447a", "#21274a", "#c9cfff", "#ffffff"),
    "confuse": ("#6e2160", "#3d0f35", "#ff7ad9", "#ffe0f6"),
}

# signs, centred in the core: '#' = sign colour, 'o' = glow, '+' = deep accent
SIGNS = {
    "poison": [
        "....##...",
        "...#oo#..",
        "...#oo#.#",
        "....##.#o",
        ".##.....#",
        "#oo#.....",
        ".##......",
    ],
    "ice": [
        "#...#...#",
        ".#..#..#.",
        "..#####..",
        "###.o.###",
        "..#####..",
        ".#..#..#.",
        "#...#...#",
    ],
    "fire": [
        "..#....#.",
        "...#..#..",
        "#..#oo#..",
        ".##oooo#.",
        "...#oo#.#",
        "..#..#.#.",
        ".#....#..",
    ],
    "freeze": [
        "....#....",
        "..#.#.#..",
        "...###...",
        "####o####",
        "...###...",
        "..#.#.#..",
        "....#....",
    ],
    "shock": [
        ".....##..",
        "....##...",
        "...##....",
        "..#oooo#.",
        "....##...",
        "...##....",
        "..##.....",
    ],
    "sleep": [
        "...###...",
        "..##.oooo",
        ".##....o.",
        ".##...o..",
        ".##..oooo",
        "..##.....",
        "...###...",
    ],
    "confuse": [
        "..#####..",
        ".#.....#.",
        "#..###..#",
        "#.#..o#.#",
        "#.#.##..#",
        ".#.#...#.",
        "..#.###..",
    ],
}


def inside(x, y, a, b):
    dx = (x + 0.5 - CX) / a
    dy = (y + 0.5 - CY) / b
    return dx * dx + dy * dy <= 1.0


def plate(kind):
    base, deep, hi, glow = (hexc(c) for c in TYPES[kind])
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    for y in range(H):
        for x in range(W):
            if not inside(x, y, 14.0, 9.0):
                continue
            if not inside(x, y, 13.0, 8.0):
                px[x, y] = INK
                continue
            if inside(x, y, 9.6, 5.4):
                # recessed core: the rim's shadow darkens its top edge
                top_shadow = not inside(x, y + 1.6, 9.6, 5.4)
                px[x, y] = deep if top_shadow else base
                continue
            if inside(x, y, 10.6, 6.4):
                px[x, y] = INK   # the lip between rim and core
                continue
            # stone rim: lit from the top, darker at the bottom
            t = (y + 0.5 - CY) / 8.0
            if t < -0.62:
                c = RIM_HI
            elif t < -0.05:
                c = RIM
            elif t < 0.6:
                c = RIM_MID
            else:
                c = RIM_LO
            px[x, y] = c
    # stone seams cut across the rim (blocks)
    for sx, sy in [(4, 4), (9, 1), (18, 1), (23, 4), (3, 12), (9, 15), (18, 15), (24, 12)]:
        if px[sx, sy][3] and px[sx, sy] not in (INK,):
            px[sx, sy] = SEAM
    # sign
    rows = SIGNS[kind]
    sh, sw = len(rows), len(rows[0])
    ox = int(round(CX - sw / 2.0))
    oy = int(round(CY - sh / 2.0)) + 1
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            x, y = ox + i, oy + j
            if not inside(x, y, 9.6, 5.4):
                continue
            if ch == "#":
                px[x, y] = hi
            elif ch == "o":
                px[x, y] = glow
            elif ch == "+":
                px[x, y] = deep
    # drop the lone pixels at the very ends of the oval (they read as nubs)
    for _ in range(2):
        lone = []
        for y in range(H):
            for x in range(W):
                if px[x, y][3] == 0:
                    continue
                n = 0
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < W and 0 <= yy < H and px[xx, yy][3] > 0:
                        n += 1
                if n <= 1:
                    lone.append((x, y))
        for q in lone:
            px[q] = (0, 0, 0, 0)
    return im


for k in TYPES:
    plate(k).save("%s/trap_%s.png" % (OUT, k))
print("ok")
