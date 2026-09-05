#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extract_mushaf_glyphs.py  —  Phase G-t2 · sub-word glyph geometry.

`extract_mushaf_svg.py` (frozen, gate M5) collapses every word to ONE union
box. This tool goes one level deeper into the **already-bundled** page SVGs
(`assets/mushaf/pages_svg/NNN.svg.gz`) and records, per text word, the box
of each **ligature** (base `<path data-text>`) and each **diacritic**
(`md-diacritic-* <path data-diacritic>`), plus the `[cs, ce)` span of the
word's own Uthmani text each ligature covers — so the tajwīd overlay
(G-t3) can translate a rule's char range into a run of boxes.

It does NOT modify `extract_mushaf_svg.py`; it imports `bbox_of` / `NS`
from it for identical geometry.

  assets/mushaf/mushaf_glyphs.json.gz
      {"v":1,"viewBox":[..],"pages":[{"p":N,"words":[
          {"o":word_order,"n":len(hafs),
           "g":[{"k":0,"t":"بسم","cs":0,"ce":4,"b":[x,y,w,h]},        k=0 ligature
                {"k":1,"t":"kasra","cs":3,"ce":4,"b":[x,y,w,h]}, …]}  k=1 diacritic
      ]}]}

  py tool/extract_mushaf_glyphs.py            # base + diacritic (default)
  py tool/extract_mushaf_glyphs.py --all      # + dots (iʿjām) + waqf marks

Build FAILS if the gzipped asset exceeds 10 MB.
"""
import gzip
import hashlib
import io
import json
import os
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_mushaf_svg import NS, VIEWBOX, bbox_of  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGES_DIR = os.path.join(REPO, "assets", "mushaf", "pages_svg")
OUT = os.path.join(REPO, "assets", "mushaf", "mushaf_glyphs.json.gz")
REPORT = os.path.join(REPO, "docs", "quran", "reports", "MUSHAF_GLYPHS_QA.md")
SIZE_LIMIT = 10 * 1024 * 1024

# data-diacritic value  →  the Uthmani codepoint(s) it renders, so a
# diacritic <path> can be pinned to its exact index in the word's `hafs`.
DIA_CP = {
    "fatha": "َ", "kasra": "ِ", "damma": "ُ",
    "fathatan": "ً", "kasratan": "ٍ", "dammatan": "ٌ",
    "shadda": "ّ", "sukun": "ْۡ۟۠",
    "madda": "ٓ", "hamza": "ٕٔء",
    "superscript-alef": "ٰ", "dagger-alef": "ٰ",
    "small-alef": "ٰ", "alef-khnjariah": "ٰ",
    "maddah": "ٓ",
}

MARK = set("ًٌٍَُِّْٕٓٔ"
           "ٰۣ۟۠ۡۢۤۥۦۧۨ"
           "ࣰࣱࣲ۪ۭ۫۬")


def is_base(ch):
    return unicodedata.category(ch) != "Mn"


def base_indices(h):
    """indices in `h` of every base (non-mark) char."""
    return [i for i, c in enumerate(h) if is_base(c)]


def span_end(h, start, n_more_bases_from):
    """char index in `h` just before the (n_more_bases_from)-th remaining base
    starts — i.e. `start` plus this ligature's base chars plus their trailing
    marks, stopping where the next ligature's first base begins."""
    return n_more_bases_from if n_more_bases_from is not None else len(h)


def extract_page(raw, want_all):
    root = ET.fromstring(raw)
    page_el = root.find(f".//{NS}g[@id='md-page']")
    page_no = int(page_el.get("data-page-number"))

    # `order` MUST advance for the exact same set extract_mushaf_svg.py counts
    # (text + the two ornament word types) so glyph `o` lines up with the
    # layout's `o`; we only EMIT glyph records for text words.
    WORD_TYPES = {"text", "juz-star", "sajda-mehrab"}
    words = []
    order = 0
    for g in root.iter(NS + "g"):
        gid = g.get("id") or ""
        if not re.fullmatch(r"md-word-\d+", gid):
            continue
        if g.get("data-type") not in WORD_TYPES:
            continue
        order += 1
        if g.get("data-type") != "text":
            continue
        hafs = g.get("data-hafs") or ""
        if not hafs:
            continue

        bidx = base_indices(hafs)  # hafs-index of each base letter
        ligs = [x for x in g.iter(NS + "g")
                if re.fullmatch(r"md-ligature-\d+-\d+", x.get("id") or "")]

        glyphs = []
        base_cursor = 0  # base letters consumed so far
        nbase = len(bidx)
        last_cs, last_ce = 0, len(hafs)  # span the current ligature's marks fall in
        for lg in ligs:
            base_path = next(
                (p for p in lg.iter(NS + "path") if p.get("data-text") is not None),
                None)
            dtext = (base_path.get("data-text") if base_path is not None else "") or ""

            if base_path is not None and base_cursor < nbase:
                # this ligature owns the next `nb` base letters (clamped) + any
                # trailing marks up to where the next ligature's first base begins
                nb = min(len(dtext) or 1, nbase - base_cursor)
                cs = bidx[base_cursor]
                nxt = base_cursor + nb
                ce = bidx[nxt] if nxt < nbase else len(hafs)
                if ce <= cs:
                    ce = len(hafs)
                base_cursor = nxt
                last_cs, last_ce = cs, ce
                bb = bbox_of(base_path)
                if bb:
                    glyphs.append({"k": 0, "t": dtext, "cs": cs, "ce": ce, "b": bb})
            else:
                # a ligature group with no readable base (or the word's letters
                # are all already mapped) — its marks attach to the last span
                cs, ce = last_cs, last_ce

            # diacritic paths grouped under this ligature
            dia_group = next(
                (x for x in lg.iter(NS + "g")
                 if re.fullmatch(r"md-diacritic-\d+-\d+", x.get("id") or "")), None)
            if dia_group is not None:
                # marks physically inside this ligature's hafs span, in order
                span_marks = [i for i in range(cs, ce) if hafs[i] in MARK]
                mi = 0
                for p in dia_group.iter(NS + "path"):
                    dt = p.get("data-type")
                    dv = (p.get("data-diacritic") or p.get("data-dots")
                          or p.get("data-waqf") or dt or "")
                    is_dia = p.get("data-diacritic") is not None
                    is_extra = (p.get("data-dots") is not None
                                or p.get("data-waqf") is not None)
                    if not is_dia and not (want_all and is_extra):
                        continue
                    bb = bbox_of(p)
                    if not bb:
                        continue
                    # pin to an exact hafs index where possible
                    hit = None
                    if is_dia:
                        want = DIA_CP.get(p.get("data-diacritic"), "")
                        hit = next((i for i in span_marks if hafs[i] in want), None)
                        if hit is None and mi < len(span_marks):
                            hit = span_marks[mi]
                        if hit is not None:
                            mi += 1
                    gi = hit if hit is not None else min(cs, len(hafs) - 1)
                    gi = max(0, gi)
                    ge = gi + 1
                    glyphs.append({"k": 1, "t": dv, "cs": gi, "ce": ge, "b": bb})

        if not any(gg["k"] == 0 for gg in glyphs):
            # a text word with no readable base path — keep an empty marker so
            # the QA gate can see it; overlay just won't colour it
            glyphs = []
        glyphs.sort(key=lambda x: (x["cs"], x["k"]))
        words.append({"o": order, "n": len(hafs), "g": glyphs})

    return {"p": page_no, "words": words}


def main():
    want_all = "--all" in sys.argv
    files = sorted(f for f in os.listdir(PAGES_DIR)
                   if re.fullmatch(r"\d{3}\.svg\.gz", f))
    if len(files) != 604:
        print(f"WARN expected 604 page svgs, found {len(files)}", file=sys.stderr)

    pages = []
    for i, f in enumerate(files, 1):
        raw = gzip.open(os.path.join(PAGES_DIR, f)).read()
        pages.append(extract_page(raw, want_all))
        if i % 100 == 0 or i == len(files):
            print(f"  {i}/{len(files)}", file=sys.stderr)
    pages.sort(key=lambda p: p["p"])

    payload = json.dumps(
        {"v": 1, "viewBox": VIEWBOX, "all": want_all, "pages": pages},
        ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    with gzip.open(OUT, "wb", compresslevel=9) as fh:
        fh.write(payload)
    size = os.path.getsize(OUT)
    sha = hashlib.sha256(payload).hexdigest()

    nwords = sum(len(p["words"]) for p in pages)
    nglyphs = sum(len(w["g"]) for p in pages for w in p["words"])
    empties = sum(1 for p in pages for w in p["words"] if not w["g"])
    per_word = [len(w["g"]) for p in pages for w in p["words"] if w["g"]]
    mx = max(per_word) if per_word else 0

    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join([
        "# Mushaf sub-word glyph geometry — QA (Phase G-t2)", "",
        f"Source: `assets/mushaf/pages_svg/*.svg.gz` (MushafDatabase Ligature-"
        f"Based SVG V1.01). Extracted by `tool/extract_mushaf_glyphs.py`"
        f"{' --all' if want_all else ''}.", "",
        f"- pages: **{len(pages)} / 604**",
        f"- text words: **{nwords}**",
        f"- glyph boxes: **{nglyphs}**  (base ligatures + diacritics"
        f"{' + dots/waqf' if want_all else ''})",
        f"- words with no readable base path: **{empties}**",
        f"- max glyphs on one word: **{mx}**",
        f"- asset: `mushaf_glyphs.json.gz` **{size/1024:.0f} KB** gz "
        f"(limit {SIZE_LIMIT // (1024*1024)} MB)",
        f"- sha256: `{sha}`", "",
    ]) + "\n")

    print(f"mushaf_glyphs.json.gz  {size/1024:.0f} KB gz  ·  {len(pages)} pages "
          f"·  {nwords} words  ·  {nglyphs} glyphs  ·  max {mx}/word  ·  "
          f"{empties} empty")
    print(f"  sha256 {sha}")
    if size > SIZE_LIMIT:
        sys.exit(f"FAIL: {size} bytes > {SIZE_LIMIT} limit — drop diacritics or "
                 f"split per-juz.")


if __name__ == "__main__":
    main()
