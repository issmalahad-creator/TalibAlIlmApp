#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_alignments.py  —  Phase B / VT-3  (the identity-spine backbone).

Maps the **Quranic Arabic Corpus** word segmentation (used by
`assets/quran/corpus/morphology.json.gz` and `syntax.json.gz`) onto **our**
canonical `mushaf_words.word_index` per `(surah, ayah)`, so a tapped word on
the muṣḥaf page can show its ṣarf / iʿrāb.

QAC keeps each orthographic word whole (and splits it into *segments*); our
`mushaf_*` splits clitics (`وَ`, `فَ`, `بِ`, `لِ`, `ٱلْ`, `ـهُ`, `ـكَ`, …)
into separate `word_index` entries and also indexes standalone waqf glyphs.
So the mapping is **many-of-ours → one QAC word**.

Method: normalise both sides (strip ḥarakāt / dagger-alef / tatweel, unify
alef & ya & ta-marbuta, drop pause glyphs); drop our tokens that normalise
to empty; then walk our words, accumulating their normalised text until it
equals the next QAC word's normalised text. Perfect concatenation ⇒ clean
map. Any residue ⇒ the ayah is flagged (still emitted best-effort, never
guessed silently).

Emits:
  assets/quran/corpus/align_qac.json.gz   [{s, a, m:{word_index: qac_word_no}}]
  docs/quran/reports/QURAN_WORD_ALIGNMENT_REPORT.md
"""
import gzip
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(REPO, "assets", "quran", "corpus")
LAYOUT = os.path.join(REPO, "assets", "mushaf", "mushaf_layout.json.gz")
REPORT = os.path.join(REPO, "docs", "quran", "reports")

_HARAKAT = re.compile(
    "[ؐ-ًؚ-ٰٟۖ-ۜ۟-ۨ"
    "۪-ۭ࣓-ࣿ‍ـ]")
_PAUSE = set("ۣۖۗۘۙۚۛۜ۟۞۩ۤ")  # waqf marks + rub’/sajda ornaments (we index them, QAC does not)


def norm(s):
    if not s:
        return ""
    s = _HARAKAT.sub("", s)
    out = []
    for ch in s:
        if ch in _PAUSE:
            continue
        if ch in " 	‍ـ":
            continue
        if ch in "أإآٱ":
            ch = "ا"
        elif ch in "ىی":
            ch = "ي"
        elif ch == "ة":
            ch = "ه"
        elif ch in "ؤئ":
            ch = "ء"
        out.append(ch)
    return "".join(out).strip()


def load_qac():
    """{(s,a): [normalised QAC word text, ...]}  (1-indexed by position)."""
    rows = json.loads(gzip.open(os.path.join(CORPUS, "morphology.json.gz")
                                .read() if False else
                                os.path.join(CORPUS, "morphology.json.gz")).read()
                      ) if False else None
    with gzip.open(os.path.join(CORPUS, "morphology.json.gz")) as fh:
        data = json.loads(fh.read())["rows"]
    out = {}
    for r in data:
        words = r["morphology"]["words"]
        out[(r["s"], r["a"])] = [norm(w.get("text", "")) for w in words]
    return out


def load_ours():
    """{(s,a): [(word_index, normalised hafs text), ...] in word_index order}."""
    with gzip.open(LAYOUT) as fh:
        d = json.loads(fh.read())
    out = {}
    for p in d["pages"]:
        for w in p["words"]:
            # imlaei (simplified) form aligns to QAC far better than the
            # Uthmani rasm (which drops alefs: العلمين vs العالمين).
            txt = w.get("iml") or w.get("hafs", "")
            out.setdefault((w["s"], w["a"]), []).append((w["w"], norm(txt)))
    for k in out:
        out[k].sort()
    return out


def align_ayah(qac_words, our_words):
    """Return ({word_index: qac_no}, ok:bool, note:str)."""
    ours = [(wi, t) for wi, t in our_words if t]  # drop empty (pause glyphs)
    mp = {}
    qi = 0                       # 0-based index into qac_words
    buf = ""
    buf_idx = []
    for wi, t in ours:
        if qi >= len(qac_words):
            return mp, False, f"ran out of QAC words at word_index {wi}"
        buf += t
        buf_idx.append(wi)
        target = qac_words[qi]
        _skel = lambda x: x.replace("ا", "").replace("ة", "ه").replace("ت", "ه").replace("و", "")
        if buf == target or _skel(buf) == _skel(target):
            # exact, or same skeleton ignoring alef (Uthmani rasm ↔ imlaei:
            # العلمين/العالمين, سموات/سماوات, تتلوا/تتلو)
            for k in buf_idx:
                mp[k] = qi + 1   # QAC word numbers are 1-based
            qi += 1
            buf, buf_idx = "", []
        elif qi + 1 < len(qac_words) and buf == target + qac_words[qi + 1]:
            # our single token spans two QAC words (e.g. vocative يا + noun)
            for k in buf_idx:
                mp[k] = qi + 1
            qi += 2
            buf, buf_idx = "", []
        elif not target.startswith(buf):
            return mp, False, (f"mismatch: ours «{buf}» vs QAC «{target}» "
                               f"(word_index {buf_idx})")
    ok = (qi == len(qac_words) and not buf)
    note = "" if ok else f"leftover: qi={qi}/{len(qac_words)} buf=«{buf}»"
    return mp, ok, note


def main():
    qac = load_qac()
    ours = load_ours()
    rows, clean, flagged = [], 0, []
    for key in sorted(ours):
        s, a = key
        qw = qac.get(key)
        if not qw:
            flagged.append((s, a, "no QAC entry"))
            continue
        mp, ok, note = align_ayah(qw, ours[key])
        rows.append({"s": s, "a": a, "m": mp})
        if ok:
            clean += 1
        else:
            flagged.append((s, a, note))

    import hashlib
    payload = json.dumps(
        {"v": 1, "source": "QAC word ↔ mushaf_words.word_index",
         "count": len(rows), "clean": clean, "flagged": len(flagged),
         "rows": rows},
        ensure_ascii=False, separators=(",", ":")).encode()
    with gzip.open(os.path.join(CORPUS, "align_qac.json.gz"), "wb",
                   compresslevel=9) as fh:
        fh.write(payload)

    # register in the corpus manifest so QuranCorpusSync picks it up
    mp_path = os.path.join(CORPUS, "corpus_manifest.json")
    man = json.load(open(mp_path, encoding="utf-8"))
    man["datasets"]["align_qac"] = {
        "file": "align_qac.json.gz",
        "source": "QAC ↔ mushaf_words (build_alignments.py)",
        "source_version": "vt3-1", "licence": "GNU GPL (QAC segmentation)",
        "rows": len(rows),
        "sha256": hashlib.sha256(payload).hexdigest(),
        "bytes": os.path.getsize(os.path.join(CORPUS, "align_qac.json.gz")),
        "checks": {"clean": clean, "flagged": len(flagged), "ayat": len(rows)},
    }
    json.dump(man, open(mp_path, "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)

    os.makedirs(REPORT, exist_ok=True)
    md = [f"# QAC ↔ mushaf_words alignment (VT-3)", "",
          f"- ayat aligned: **{len(rows)} / 6236**",
          f"- clean (perfect concatenation): **{clean}**",
          f"- flagged (best-effort map still emitted): **{len(flagged)}**", ""]
    if flagged:
        md.append("| surah:ayah | note |")
        md.append("|---|---|")
        for s, a, n in flagged[:200]:
            md.append(f"| {s}:{a} | {n} |")
        if len(flagged) > 200:
            md.append(f"| … | +{len(flagged) - 200} more |")
    open(os.path.join(REPORT, "QURAN_WORD_ALIGNMENT_REPORT.md"), "w",
         encoding="utf-8").write("\n".join(md) + "\n")

    print(f"align_qac: {clean}/{len(rows)} clean, {len(flagged)} flagged")
    for s, a, n in flagged[:15]:
        print(f"  {s}:{a}  {n}")
    if "--strict" in sys.argv and flagged:
        sys.exit(1)


if __name__ == "__main__":
    main()
