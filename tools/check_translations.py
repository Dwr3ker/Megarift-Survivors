"""Missing-translation check: every L.t("...") text in the given scripts (or the whole scripts/ folder) must exist in
each of the 11 language files. Latin American Spanish may fall back to Spain Spanish.

Usage: python tools/check_translations.py [script.gd ...]
Exit code 1 and a list per language when something is missing.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LANGS = ["es", "es_419", "fr", "it", "ja", "pt_BR", "pt_PT", "ru", "vi", "zh_CN", "zh_HK"]
PAT = re.compile(r'L\.t\("((?:[^"\\]|\\.)*)"\)')


def keys_in(files):
    out = set()
    for f in files:
        out |= {k.replace('\\"', '"') for k in PAT.findall(Path(f).read_text(encoding="utf-8"))}
    return out


def main(argv):
    files = [ROOT / a for a in argv] if argv else sorted((ROOT / "scripts").glob("*.gd"))
    keys = keys_in(files)
    es = json.loads((ROOT / "data" / "lang_es.json").read_text(encoding="utf-8"))
    missing = {}
    for c in LANGS:
        d = json.loads((ROOT / "data" / ("lang_%s.json" % c)).read_text(encoding="utf-8"))
        miss = [k for k in sorted(keys) if k not in d and not (c == "es_419" and k in es)]
        if miss:
            missing[c] = miss
    print("%d texts checked in %d files" % (len(keys), len(files)))
    if not missing:
        print("nothing missing in the 11 languages")
        return 0
    for c, miss in missing.items():
        print("%s: %d missing" % (c, len(miss)))
        for k in miss[:40]:
            print("   ", k)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
