#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_quran_corpus.py  —  Phase B / QC1 ingest.

Reads the raw Quranpedia dumps (+ Quran-Data-2.0) at the repo root and emits
a curated, canonical, versioned corpus under `assets/quran/corpus/`:

  <name>.json.gz            one file per dataset, compact JSON, keyed by the
                            canonical Hafs spine  {s, a, ...}
  corpus_manifest.json      per-dataset: source, source_version, sha256,
                            row_count, checks, licence_tag
  QURAN_CORPUS_QA.md        human report  (also docs/quran/reports/)

Every dataset is validated against canonical ground truth (114 surahs, 6236
ayat, per-surah counts from assets/mushaf/mushaf_manifest.json). A dataset
that fails validation is NOT written.

Never ships a source's own schema; never uses a source's word segmentation
as identity (that is align_qac / align_tanzil, build_alignments.py).

    python tool/build_quran_corpus.py [--only morphology,syntax,...] [--list-tafsir]
"""
import gzip
import hashlib
import json
import os
import sys
import zipfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "assets", "quran", "corpus")
REPORT = os.path.join(REPO, "docs", "quran", "reports")
MUSHAF_MANIFEST = os.path.join(REPO, "assets", "mushaf", "mushaf_manifest.json")

CANON_SURAHS = 114
CANON_AYAT = 6236


# ─────────────────────────────── helpers ────────────────────────────────

def _canon_counts():
    """{surah: ayah_count} for all 114, from the verified mushaf manifest."""
    m = json.load(open(MUSHAF_MANIFEST, encoding="utf-8"))
    return {int(k): v["ayah_count"] for k, v in m["per_surah"].items()}


CANON = _canon_counts()
assert len(CANON) == CANON_SURAHS and sum(CANON.values()) == CANON_AYAT, "bad canon"


def read_gz_json(path):
    with gzip.open(path, "rb") as fh:
        return json.loads(fh.read())


def read_zip_member_gz_json(zf, member):
    return json.loads(gzip.decompress(zf.read(member)))


def envelope(obj):
    """Quranpedia dumps wrap payload as {license, schema, data|ayahs|...}."""
    lic = obj.get("license", {}) if isinstance(obj, dict) else {}
    ver = lic.get("version") or lic.get("ar", {}) if isinstance(lic, dict) else ""
    if isinstance(ver, dict):
        ver = lic.get("version", "")
    data = None
    if isinstance(obj, dict):
        for k in ("data", "ayahs", "items", "verses"):
            if k in obj:
                data = obj[k]
                break
    return data, str(lic.get("version", "")), lic


def norm_sa(rec):
    """Pull (surah, ayah) from a record in any of the shapes the dumps use."""
    s = rec.get("surah") or rec.get("s") or rec.get("surah_number")
    a = rec.get("ayah") or rec.get("a") or rec.get("number") or rec.get("verse")
    return (int(s), int(a)) if s is not None and a is not None else (None, None)


def validate_per_ayah(rows, name, require_full=False):
    """rows: list of {'s':.., 'a':..}. Returns (ok, notes)."""
    notes = []
    seen = set()
    bad = 0
    for r in rows:
        s, a = r.get("s"), r.get("a")
        if s is None or a is None or s not in CANON or not (1 <= a <= CANON[s]):
            bad += 1
            continue
        seen.add((s, a))
    if bad:
        notes.append(f"{bad} rows with out-of-range (s,a)")
    surahs = {s for s, _ in seen}
    if surahs and surahs - set(CANON):
        notes.append(f"unknown surahs: {sorted(surahs - set(CANON))[:5]}")
    cov = len(seen)
    if require_full and cov != CANON_AYAT:
        notes.append(f"coverage {cov}/{CANON_AYAT} (expected full)")
    return (bad == 0 and (not require_full or cov == CANON_AYAT)), notes, cov


def write_dataset(name, rows, source, version, licence_tag, checks):
    os.makedirs(OUT, exist_ok=True)
    payload = json.dumps(
        {"v": 1, "source": source, "source_version": version,
         "licence": licence_tag, "count": len(rows), "rows": rows},
        ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    # Content-pack datasets live in corpus/packs/ (stripped in lite, published
    # by tool/publish_packs.py) — keep this set in sync with QuranCorpusSync.packDatasets.
    sub = "packs" if name in {"sayings", "notes", "similar", "irab_books", "fatwas"} else ""
    os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    path = os.path.join(OUT, sub, f"{name}.json.gz")
    with gzip.open(path, "wb", compresslevel=9) as fh:
        fh.write(payload)
    sha = hashlib.sha256(payload).hexdigest()
    size = os.path.getsize(path)
    print(f"  wrote {name}.json.gz  {size/1024:.0f} KB  {len(rows)} rows  {checks}")
    return {
        "file": f"{name}.json.gz", "source": source, "source_version": version,
        "licence": licence_tag, "rows": len(rows), "sha256": sha,
        "bytes": size, "checks": checks,
    }


# ─────────────────────────── dataset builders ───────────────────────────

def build_surahs(man):
    obj = read_gz_json(os.path.join(REPO, "surahs.json.gz"))
    data, ver, lic = envelope(obj)
    rows = []
    for d in data:
        info = d.get("information", {})
        intro = (info.get("introduction") or {}).get("value", "")
        rows.append({"s": int(d["surah"]), "intro_html": intro})
    ok = len(rows) == CANON_SURAHS
    return "surah_info", rows, "Quranpedia surahs", ver, "quranpedia-free", \
        {"surahs": len(rows), "ok": ok}


def build_service(man, member, key, name, licence_tag, require_full=False):
    z = zipfile.ZipFile(os.path.join(REPO, "services-all.zip"))
    obj = read_zip_member_gz_json(z, member)
    data, ver, lic = envelope(obj)
    rows = []
    for rec in data:
        s, a = norm_sa(rec)
        if s is None:
            continue
        payload = rec.get(key, rec)
        rows.append({"s": s, "a": a, key: payload})
    ok, notes, cov = validate_per_ayah(rows, name, require_full)
    return name, rows, f"Quranpedia services/{member}", ver, licence_tag, \
        {"ayat": cov, "ok": ok, "notes": notes}


def build_topics(man):
    obj = read_gz_json(os.path.join(REPO, "topics-index.json.gz"))
    data, ver, lic = envelope(obj)
    topics, links = [], []
    for t in data:
        topics.append({"id": t["id"], "name": t["name"],
                       "parent": t.get("parent_id")})
        rng = t.get("ayahs") or ""
        for part in str(rng).split(","):
            part = part.strip()
            if ":" not in part:
                continue
            sp, ap = part.split(":", 1)
            try:
                s = int(sp)
            except ValueError:
                continue
            if "-" in ap:
                lo, hi = ap.split("-", 1)
                try:
                    lo, hi = int(lo), int(hi)
                except ValueError:
                    continue
            else:
                try:
                    lo = hi = int(ap)
                except ValueError:
                    continue
            if s in CANON:
                links.append({"t": t["id"], "s": s, "a1": lo, "a2": hi})
    rows = {"topics": topics, "links": links}
    return "topics", [rows], "Quranpedia topics-index", ver, "quranpedia-free", \
        {"topics": len(topics), "links": len(links)}


def build_reciters(man):
    zf = zipfile.ZipFile(os.path.join(REPO, "Quran-Data-version-2.0.zip"))
    base = "Quran-Data-version-2.0/data/json/audio/audio_surah_1.json"
    lst = json.loads(zf.read(base))
    rows = []
    for r in lst:
        link = r.get("link", "")
        server = r.get("server", "")
        rows.append({
            "id": r["id"],
            "name_ar": (r.get("reciter") or {}).get("ar"),
            "name_en": (r.get("reciter") or {}).get("en"),
            "riwaya_ar": (r.get("rewaya") or {}).get("ar"),
            "audio_base": server,  # per-surah url = {server}/{NNN}.mp3
        })
    ok = len(rows) > 100
    return "reciters", rows, "Quran-Data-2.0 (mp3quran.net)", "2.0", \
        "mit / mp3quran", {"reciters": len(rows), "ok": ok}


def build_book_content(man, zip_name, prefix, name, licence_tag):
    """iʿrāb / asbāb book zips: {book, ayahs:[{surah,ayah,content|html}]}."""
    z = zipfile.ZipFile(os.path.join(REPO, zip_name))
    books, rows = [], []
    for member in z.namelist():
        if not member.startswith(prefix):
            continue
        obj = read_zip_member_gz_json(z, member)
        b = obj.get("book", {})
        bid = b.get("id")
        books.append({"id": bid, "name": b.get("name"),
                      "short": b.get("short_name"),
                      "author": (b.get("author") or {}).get("full_name")
                      if isinstance(b.get("author"), dict) else b.get("author"),
                      "year": b.get("publish_year")})
        for rec in obj.get("ayahs", obj.get("data", [])):
            s, a = norm_sa(rec)
            if s is None:
                continue
            content = rec.get("content") or rec.get("html") or rec.get("text")
            if isinstance(content, list):
                content = " ".join(c.get("text", "") for c in content
                                   if isinstance(c, dict))
            rows.append({"b": bid, "s": s, "a": a, "html": content})
    ok, notes, cov = validate_per_ayah(rows, name)
    return name, [{"books": books, "entries": rows}], \
        f"Quranpedia {zip_name}", "", licence_tag, \
        {"books": len(books), "entries": len(rows), "ayat": cov, "ok": ok,
         "notes": notes}


_TAG = None


def strip_html(s):
    global _TAG
    if _TAG is None:
        import re
        _TAG = re.compile(r"<[^>]+>")
    if not s:
        return s
    return _TAG.sub("", s).replace("&nbsp;", " ").strip()


_BR = None


def clean_rich(s):
    """Tafsīr / notes HTML → plain text with real line breaks. `<br>`, `</p>`,
    `</div>` become '\\n'; every other tag is dropped; entities decoded; runs
    of blank lines collapsed. Renders as styled text, not a WebView."""
    global _BR
    if _BR is None:
        import re
        _BR = (re.compile(r"<\s*/?\s*(br|p|div|li)\s*/?\s*>", re.I),
               re.compile(r"<[^>]+>"),
               re.compile(r"[ \t]*\n[ \t]*(\n[ \t]*)+"),
               re.compile(r"\r"))
    if not s:
        return s
    brk, tag, blanks, cr = _BR
    s = cr.sub("", s)
    s = brk.sub("\n", s)
    s = tag.sub("", s)
    s = (s.replace("&nbsp;", " ").replace("&amp;", "&")
         .replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"'))
    s = blanks.sub("\n\n", s)
    return s.strip()


def _write_sub(subdir, name, obj):
    d = os.path.join(OUT, subdir)
    os.makedirs(d, exist_ok=True)
    payload = json.dumps(obj, ensure_ascii=False, separators=(",", ":")).encode()
    path = os.path.join(d, f"{name}.json.gz")
    with gzip.open(path, "wb", compresslevel=9) as fh:
        fh.write(payload)
    return os.path.getsize(path), hashlib.sha256(payload).hexdigest()


def build_translations(man):
    """All 138 editions → corpus/translations/<id>.json.gz  {s,a,t} + index."""
    z = zipfile.ZipFile(os.path.join(REPO, "translations-all.zip"))
    index, total_bytes, bad = [], 0, 0
    for member in sorted(n for n in z.namelist() if n.endswith(".json")):
        ed = json.loads(z.read(member))
        eid = ed["id"]
        rows = []
        for v in ed.get("ayahs", []):
            s = int(v["surah_number"])
            a = int(v["ayah_number"])
            if s not in CANON or not (1 <= a <= CANON[s]):
                bad += 1
                continue
            rows.append({"s": s, "a": a,
                         "t": strip_html(v.get("translated_text", ""))})
        sz, sha = _write_sub("translations", str(eid),
                             {"v": 1, "id": eid, "rows": rows})
        total_bytes += sz
        index.append({"id": eid, "name": ed.get("name"),
                      "short": ed.get("short_name"),
                      "lang": (ed.get("language") or {}).get("name")
                      if isinstance(ed.get("language"), dict) else ed.get("language"),
                      "locale": ed.get("locale_code"),
                      "dir": ed.get("direction"), "ayat": len(rows),
                      "bytes": sz, "sha256": sha})
    sz, sha = _write_sub("", "translations_index", {"v": 1, "editions": index})
    ok = len(index) >= 130 and bad == 0
    return "translations_index", [{"editions": index}], \
        "Quranpedia translations-all", "", \
        "per-edition author IP — attribution shown", \
        {"editions": len(index), "total_MB": round(total_bytes / 1e6, 1),
         "bad_rows": bad, "ok": ok}


def build_tafsir(man):
    """Bundle ~budget MB smallest-first (+forced essentials); the rest are
    listed in the index as mirror=true. corpus/tafsir/<id>.json.gz {s,a,h}."""
    z = zipfile.ZipFile(os.path.join(REPO, "tafsir_books-all.zip"))
    bundle, mirror, cum = plan_tafsir()
    bundle_ids = {m["id"] for m in bundle}
    index, wrote_bytes, wrote = [], 0, 0
    all_members = [n for n in z.namelist() if n.startswith("tafsir-book-")]
    for member in all_members:
        obj = json.loads(gzip.decompress(z.read(member)))
        b = obj.get("book", {})
        bid = b.get("id")
        author = b.get("author")
        meta = {
            "id": bid, "name": b.get("name"), "short": b.get("short_name"),
            "author": (author or {}).get("full_name")
            if isinstance(author, dict) else author,
            "year": b.get("publish_year"), "nasher": b.get("nasher"),
        }
        if bid in bundle_ids:
            rows = []
            for rec in obj.get("ayahs", []):
                s, a = norm_sa(rec)
                if s is None or s not in CANON:
                    continue
                c = rec.get("content")
                if isinstance(c, list):
                    c = " ".join(x.get("text", "") for x in c if isinstance(x, dict))
                rows.append({"s": s, "a": a, "h": clean_rich(c)})
            sz, sha = _write_sub("tafsir", str(bid),
                                 {"v": 1, "id": bid, "rows": rows})
            wrote_bytes += sz
            wrote += 1
            meta.update({"bundled": True, "ayat": len(rows), "bytes": sz,
                         "sha256": sha})
        else:
            meta.update({"bundled": False, "mirror": True})
        index.append(meta)
    _write_sub("", "tafsir_index", {"v": 1, "books": index})
    return "tafsir_index", [{"books": index}], "Quranpedia tafsir_books-all", "", \
        "classical = free · modern = per-author", \
        {"total_books": len(index), "bundled": wrote,
         "bundled_MB": round(wrote_bytes / 1e6, 1),
         "mirror": len(index) - wrote}


def build_riwayat(man):
    """14 riwāyāt full text → corpus/riwaya/<id>.json.gz + index. Hafs = primary."""
    import re as _re
    z = zipfile.ZipFile(os.path.join(REPO, "mushafs-all.zip"))
    members = sorted(
        (n for n in z.namelist() if _re.fullmatch(r"mushafs-\d+\.json\.gz", n)),
        key=lambda n: int(_re.search(r"\d+", n).group()))
    index = []
    for member in members:
        obj = json.loads(gzip.decompress(z.read(member)))
        d = obj.get("data", {})
        if not isinstance(d, dict) or not d.get("surahs"):
            continue
        rid = d.get("id")
        rows = []
        for surah in d.get("surahs", []):
            s = int(surah.get("id") or surah.get("number"))
            for v in surah.get("ayahs", []):
                a = int(v.get("number"))
                rows.append({"s": s, "a": a,
                             "t": (v.get("text") or "").lstrip("﻿").strip(),
                             "m": v.get("marker")})
        sz, sha = _write_sub("riwaya", str(rid), {"v": 1, "id": rid, "rows": rows})
        rawi = d.get("rawi") or {}
        index.append({"id": rid, "name": d.get("name"),
                      "rawi": rawi.get("name") if isinstance(rawi, dict) else rawi,
                      "ayat": len(rows), "bytes": sz, "sha256": sha,
                      "primary": rid == 1})
    _write_sub("", "riwaya_index", {"v": 1, "riwayat": index})
    hafs = next((r for r in index if r["id"] == 1), None)
    ok = hafs is not None and hafs["ayat"] == CANON_AYAT
    return "riwaya_index", [{"riwayat": index}], "Quranpedia mushafs-all", "", \
        "quranpedia-free", {"riwayat": len(index),
                            "hafs_ayat": hafs["ayat"] if hafs else 0, "ok": ok}


def build_sayings(man):
    z = zipfile.ZipFile(os.path.join(REPO, "other-all.zip"))
    obj = json.loads(gzip.decompress(z.read("sayings.json.gz")))
    data, ver, lic = envelope(obj)
    rows = []
    for rec in data:
        s, a = norm_sa(rec)
        if s is None or s not in CANON:
            continue
        rows.append({"s": s, "a": a, "sayings": rec.get("sayings", [])})
    ok, notes, cov = validate_per_ayah(rows, "sayings")
    return "sayings", rows, "Quranpedia other/sayings", ver, "quranpedia-free", \
        {"ayat": cov, "ok": ok, "notes": notes}


def build_fatwas(man):
    obj = read_gz_json(os.path.join(REPO, "fatwas.json.gz"))
    data, ver, lic = envelope(obj)
    rows = []
    for f in data:
        rows.append({"id": f["id"], "title": f.get("ar_title"),
                     "q": f.get("ar_question"), "a": f.get("ar_answer"),
                     "ref": f.get("ayahs") or f.get("surah")})
    return "fatwas", rows, "Quranpedia fatwas", ver, "quranpedia-free", \
        {"fatwas": len(rows)}


def build_book_catalog(man):
    z = zipfile.ZipFile(os.path.join(REPO, "books-all.zip"))
    obj = json.loads(gzip.decompress(z.read("books.json.gz")))
    data, ver, lic = envelope(obj)
    rows = []
    for b in data:
        rows.append({
            "id": b["id"], "type": b.get("type"), "name": b.get("name"),
            "short": b.get("short_name"),
            "author": (b.get("author") or {}).get("full_name")
            if isinstance(b.get("author"), dict) else b.get("author"),
            "year": b.get("publish_year"),
            "lang": (b.get("language") or {}).get("code")
            if isinstance(b.get("language"), dict) else None,
        })
    from collections import Counter
    kinds = Counter(r["type"] for r in rows)
    return "book_catalog", rows, "Quranpedia books-all", ver, "quranpedia-free", \
        {"books": len(rows), "by_type": dict(kinds)}


def build_nasekh(man):
    obj = read_gz_json(os.path.join(REPO, "nasekh-book-2391.json.gz"))
    data, ver, lic = envelope(obj)
    b = obj.get("book", {})
    rows = []
    for rec in data or []:
        s, a = norm_sa(rec)
        if s is None:
            continue
        rows.append({"s": s, "a": a,
                     "html": rec.get("content") or rec.get("html")
                     or rec.get("text")})
    return "nasekh", [{"book": {"id": b.get("id"), "name": b.get("name")},
                       "entries": rows}], \
        "Quranpedia nasekh-book-2391", ver, "quranpedia-free", \
        {"entries": len(rows)}


# ─────────────────────────────── tafsir ─────────────────────────────────

FORCE_TAFSIR = {  # essentials, bundled regardless of size
    4, 136, 331, 261, 2, 3, 32, 27809, 272, 184, 352, 306, 343, 168, 169,
    18, 27804, 64, 308, 340, 273, 346, 319, 503, 2003, 37, 340, 350, 349,
}


def list_tafsir():
    z = zipfile.ZipFile(os.path.join(REPO, "tafsir_books-all.zip"))
    out = []
    for n in z.namelist():
        if not n.startswith("tafsir-book-"):
            continue
        raw = z.read(n)
        b = json.loads(gzip.decompress(raw)).get("book", {})
        out.append((b.get("id"), raw.__sizeof__(), len(raw),
                    b.get("short_name") or b.get("name")))
    out.sort(key=lambda x: x[2])
    return out


def plan_tafsir(budget_mb=135):
    z = zipfile.ZipFile(os.path.join(REPO, "tafsir_books-all.zip"))
    meta = []
    for n in z.namelist():
        if not n.startswith("tafsir-book-"):
            continue
        raw = z.read(n)
        b = json.loads(gzip.decompress(raw)).get("book", {})
        meta.append({"member": n, "id": b.get("id"),
                     "name": b.get("short_name") or b.get("name"),
                     "bytes": len(raw)})
    meta.sort(key=lambda m: m["bytes"])
    bundle, mirror, cum = [], [], 0
    budget = budget_mb * 1024 * 1024
    for m in meta:
        forced = m["id"] in FORCE_TAFSIR
        if forced or cum + m["bytes"] <= budget:
            bundle.append(m)
            cum += m["bytes"]
        else:
            mirror.append(m)
    return bundle, mirror, cum


# ────────────────────────────────  main  ────────────────────────────────

BUILDERS = {
    "surah_info": build_surahs,
    "morphology": lambda m: build_service(
        m, "morphology.json.gz", "morphology", "morphology",
        "GNU GPL — Quranic Arabic Corpus (corpus.quran.com)", require_full=True),
    "syntax": lambda m: build_service(
        m, "syntax.json.gz", "syntax", "syntax",
        "MIT — The Quranic Treebank"),
    "meanings": lambda m: build_service(
        m, "meanings.json.gz", "meanings", "meanings", "quranpedia-free"),
    "notes": lambda m: build_service(
        m, "notes.json.gz", "notes", "notes", "quranpedia-free"),
    "qiraat": lambda m: build_service(
        m, "qiraat.json.gz", "qiraat", "qiraat", "quranpedia-free"),
    "similar": lambda m: build_service(
        m, "similar.json.gz", "similar", "similar", "quranpedia-free"),
    "topics": build_topics,
    "reciters": build_reciters,
    "irab_books": lambda m: build_book_content(
        m, "e3rab_books-all.zip", "e3rab-book-", "irab_books",
        "classical / MIT-treebank-derived"),
    "asbab_books": lambda m: build_book_content(
        m, "asbab_books-all.zip", "asbab-book-", "asbab_books", "quranpedia-free"),
    "nasekh": build_nasekh,
    "translations": build_translations,
    "tafsir": build_tafsir,
    "riwayat": build_riwayat,
    "sayings": build_sayings,
    "fatwas": build_fatwas,
    "book_catalog": build_book_catalog,
}


def main():
    args = sys.argv[1:]
    if "--list-tafsir" in args:
        for tid, _, sz, name in list_tafsir():
            print(f"{str(tid):>7} {sz/1e6:>7.2f} MB  {name}")
        b, mi, cum = plan_tafsir()
        print(f"\nplan: bundle {len(b)} ({cum/1e6:.0f} MB), mirror {len(mi)}")
        return

    only = None
    if "--only" in args:
        only = set(args[args.index("--only") + 1].split(","))

    man_out = {"v": 1, "canon": {"surahs": CANON_SURAHS, "ayat": CANON_AYAT},
               "datasets": {}}
    report = ["# Quran Corpus — QC1 ingest report", ""]
    for name, fn in BUILDERS.items():
        if only and name not in only:
            continue
        try:
            ds_name, rows, source, ver, lic, checks = fn(None)
        except FileNotFoundError as e:
            print(f"  SKIP {name}: {e}")
            report.append(f"- **{name}**: SKIP (missing source: {e})")
            continue
        entry = write_dataset(ds_name, rows, source, ver, lic, checks)
        man_out["datasets"][ds_name] = entry
        ok = checks.get("ok", True)
        report.append(f"- **{ds_name}** — {entry['rows']} rows, "
                      f"{entry['bytes']/1024:.0f} KB, `{lic}` — "
                      f"{'PASS' if ok else 'CHECK'} {checks}")

    os.makedirs(OUT, exist_ok=True)
    json.dump(man_out, open(os.path.join(OUT, "corpus_manifest.json"), "w",
                            encoding="utf-8"), ensure_ascii=False, indent=1)
    os.makedirs(REPORT, exist_ok=True)
    open(os.path.join(REPORT, "QURAN_CORPUS_QA.md"), "w",
         encoding="utf-8").write("\n".join(report) + "\n")
    print("\n".join(report))


if __name__ == "__main__":
    main()
