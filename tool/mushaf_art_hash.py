#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
mushaf_art_hash.py — integrity hash of the bundled Mushaf page art.

Computes one SHA-256 over the 604 gzipped SVG pages
(`assets/mushaf/pages_svg/NNN.svg.gz`, page order 001..604), so any change to
the artwork itself is detectable. Phase 80 / M1: prove the rendering art is
untouched while the layout data is corrected. Reused by the M5 QA tool.

    python tool/mushaf_art_hash.py            # print the combined hash
    python tool/mushaf_art_hash.py --write    # also write it into
                                              # assets/mushaf/mushaf_manifest.json
                                              # as "art_set_sha256"

The hash is over the raw .gz bytes (not the decompressed SVG) — the .gz files
are exactly what ships in the APK.
"""
import hashlib
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = os.path.join(REPO, "assets", "mushaf", "pages_svg")
MANIFEST = os.path.join(REPO, "assets", "mushaf", "mushaf_manifest.json")
PAGE_COUNT = 604


def combined_hash():
    h = hashlib.sha256()
    missing = []
    for pg in range(1, PAGE_COUNT + 1):
        path = os.path.join(ART_DIR, f"{pg:03d}.svg.gz")
        if not os.path.isfile(path):
            missing.append(pg)
            continue
        with open(path, "rb") as fh:
            data = fh.read()
        # domain-separate each page so reordering/splicing changes the digest
        h.update(f"{pg:03d}:{len(data)}:".encode("ascii"))
        h.update(data)
    if missing:
        raise SystemExit(f"ERROR: missing art files for pages {missing[:20]}"
                         f"{'…' if len(missing) > 20 else ''}")
    return h.hexdigest()


def main():
    digest = combined_hash()
    print(f"art_set_sha256 = {digest}")
    if "--write" in sys.argv[1:]:
        with open(MANIFEST, "r", encoding="utf-8") as fh:
            manifest = json.load(fh)
        manifest["art_set_sha256"] = digest
        with open(MANIFEST, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(manifest, fh, ensure_ascii=False, indent=2)
            fh.write("\n")
        print(f"wrote art_set_sha256 into {os.path.relpath(MANIFEST, REPO)}")


if __name__ == "__main__":
    main()
