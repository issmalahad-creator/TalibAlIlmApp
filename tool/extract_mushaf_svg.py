#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extract_mushaf_svg.py  —  build-time extractor for phase 79-mushaf.

Reads the 604 MushafDatabase Ligature-Based SVG pages (license
"Sadaqa-e-Jaria", fully open) and produces a compact *structural* model:

  assets/mushaf/mushaf_layout.json.gz   full per-page layout (gzipped JSON)
  assets/mushaf/mushaf_manifest.json    counts + checksums for validation

The glyph paths are DROPPED. What is kept, verbatim and losslessly, is the
semantic layer for every word:

    surah, ayah, word_index_in_ayah, line_number, hafs (uthmani), imlaey
    + a geometric bounding box [x,y,w,h] in the 382.68 x 547.09 viewBox

The bbox is computed as the union of every descendant path segment's
end-points and Bezier control points, so it is a conservative (never too
small) box — exactly what a hit-test / highlight layer needs. The bbox is
NOT semantic data; the rendering layer may use it or ignore it. The DB
schema stores the semantic columns independently of the geometry.

Usage:
    python tool/extract_mushaf_svg.py [SVG_DIR] [OUT_DIR]

Defaults:
    SVG_DIR = MushafDatabase-Ligature-Based-SVG-main_2/MushafDatabase-Ligature-Based-SVG-main/SVG V1.01
    OUT_DIR = assets/mushaf
"""
import sys, os, gzip, json, hashlib, re
import xml.etree.ElementTree as ET
from svg.path import parse_path

NS = "{http://www.w3.org/2000/svg}"
VIEWBOX = [0.0, 0.0, 382.68, 547.09]

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_SVG_DIR = os.path.join(
    REPO,
    "MushafDatabase-Ligature-Based-SVG-main_2",
    "MushafDatabase-Ligature-Based-SVG-main",
    "SVG V1.01",
)
DEFAULT_OUT_DIR = os.path.join(REPO, "assets", "mushaf")


def _pts(seg):
    for name in ("start", "end", "control1", "control2"):
        v = getattr(seg, name, None)
        if v is not None:
            yield v.real, v.imag


def bbox_of(el):
    """Union bbox of every <path d> descendant of el. Returns [x,y,w,h] or None."""
    minx = miny = float("inf")
    maxx = maxy = float("-inf")
    found = False
    for p in el.iter(NS + "path"):
        d = p.get("d")
        if not d:
            continue
        try:
            path = parse_path(d)
        except Exception:
            continue
        for seg in path:
            for x, y in _pts(seg):
                found = True
                if x < minx: minx = x
                if y < miny: miny = y
                if x > maxx: maxx = x
                if y > maxy: maxy = y
    if not found:
        return None
    return [round(minx, 2), round(miny, 2),
            round(maxx - minx, 2), round(maxy - miny, 2)]


def i3(s):
    return int(s) if s is not None else None


def extract_page(path):
    tree = ET.parse(path)
    root = tree.getroot()

    page_el = root.find(f".//{NS}g[@id='md-page']")
    page_no = int(page_el.get("data-page-number"))

    inner = root.find(f".//{NS}g[@id='md-page-inner']")
    rect = None
    if inner is not None and inner.get("data-rect"):
        rect = [round(float(v), 2) for v in inner.get("data-rect").split(",")]

    lines = []
    for g in root.iter(NS + "g"):
        gid = g.get("id") or ""
        if re.fullmatch(r"md-line-\d+", gid):
            lines.append({
                "n": int(g.get("data-line-number")),
                "type": g.get("data-type") or "text",
            })
    lines.sort(key=lambda l: l["n"])

    # Every md-word carries the full semantic tuple (surah / aya / word-index /
    # hafs / imlaey). Besides plain "text" words the dataset also indexes two
    # ornament glyphs *inside* the ayah word sequence: "juz-star" (۞ rub'
    # el-hizb, 199 of them) and "sajda-mehrab" (۩ sajdat al-tilawah, 15). They
    # occupy a real data-word-index-in-ayah, so dropping them would leave the
    # per-ayah word_index non-contiguous. Keep them; tag the non-text ones.
    WORD_TYPES = {"text", "juz-star", "sajda-mehrab"}
    words = []
    marks = []
    order = 0
    for g in root.iter(NS + "g"):
        gid = g.get("id") or ""
        if re.fullmatch(r"md-word-\d+", gid) and g.get("data-type") in WORD_TYPES:
            order += 1
            b = bbox_of(g)
            wtype = g.get("data-type")
            rec = {
                "s": i3(g.get("data-surah")),
                "a": i3(g.get("data-aya")),
                "w": i3(g.get("data-word-index-in-ayah")),
                "ln": i3(g.get("data-line-number")),
                "o": order,
                "hafs": g.get("data-hafs") or "",
                "iml": g.get("data-imlaey") or "",
                "b": b,
            }
            if wtype != "text":
                rec["t"] = wtype
            words.append(rec)
        elif re.fullmatch(r"md-aya-mark-\d+", gid):
            b = bbox_of(g)
            marks.append({
                "s": i3(g.get("data-surah")),
                "a": i3(g.get("data-aya")),
                "ln": i3(g.get("data-line-number")),
                "b": b,
            })

    # markers: margin sajda / juz-hizb, and surah-header lines
    markers = []
    for g in root.iter(NS + "g"):
        gid = g.get("id") or ""
        if gid == "md-non-quranic-margin-sajda":
            markers.append({"k": "sajda", "b": bbox_of(g)})
        elif gid in ("md-non-quranic-margin-juz-hisb", "md-non-quranic-margin-juz-hizb"):
            markers.append({"k": "juz-hizb", "b": bbox_of(g)})

    line_type = {l["n"]: l["type"] for l in lines}
    for l in lines:
        if l["type"] == "surah-name":
            # infer the surah this header introduces: first word on a later
            # line that starts a new ayah 1, else first following word.
            after = [w for w in words if (w["ln"] or 0) > l["n"]]
            cand = next((w for w in after if w["a"] == 1), None) or (after[0] if after else None)
            markers.append({"k": "surah-header", "ln": l["n"],
                            "s": cand["s"] if cand else None})
        elif l["type"] == "bismillah":
            markers.append({"k": "bismillah", "ln": l["n"]})

    return {
        "page": page_no,
        "rect": rect,
        "lines": lines,
        "words": words,
        "marks": marks,
        "markers": markers,
    }


def main():
    svg_dir = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SVG_DIR
    out_dir = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_OUT_DIR
    os.makedirs(out_dir, exist_ok=True)

    files = sorted(f for f in os.listdir(svg_dir) if re.fullmatch(r"\d{3}\.svg", f))
    if len(files) != 604:
        print(f"WARN: expected 604 svg files, found {len(files)}", file=sys.stderr)

    pages = []
    for i, f in enumerate(files, 1):
        pg = extract_page(os.path.join(svg_dir, f))
        pages.append(pg)
        if i % 50 == 0 or i == len(files):
            print(f"  {i}/{len(files)} pages", file=sys.stderr)

    pages.sort(key=lambda p: p["page"])
    layout = {
        "version": 1,
        "source": "MushafDatabase-Ligature-Based-SVG V1.01 (Sadaqa-e-Jaria)",
        "viewBox": VIEWBOX,
        "page_count": len(pages),
        "pages": pages,
    }

    payload = json.dumps(layout, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    gz_path = os.path.join(out_dir, "mushaf_layout.json.gz")
    with gzip.open(gz_path, "wb", compresslevel=9) as fh:
        fh.write(payload)

    # ---- manifest (validation aid) ----
    per_surah = {}
    total_words = 0
    total_marks = 0
    type_counts = {}
    for pg in pages:
        for w in pg["words"]:
            total_words += 1
            type_counts[w.get("t", "text")] = type_counts.get(w.get("t", "text"), 0) + 1
            s = w["s"]
            d = per_surah.setdefault(s, {"ayat": set(), "words": 0, "pages": set()})
            d["ayat"].add(w["a"])
            d["words"] += 1
            d["pages"].add(pg["page"])
        total_marks += len(pg["marks"])

    surah_manifest = {}
    for s in sorted(per_surah):
        d = per_surah[s]
        surah_manifest[str(s)] = {
            "ayah_count": len(d["ayat"]),
            "max_ayah": max(d["ayat"]),
            "word_count": d["words"],
            "first_page": min(d["pages"]),
            "last_page": max(d["pages"]),
        }

    manifest = {
        "version": 1,
        "source": layout["source"],
        "page_count": len(pages),
        "surah_count": len(per_surah),
        "total_words": total_words,
        "word_type_counts": type_counts,
        "total_aya_marks": total_marks,
        "layout_sha256": hashlib.sha256(payload).hexdigest(),
        "per_surah": surah_manifest,
    }
    with open(os.path.join(out_dir, "mushaf_manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, ensure_ascii=False, indent=2)

    print(f"\nwrote {gz_path}  ({os.path.getsize(gz_path)/1024:.1f} KiB gz, "
          f"{len(payload)/1024:.1f} KiB raw)")
    print(f"pages={len(pages)} surahs={len(per_surah)} words={total_words} "
          f"aya_marks={total_marks}")


if __name__ == "__main__":
    main()
