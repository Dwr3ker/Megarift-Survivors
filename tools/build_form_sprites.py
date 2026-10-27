"""Build Godot-ready form sprite sheets (Mega/Primal/Crowned/Forme) from PMD SpriteCollab.

Conventions reverse-engineered from the base port (verified pixel-identical for Charizard):
  - sheet = SpriteCollab <Anim>-Anim.png copied as-is (8 direction rows, n frames per row)
  - meta  = {"s": ShadowSize, "a": {Anim: {w,h,n,r:8,d:[durations],ax,ay}}, "sh": has_shiny}
  - ax, ay = (white pixel of <Anim>-Shadow.png, frame 0 / row 0) - 0.5
  - shiny sheets live in <id>/s/ and come from SpriteCollab <dex>/<form>/0001/
Form sprites become pseudo-species so the existing loaders work unchanged:
  form_id = 100000 + dex*100 + int(spriteCollab)

Usage: python tools/build_form_sprites.py tools/sprite_forms.json . [--only dex,dex]   (needs Pillow; downloads from PMD SpriteCollab)
Sprites are CC BY-NC 4.0 (PMD SpriteCollab); credits are written to FORM_CREDITS.md.
"""
import io, json, re, sys, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from PIL import Image

RAW = "https://raw.githubusercontent.com/PMDCollab/SpriteCollab/master/"
ANIMS = ["Idle", "Walk", "Attack", "Shoot", "Charge", "Hurt", "Faint"]
# The base port synthesizes anims SpriteCollab lacks: Faint = Hurt, Shoot = Charge (verified on dex 65, 282).
ALIAS = {"Faint": "Hurt", "Shoot": "Charge"}
HERE = Path(__file__).resolve().parent
CACHE = HERE / "sc_cache"


def fetch(rel):
    """Download (with on-disk cache). Returns bytes or None on 404."""
    f = CACHE / rel.replace("/", "__")
    if f.exists():
        return f.read_bytes() if f.stat().st_size else None
    try:
        with urllib.request.urlopen(RAW + rel, timeout=60) as r:
            data = r.read()
    except urllib.error.HTTPError as e:
        if e.code == 404:
            f.write_bytes(b"")
            return None
        raise
    f.write_bytes(data)
    return data


def form_id(dex, sc):
    return 100000 + dex * 100 + int(sc)


def parse_anim_data(xml):
    """Returns (ShadowSize, {anim: (w, h, durations)}); resolves <CopyOf> aliases."""
    t = xml.decode("utf8")
    ss = re.search(r"<ShadowSize>(\d+)", t)
    shadow = int(ss.group(1)) if ss else 1
    raw, copies = {}, {}
    for m in re.finditer(r"<Anim>(.*?)</Anim>", t, re.S):
        blk = m.group(1)
        name = re.search(r"<Name>(\w+)</Name>", blk).group(1)
        cp = re.search(r"<CopyOf>(\w+)</CopyOf>", blk)
        if cp:
            copies[name] = cp.group(1)
            continue
        fw, fh = re.search(r"<FrameWidth>(\d+)", blk), re.search(r"<FrameHeight>(\d+)", blk)
        if not fw or not fh:
            continue
        raw[name] = (int(fw.group(1)), int(fh.group(1)), [int(x) for x in re.findall(r"<Duration>(\d+)", blk)])
    for name, src in copies.items():
        if src in raw:
            raw[name] = raw[src]
    return shadow, {k: v for k, v in raw.items() if k in ANIMS}


def shadow_anchor(png, w, h):
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    for y in range(h):
        for x in range(w):
            if im.getpixel((x, y)) == (255, 255, 255, 255):
                return x - 0.5, y - 0.5
    return None


def save_sheet(png, dest):
    im = Image.open(io.BytesIO(png)).convert("RGBA")
    colors = im.getcolors(maxcolors=257)
    if colors is not None:  # <=256 colours: lossless palette PNG like the base port
        q = im.quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
        if Image.open(io.BytesIO(png)).convert("RGBA").tobytes() == q.convert("RGBA").tobytes():
            im = q
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, optimize=True)


def build(form, proj):
    """Per-animation fallback: form folder first, then the base species folder."""
    dex, sc = form["dex"], form["spriteCollab"]
    fid = form_id(dex, sc)
    srcs = [  # (normal dir, shiny dir)
        (f"sprite/{dex:04d}/{sc}/", f"sprite/{dex:04d}/{sc}/0001/"),
        (f"sprite/{dex:04d}/", f"sprite/{dex:04d}/0000/0001/"),
    ]
    data = []
    for nd, _ in srcs:
        xml = fetch(nd + "AnimData.xml")
        data.append(parse_anim_data(xml) if xml else (2, {}))
    shadow = data[0][0] if data[0][1] else data[1][0]
    meta_a, fallbacks, shiny_ok = {}, [], True
    for a in ANIMS:
        found = False
        for (nd, sd), (_, anims) in zip(srcs, data):
            for name in [a] + ([ALIAS[a]] if a in ALIAS else []):
                png = fetch(nd + f"{name}-Anim.png")
                sh = fetch(nd + f"{name}-Shadow.png")
                if png is None or sh is None or name not in anims:
                    continue
                w, h, d = anims[name]
                anc = shadow_anchor(sh, w, h)
                n = Image.open(io.BytesIO(png)).width // w
                if anc is None or n != len(d):
                    continue
                meta_a[a] = {"w": w, "h": h, "n": n, "r": 8, "d": d, "ax": anc[0], "ay": anc[1]}
                if nd != srcs[0][0] or name != a:
                    fallbacks.append(f"{a}<-{'base ' if nd != srcs[0][0] else ''}{name}")
                save_sheet(png, proj / f"assets/pokemon/{fid}/{a}.png")
                spng = fetch(sd + f"{name}-Anim.png")
                if spng is None:
                    shiny_ok = False
                else:
                    save_sheet(spng, proj / f"assets/pokemon/{fid}/s/{a}.png")
                found = True
                break
            if found:
                break
        if not found:
            return fid, None, f"no source for {a} (dex {dex} form {sc})"
    if not shiny_ok:  # incomplete shiny set: drop it so the game never mixes sheets
        import shutil
        shutil.rmtree(proj / f"assets/pokemon/{fid}/s", ignore_errors=True)
    credits = fetch(srcs[0][0] + "credits.txt")
    return fid, {"s": shadow, "a": meta_a, "sh": 1 if shiny_ok else 0}, (credits, fallbacks)


def main():
    forms = json.load(open(sys.argv[1], encoding="utf8"))
    proj = Path(sys.argv[2])
    only = None
    if "--only" in sys.argv:
        only = {int(x) for x in sys.argv[sys.argv.index("--only") + 1].split(",")}
    CACHE.mkdir(exist_ok=True)
    todo = [f for f in forms if only is None or f["dex"] in only]
    with ThreadPoolExecutor(8) as ex:
        results = list(ex.map(lambda f: build(f, proj), todo))
    meta_path = proj / "data/sprite_meta.json"
    meta = json.load(open(meta_path, encoding="utf8"))
    ok, bad, credit_rows, notes = 0, [], [], []
    for f, (fid, m, extra) in zip(todo, results):
        if m is None:
            bad.append((f["name"], extra))
            continue
        meta[str(fid)] = m
        ok += 1
        credit_rows.append((f["name"], fid, (extra[0] or b"").decode("utf8", "replace")))
        if extra[1]:
            notes.append(f["name"] + ": fell back to base species for " + ",".join(extra[1]))
    json.dump(meta, open(meta_path, "w", encoding="utf8"), separators=(",", ":"), ensure_ascii=False)

    names = {}
    raw = fetch("credit_names.txt")
    if raw:
        for line in raw.decode("utf8", "replace").splitlines()[1:]:
            p = line.split("\t")
            if len(p) >= 2:
                m = re.search(r"\d{6,}", p[1])
                names[m.group(0) if m else p[1].strip()] = p[0].strip()
    lines = ["# Form sprite credits (PMD SpriteCollab, CC BY-NC 4.0)\n"]
    for name, fid, c in credit_rows:
        who = []
        for row in c.splitlines():
            cols = row.split("\t")
            if len(cols) >= 3 and cols[2] == "CUR":
                for ident in re.findall(r"<@!?(\d+)>|(\S+)", cols[1]):
                    k = ident[0] or ident[1]
                    who.append(names.get(k, k))
        lines.append(f"- {name} (id {fid}): " + ", ".join(sorted(set(who))))
    (proj / "tools" / "form_credits.generated.md").write_text("\n".join(lines) + "\n", encoding="utf8")
    print(f"built {ok}/{len(todo)} forms")
    for n in notes:
        print("  note:", n)
    for n, why in bad:
        print("  SKIPPED", n, "-", why)


if __name__ == "__main__":
    main()
