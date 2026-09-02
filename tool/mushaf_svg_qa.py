#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
mushaf_svg_qa.py — forensic QA over all 604 bundled Mushaf page SVGs.

Phase 80 diagnostic (pre-M3). Answers: *where* does the "some pages look
shifted left / right" come from — the SVG itself (A), the layout metadata
(B), the renderer / ScreenTransform (C), or a layer interaction (D)?

For every `assets/mushaf/pages_svg/NNN.svg.gz` it records, WITHOUT changing
anything:

  - root: viewBox, width/height attrs, preserveAspectRatio
  - every `transform` attribute anywhere in the tree (id + value)
  - the group tree (ids, nesting) down to md-line level
  - `md-page-inner @data-rect`  (x0,y0,x1,y1 content frame)
  - true path bbox of:
        whole SVG   ·   md-page   ·   md-page-outer (frame, incl. margins)
        md-page-inner (text block)   ·   each margin marker group
  - elements that don't paint (fill:none / opacity:0 / display:none /
    visibility:hidden) whose geometry would still skew a naive bbox
  - odd/even (recto/verso) split of the frame centre-x and the text centre-x

Then it flags outliers and writes:
  docs/quran/reports/mushaf_svg_qa.json   (machine)
  docs/quran/reports/MUSHAF_SVG_QA.md     (human)

    python tool/mushaf_svg_qa.py [--pages 3,4,255,300]   # subset, prints only
    python tool/mushaf_svg_qa.py                          # all 604 + reports
"""
import gzip
import json
import os
import statistics
import sys
import xml.etree.ElementTree as ET

from svg.path import parse_path  # same parser tool/extract_mushaf_svg.py uses

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART_DIR = os.path.join(REPO, "assets", "mushaf", "pages_svg")
REPORT_DIR = os.path.join(REPO, "docs", "quran", "reports")
NS = "{http://www.w3.org/2000/svg}"
VBW, VBH = 382.68, 547.09
PAGE_COUNT = 604


def _seg_points(seg):
    for name in ("start", "end", "control1", "control2"):
        v = getattr(seg, name, None)
        if v is not None:
            yield v.real, v.imag


def _path_bbox_acc(d, acc):
    """Fold every start/end/control point of path `d` into acc = [x0,y0,x1,y1].

    Identical method to extract_mushaf_svg.py's bbox_of — resolves relative
    (lowercase) commands, so it is correct for MushafDatabase's `M … c …`
    glyph paths.
    """
    try:
        path = parse_path(d)
    except Exception:  # noqa: BLE001
        return
    for seg in path:
        for x, y in _seg_points(seg):
            acc[0] = min(acc[0], x); acc[1] = min(acc[1], y)
            acc[2] = max(acc[2], x); acc[3] = max(acc[3], y)


def _finish(acc):
    if acc[0] == float("inf"):
        return None
    return [round(acc[0], 2), round(acc[1], 2), round(acc[2], 2), round(acc[3], 2)]


def bbox_of(el):
    """Union bbox [x0,y0,x1,y1] of every <path d> at/under `el`, or None."""
    acc = [float("inf"), float("inf"), float("-inf"), float("-inf")]
    for p in el.iter(NS + "path"):
        d = p.get("d")
        if d:
            _path_bbox_acc(d, acc)
    return _finish(acc)


def bbox_excluding(el, drop_ids):
    """bbox of `el` counting only paths NOT inside a descendant whose id is in
    drop_ids (so md-page-outer minus md-page-inner = the frame + margins)."""
    dropped = set()
    for g in el.iter(NS + "g"):
        if g.get("id") in drop_ids:
            for p in g.iter(NS + "path"):
                dropped.add(id(p))
    acc = [float("inf"), float("inf"), float("-inf"), float("-inf")]
    for p in el.iter(NS + "path"):
        if id(p) in dropped:
            continue
        d = p.get("d")
        if d:
            _path_bbox_acc(d, acc)
    return _finish(acc)


def cx(b):
    return None if not b else round((b[0] + b[2]) / 2, 2)


def analyse_page(pg):
    path = os.path.join(ART_DIR, f"{pg:03d}.svg.gz")
    svg = gzip.open(path).read().decode("utf-8", "replace")
    root = ET.fromstring(svg)

    rec = {"page": pg, "odd": bool(pg % 2)}
    rec["viewBox"] = root.get("viewBox")
    rec["root_width"] = root.get("width")
    rec["root_height"] = root.get("height")
    rec["preserveAspectRatio"] = root.get("preserveAspectRatio")

    # every transform anywhere
    tr = []
    for el in root.iter():
        t = el.get("transform")
        if t:
            tr.append({"tag": el.tag.replace(NS, ""), "id": el.get("id"), "transform": t})
    rec["transforms"] = tr

    # non-painting geometry that could skew a naive bbox
    non_paint = 0
    for el in root.iter():
        style = (el.get("style") or "")
        if (el.get("fill") == "none" or el.get("opacity") == "0"
                or "display:none" in style or "visibility:hidden" in style
                or "opacity:0" in style.replace(" ", "")):
            if el.tag == NS + "path" and el.get("d"):
                non_paint += 1
    rec["non_painting_paths"] = non_paint

    def find(gid):
        return root.find(f".//{NS}g[@id='{gid}']")

    inner = find("md-page-inner")
    outer = find("md-page-outer")
    page_g = find("md-page")

    dr = inner.get("data-rect") if inner is not None else None
    rec["data_rect"] = [round(float(v), 2) for v in dr.split(",")] if dr else None

    rec["bbox_all"] = bbox_of(root)
    rec["bbox_md_page"] = bbox_of(page_g) if page_g is not None else None
    rec["bbox_frame"] = (bbox_excluding(outer, {"md-page-inner"})
                         if outer is not None else None)
    rec["bbox_text"] = bbox_of(inner) if inner is not None else None

    # margin markers (hizb / rub / sajda / juz)
    markers = {}
    for g in root.iter(NS + "g"):
        gid = g.get("id") or ""
        if gid.startswith("md-non-quranic-margin") or "sajda" in gid or "hizb" in gid or "juz" in gid:
            markers[gid] = bbox_of(g)
    rec["margin_markers"] = markers

    rec["cx_viewBox"] = round(VBW / 2, 2)
    rec["cx_frame"] = cx(rec["bbox_frame"])
    rec["cx_text"] = cx(rec["bbox_text"])
    rec["cx_data_rect"] = (round((rec["data_rect"][0] + rec["data_rect"][2]) / 2, 2)
                           if rec["data_rect"] else None)
    rec["text_width"] = (round(rec["bbox_text"][2] - rec["bbox_text"][0], 2)
                         if rec["bbox_text"] else None)
    rec["frame_width"] = (round(rec["bbox_frame"][2] - rec["bbox_frame"][0], 2)
                          if rec["bbox_frame"] else None)

    # flags
    f = []
    if rec["viewBox"] != f"0 0 {VBW} {VBH}":
        f.append("viewBox-differs")
    if tr:
        f.append(f"has-{len(tr)}-transforms")
    if rec["bbox_all"] and (rec["bbox_all"][0] < -1 or rec["bbox_all"][1] < -1
                            or rec["bbox_all"][2] > VBW + 1 or rec["bbox_all"][3] > VBH + 1):
        f.append("geometry-outside-viewBox")
    if non_paint:
        f.append(f"{non_paint}-non-painting-paths")
    rec["flags"] = f
    return rec


def main():
    args = sys.argv[1:]
    subset = None
    if "--pages" in args:
        subset = [int(x) for x in args[args.index("--pages") + 1].split(",")]

    pages = subset or list(range(1, PAGE_COUNT + 1))
    recs = []
    for pg in pages:
        try:
            recs.append(analyse_page(pg))
        except Exception as e:  # noqa: BLE001
            recs.append({"page": pg, "error": repr(e)})
        if not subset and pg % 100 == 0:
            print(f"  {pg}/{PAGE_COUNT}", file=sys.stderr)

    ok = [r for r in recs if "error" not in r]
    # ---- aggregate ----
    viewboxes = sorted({r["viewBox"] for r in ok})
    with_tr = [r["page"] for r in ok if r["transforms"]]
    outside = [r["page"] for r in ok if "geometry-outside-viewBox" in r["flags"]]
    nonpaint = [r["page"] for r in ok if r["non_painting_paths"]]

    odd = [r for r in ok if r["odd"]]
    even = [r for r in ok if not r["odd"]]

    def stat(rows, key):
        vals = [r[key] for r in rows if r.get(key) is not None]
        if not vals:
            return None
        return {
            "n": len(vals),
            "min": round(min(vals), 2),
            "median": round(statistics.median(vals), 2),
            "max": round(max(vals), 2),
        }

    summary = {
        "pages_analysed": len(ok),
        "errors": [r for r in recs if "error" in r],
        "distinct_viewBoxes": viewboxes,
        "pages_with_transforms": with_tr,
        "pages_with_geometry_outside_viewBox": outside,
        "pages_with_non_painting_paths": nonpaint,
        "viewBox_center_x": round(VBW / 2, 2),
        "frame_center_x": {
            "odd": stat(odd, "cx_frame"),
            "even": stat(even, "cx_frame"),
        },
        "text_center_x": {
            "odd": stat(odd, "cx_text"),
            "even": stat(even, "cx_text"),
        },
        "text_width": {
            "odd": stat(odd, "text_width"),
            "even": stat(even, "text_width"),
        },
        "frame_width": {
            "odd": stat(odd, "frame_width"),
            "even": stat(even, "frame_width"),
        },
    }

    # verdict heuristic
    fo = summary["frame_center_x"]["odd"]
    fe = summary["frame_center_x"]["even"]
    to_ = summary["text_center_x"]["odd"]
    te = summary["text_center_x"]["even"]
    verdict = []
    if viewboxes == [f"0 0 {VBW} {VBH}"] and not with_tr:
        verdict.append("viewBox uniform, NO transforms anywhere.")
    if fo and fe and abs(fo["median"] - fe["median"]) < 3:
        verdict.append(
            f"Frame centre-x is the SAME on odd ({fo['median']}) and even "
            f"({fe['median']}) pages → the decorative page border is centred "
            f"on every page.")
    if to_ and te and abs(to_["median"] - te["median"]) > 20:
        verdict.append(
            f"Text-block centre-x DIFFERS odd ({to_['median']}) vs even "
            f"({te['median']}) by ~{round(abs(to_['median'] - te['median']), 1)} "
            f"units → recto/verso inner-margin asymmetry, drawn into the SVG "
            f"paths themselves (not a transform, not metadata).")
    summary["verdict_notes"] = verdict

    os.makedirs(REPORT_DIR, exist_ok=True)
    with open(os.path.join(REPORT_DIR, "mushaf_svg_qa.json"), "w", encoding="utf-8") as fh:
        json.dump({"summary": summary, "pages": recs}, fh, ensure_ascii=False, indent=1)

    md = ["# Mushaf SVG QA — forensic report", "",
          f"Pages analysed: **{len(ok)}** / {PAGE_COUNT}", ""]
    md.append("## Root-level")
    md.append(f"- distinct viewBoxes: `{viewboxes}`")
    md.append(f"- pages with any `transform`: **{len(with_tr)}**"
              + (f" — {with_tr[:30]}" if with_tr else " (none)"))
    md.append(f"- pages with geometry outside the viewBox: **{len(outside)}**"
              + (f" — {outside[:30]}" if outside else ""))
    md.append(f"- pages with non-painting paths: **{len(nonpaint)}**"
              + (f" — {nonpaint[:30]}" if nonpaint else ""))
    md.append("")
    md.append("## Recto (odd) vs verso (even)")
    md.append("| metric | odd median | even median | Δ |")
    md.append("|---|---|---|---|")
    for k, lbl in [("frame_center_x", "frame centre-x"),
                   ("text_center_x", "text centre-x"),
                   ("text_width", "text width"),
                   ("frame_width", "frame width")]:
        o = summary[k]["odd"]; e = summary[k]["even"]
        if o and e:
            md.append(f"| {lbl} | {o['median']} | {e['median']} | "
                      f"{round(e['median'] - o['median'], 2)} |")
    md.append(f"\nviewBox centre-x = {round(VBW/2,2)}")
    md.append("")
    md.append("## Verdict")
    for v in verdict:
        md.append(f"- {v}")
    md.append("")
    md.append("## Per-page (first 24)")
    md.append("| pg | o/e | data-rect | frame cx | text cx | text w | flags |")
    md.append("|---|---|---|---|---|---|---|")
    for r in ok[:24]:
        md.append(f"| {r['page']} | {'o' if r['odd'] else 'e'} | "
                  f"{r['data_rect']} | {r['cx_frame']} | {r['cx_text']} | "
                  f"{r['text_width']} | {','.join(r['flags']) or '-'} |")
    with open(os.path.join(REPORT_DIR, "MUSHAF_SVG_QA.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(md) + "\n")

    print("\n".join(md))
    print(f"\nwrote {os.path.relpath(os.path.join(REPORT_DIR, 'mushaf_svg_qa.json'), REPO)}")


if __name__ == "__main__":
    main()
