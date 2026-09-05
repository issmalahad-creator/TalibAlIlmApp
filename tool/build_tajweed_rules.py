#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_tajweed_rules.py  —  Phase G-t1 · tajwīd rule spans for all 6236 ayāt,
keyed by the canonical Hafs spine (surah, ayah, word_index) + a half-open
char range [cs, ce) inside that word's own Uthmani text.

INPUT  (fetch with tool/fetch_tajweed_source.sh — gitignored /tool/vendor/):
  tool/vendor/quran-tajweed/tajweed.hafs.uthmani-pause-sajdah.json
      cpfair/quran-tajweed — [{surah, ayah, annotations:[{rule,start,end}]}]
      start/end are half-open Unicode-codepoint offsets into ↓
  tool/vendor/quran-tajweed/quran-uthmani.txt
      the exact 2017 Tanzil Uthmani "S|A|text" file those offsets index.
      The first ayah of every surah except 1 and 9 has the Basmala prepended.
  assets/mushaf/mushaf_layout.json.gz
      our canonical per-word text (`hafs`) + `word_index` (`w`).

OUTPUT:
  assets/quran/corpus/tajweed.json.gz
      {v, source, licence, count, rows:[{s,a,spans:[{w,cs,ce,r}]}]}
  docs/quran/reports/TAJWEED_ALIGNMENT_REPORT.md
  corpus_manifest.json  ← datasets.tajweed registered (QuranCorpusSync picks it up)

METHOD (no space-counting — real normalised alignment, best-effort, flag residue):
  Stage A  our clitic-split words  →  cpfair whole words   (per ayah)
  Stage B  cpfair char offsets     →  our per-word [cs,ce)  (letter-group align)
  A word-group that will not align cleanly is SKIPPED and listed in the report —
  never guessed. "Worse is visible, not silent."

  py tool/build_tajweed_rules.py            # build + report
  py tool/build_tajweed_rules.py --strict   # exit 1 if any ayah is flagged
"""
import gzip
import hashlib
import json
import os
import sys
import unicodedata
import difflib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_alignments import norm as _norm0  # noqa: E402


def norm(s):
    """build_alignments.norm + also drop the bare hamza ء (U+0621): cpfair's
    2017 Tanzil rasm spells e.g. ٱلْءَاخِرَة with an explicit hamza letter that
    our data-hafs writes as an alef-madda — both must skeleton-match."""
    return _norm0(s).replace("ء", "")

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VENDOR = os.path.join(REPO, "tool", "vendor", "quran-tajweed")
RULES_JSON = os.path.join(VENDOR, "tajweed.hafs.uthmani-pause-sajdah.json")
BASE_TXT = os.path.join(VENDOR, "quran-uthmani.txt")
LAYOUT = os.path.join(REPO, "assets", "mushaf", "mushaf_layout.json.gz")
CORPUS = os.path.join(REPO, "assets", "quran", "corpus")
OUT = os.path.join(CORPUS, "tajweed.json.gz")
MANIFEST = os.path.join(CORPUS, "corpus_manifest.json")
REPORT = os.path.join(REPO, "docs", "quran", "reports", "TAJWEED_ALIGNMENT_REPORT.md")

CPFAIR_SHA = "496f71cd191da00fa2a37ded79dbbddb033bb0ad"
LICENCE = "CC BY 4.0 — quran-tajweed (Chris Pearce / cpfair)"

# The 18 rule ids cpfair emits. Anything outside this set is a corruption.
KNOWN_RULES = {
    "hamzat_wasl", "lam_shamsiyyah", "madd_2", "madd_246", "madd_6",
    "madd_muttasil", "madd_munfasil", "ghunnah", "qalqalah", "ikhfa", "iqlab",
    "idghaam_ghunnah", "idghaam_no_ghunnah", "idghaam_shafawi", "ikhfa_shafawi",
    "idghaam_mutajanisayn", "idghaam_mutaqaribayn", "silent",
}

BASMALA = "بسم الله الرحمن الرحيم"
DAGGER_ALEF = "ٰ"


# ─────────────────────────── text helpers ───────────────────────────

def _is_base(ch):
    """cpfair's own letter model: a base char is anything not `Mn`, plus the
    dagger alef (which it counts as a base char)."""
    return ch == DAGGER_ALEF or unicodedata.category(ch) != "Mn"


def letters(s):
    """[(lo, hi)] — one slice per 'letter' = base char + following combining marks."""
    out = []
    i = 0
    n = len(s)
    while i < n:
        if not _is_base(s[i]):
            # leading combining mark with no base (shouldn't happen mid-word) —
            # attach to the previous letter, or start a degenerate one.
            if out:
                lo, _ = out[-1]
                out[-1] = (lo, i + 1)
                i += 1
                continue
        j = i + 1
        while j < n and unicodedata.category(s[j]) == "Mn" and s[j] != DAGGER_ALEF:
            j += 1
        out.append((i, j))
        i = j
    return out


def base_skeleton(s, slices):
    """Normalised base char per letter slice — for aligning two Uthmani forms
    of the same word. Uses build_alignments.norm on the base char so the
    alef/ya/ta-marbuta/hamza-seat unification stays identical across the repo."""
    sk = []
    for lo, hi in slices:
        b = s[lo]
        if b == DAGGER_ALEF:
            sk.append("ا")
            continue
        nb = norm(b)
        # placeholder that can never equal a real normalised letter, so
        # the letter count stays aligned between the two skeletons
        sk.append(nb if nb else chr(0xFFFD))
    return sk


# ─────────────────────────── inputs ───────────────────────────

def load_base():
    """{(s,a): text}  — the cpfair base text, 3rd '|' field, verbatim."""
    raw = open(BASE_TXT, "rb").read().decode("utf-8-sig")
    out = {}
    for line in raw.splitlines():
        parts = line.split("|", 2)
        if len(parts) != 3 or not parts[0].isdigit():
            continue
        out[(int(parts[0]), int(parts[1]))] = parts[2].strip()
    return out


def load_rules():
    """{(s,a): [ann, ...]}  from cpfair output."""
    data = json.load(open(RULES_JSON, encoding="utf-8"))
    out = {}
    for e in data:
        out[(e["surah"], e["ayah"])] = e["annotations"]
    return out


def load_ours():
    """{(s,a): [(w, hafs), ...] in word order}  — pause-only tokens dropped."""
    with gzip.open(LAYOUT) as fh:
        d = json.loads(fh.read())
    out = {}
    raw_lens = {}
    for pg in d["pages"]:
        for w in pg["words"]:
            key = (w["s"], w["a"])
            hafs = w.get("hafs", "") or ""
            raw_lens.setdefault(key, {})[w["w"]] = len(hafs)
            if not norm(hafs):
                continue  # standalone waqf glyph / marker — never carries these rules
            out.setdefault(key, []).append((w["w"], hafs))
    for k in out:
        out[k].sort()
    return out, raw_lens


# ─────────────────────────── alignment ───────────────────────────

def _skel(x):
    return x.replace("ا", "").replace("ة", "ه").replace("ت", "ه").replace("و", "").replace("ي", "")


def word_map(ct_norm, ours_norm):
    """Stage A. ct_norm: [normalised cpfair word]. ours_norm: [(w, normalised hafs)].
    Returns (groups, ok, note) where groups = [(cp_lo, cp_hi, [w,...])] — cp_hi
    exclusive; a group usually spans one cpfair word, occasionally two."""
    groups = []
    ci = 0
    buf = ""
    buf_ws = []
    for w, t in ours_norm:
        if ci >= len(ct_norm):
            return groups, False, f"ran out of cpfair words at word {w}"
        buf += t
        buf_ws.append(w)
        tgt = ct_norm[ci]
        # _skel drops ا/و/ي/ة/ت — only trust it as a fallback when it leaves
        # something behind (else «وَ» and «وَإِيَّاىَ» both skel to "" → false match)
        sk_ok = bool(_skel(buf)) and _skel(buf) == _skel(tgt)
        if buf == tgt or sk_ok:
            groups.append((ci, ci + 1, buf_ws))
            ci += 1
            buf, buf_ws = "", []
        elif ci + 1 < len(ct_norm) and (
            buf == tgt + ct_norm[ci + 1]
            or (bool(_skel(buf)) and _skel(buf) == _skel(tgt + ct_norm[ci + 1]))
        ):
            groups.append((ci, ci + 2, buf_ws))
            ci += 2
            buf, buf_ws = "", []
        elif not tgt.startswith(buf) and not (
            _skel(buf) and _skel(tgt).startswith(_skel(buf))
        ):
            return groups, False, f"mismatch: ours «{buf}» vs cpfair «{tgt}» (words {buf_ws})"
    ok = (ci == len(ct_norm) and not buf)
    return groups, ok, "" if ok else f"leftover ci={ci}/{len(ct_norm)} buf=«{buf}»"


def char_map(tj, h):
    """Stage B core. Map every index in `tj` (a cpfair word) to an index in `h`
    (our concatenated raw hafs for the matched group) at letter-group
    granularity. Returns (map_lo, map_hi, clean) where map_lo[k]/map_hi[k] give
    the [lo,hi) in `h` for tj-letter k, or (None, None, False) if too divergent."""
    lt = letters(tj)
    lh = letters(h)
    st = base_skeleton(tj, lt)
    sh = base_skeleton(h, lh)

    pairs = []  # (tj_letter_idx -> h_letter_idx)
    if st == sh:
        pairs = [(k, k) for k in range(len(lt))]
    else:
        sm = difflib.SequenceMatcher(None, st, sh, autojunk=False)
        changed = 0
        for op, a0, a1, b0, b1 in sm.get_opcodes():
            if op == "equal":
                for d in range(a1 - a0):
                    pairs.append((a0 + d, b0 + d))
            else:
                changed += max(a1 - a0, b1 - b0)
                # collapse the whole changed block: every tj letter in [a0,a1)
                # maps onto the full h block [b0,b1)
                for k in range(a0, a1):
                    pairs.append((k, (b0, b1)))
        # too divergent → give up on this group (report it, don't guess)
        if changed > 2 and changed > 0.25 * max(len(st), 1):
            return None, None, False

    map_lo = [0] * len(lt)
    map_hi = [0] * len(lt)
    for k, hk in pairs:
        if isinstance(hk, tuple):
            b0, b1 = hk
            lo = lh[b0][0] if b0 < len(lh) else len(h)
            hi = lh[b1 - 1][1] if 0 < b1 <= len(lh) else len(h)
        else:
            lo, hi = (lh[hk] if hk < len(lh) else (len(h), len(h)))
        map_lo[k], map_hi[k] = lo, hi
    return (lt, map_lo, map_hi), None, True


def spans_for_ayah(s, a, T, anns, ours):
    """→ (spans, note). spans = [{w,cs,ce,r}] into each word's own raw hafs."""
    # ---- Basmala prefix on the first ayah of every surah except 1 & 9 ----
    ct = []  # (cstart, cend, text) per cpfair word
    i = 0
    for tok in T.split(" "):
        if tok == "":
            i += 1
            continue
        ct.append((i, i + len(tok), tok))
        i += len(tok) + 1

    shift = 0
    if a == 1 and s not in (1, 9) and len(ct) >= 4:
        head = "".join(t for _, _, t in ct[:4])
        if norm(head) == norm(BASMALA):
            shift = ct[4][0] if len(ct) > 4 else ct[3][1]
            ct = [(cs - shift, ce - shift, t) for cs, ce, t in ct[4:]]

    if not ct:
        return [], "no cpfair words after basmala trim"

    ours_norm = [(w, norm(h)) for w, h in ours]
    ct_norm = [norm(t) for _, _, t in ct]
    groups, ok, note = word_map(ct_norm, ours_norm)

    # index our raw hafs by w
    raw_by_w = {w: h for w, h in ours}

    out = []
    flagged_groups = 0
    for (cp_lo, cp_hi, ws) in groups:
        g0 = ct[cp_lo][0]
        g1 = ct[cp_hi - 1][1]
        # our concatenated raw text for this group + each word's slice in it
        H = ""
        wspans = []  # (w, h_lo, h_hi)
        for w in ws:
            h = raw_by_w[w]
            wspans.append((w, len(H), len(H) + len(h)))
            H += h
        Tj = T[g0 + shift:g1 + shift]

        res, _, ok2 = char_map(Tj, H)
        if not ok2 or res is None:
            flagged_groups += 1
            continue
        lt, map_lo, map_hi = res

        for ann in anns:
            r = ann["rule"]
            if r not in KNOWN_RULES:
                continue
            a_s = ann["start"] - shift
            a_e = ann["end"] - shift
            # overlap with this group's [g0,g1) ?
            os_ = max(a_s, g0) - g0
            oe_ = min(a_e, g1) - g0
            if oe_ <= os_:
                continue
            # letter indices in Tj covering [os_, oe_)
            k_start = next((k for k, (lo, hi) in enumerate(lt) if hi > os_), None)
            k_end = next((k for k in range(len(lt) - 1, -1, -1) if lt[k][0] < oe_), None)
            if k_start is None or k_end is None or k_end < k_start:
                continue
            hs = map_lo[k_start]
            he = map_hi[k_end]
            if he <= hs:
                continue
            for (w, h_lo, h_hi) in wspans:
                cs = max(hs, h_lo) - h_lo
                ce = min(he, h_hi) - h_lo
                if ce <= cs:
                    continue
                cs = max(0, cs)
                ce = min(ce, len(raw_by_w[w]))
                if ce <= cs:
                    continue
                out.append({"w": w, "cs": cs, "ce": ce, "r": r})

    # dedupe + order
    seen = set()
    uniq = []
    for sp in sorted(out, key=lambda x: (x["w"], x["cs"], x["ce"], x["r"])):
        key = (sp["w"], sp["cs"], sp["ce"], sp["r"])
        if key in seen:
            continue
        seen.add(key)
        uniq.append(sp)

    notes = []
    if not ok:
        notes.append(f"stage-A: {note}")
    if flagged_groups:
        notes.append(f"{flagged_groups} word-group(s) skipped (char-align divergence)")
    return uniq, "; ".join(notes)


# ─────────────────────────── main ───────────────────────────

def main():
    for p in (RULES_JSON, BASE_TXT):
        if not os.path.exists(p):
            sys.exit(f"missing {p} — run  sh tool/fetch_tajweed_source.sh  first")

    base = load_base()
    rules = load_rules()
    ours, raw_lens = load_ours()

    rows = []
    clean = 0
    flagged = []       # (s, a, note)
    partial = []       # (s, a, note)  — emitted spans but with a skipped group
    total_spans = 0
    rule_hist = {}

    for key in sorted(ours):
        s, a = key
        if key not in rules or key not in base:
            flagged.append((s, a, "no cpfair entry"))
            continue
        spans, note = spans_for_ayah(s, a, base[key], rules[key], ours[key])

        # validate every span against the real word length
        wl = raw_lens.get(key, {})
        bad = [sp for sp in spans
               if not (0 <= sp["cs"] < sp["ce"] <= wl.get(sp["w"], 0))]
        if bad:
            note = (note + "; " if note else "") + f"{len(bad)} span(s) out of word bounds — dropped"
            spans = [sp for sp in spans if sp not in bad]

        rows.append({"s": s, "a": a, "spans": spans})
        total_spans += len(spans)
        for sp in spans:
            rule_hist[sp["r"]] = rule_hist.get(sp["r"], 0) + 1

        if not note:
            clean += 1
        elif spans:
            partial.append((s, a, note))
        else:
            flagged.append((s, a, note))

    payload = json.dumps(
        {"v": 1,
         "source": f"cpfair/quran-tajweed @ {CPFAIR_SHA}",
         "source_version": "2017-04-06 base · cpfair 2021-10-12",
         "licence": LICENCE,
         "count": len(rows),
         "rows": rows},
        ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    os.makedirs(CORPUS, exist_ok=True)
    with gzip.open(OUT, "wb", compresslevel=9) as fh:
        fh.write(payload)
    sha = hashlib.sha256(payload).hexdigest()
    size = os.path.getsize(OUT)

    # ---- register in the corpus manifest (QuranCorpusSync reads this) ----
    if os.path.exists(MANIFEST):
        man = json.load(open(MANIFEST, encoding="utf-8"))
        man.setdefault("datasets", {})["tajweed"] = {
            "file": "tajweed.json.gz",
            "source": f"cpfair/quran-tajweed @ {CPFAIR_SHA} (build_tajweed_rules.py)",
            "source_version": "gt1-1",
            "licence": LICENCE,
            "rows": len(rows),
            "sha256": sha,
            "bytes": size,
            "checks": {"clean": clean, "partial": len(partial),
                       "flagged": len(flagged), "ayat": len(rows),
                       "spans": total_spans},
        }
        json.dump(man, open(MANIFEST, "w", encoding="utf-8"),
                  ensure_ascii=False, indent=1)

    # ---- alignment report ----
    md = [
        "# Tajwīd alignment report (Phase G-t1)", "",
        f"Source: **cpfair/quran-tajweed** @ `{CPFAIR_SHA}` — rule data licensed "
        f"**CC BY 4.0** (Chris Pearce). Offsets are into the pinned 2017 Tanzil "
        f"Uthmani base text; remapped here to our `(surah, ayah, word_index)` "
        f"spine + a `[cs, ce)` char range in each word's own Uthmani text.", "",
        f"- ayāt with a spans row: **{len(rows)} / 6236**",
        f"- clean (every word-group aligned): **{clean}**",
        f"- partial (spans emitted, ≥1 word-group skipped): **{len(partial)}**",
        f"- flagged (no spans emitted): **{len(flagged)}**",
        f"- total spans: **{total_spans}**", "",
        "## spans per rule", "",
        "| rule | spans |", "|---|---|",
    ]
    for r, c in sorted(rule_hist.items(), key=lambda kv: -kv[1]):
        md.append(f"| `{r}` | {c} |")
    for title, lst in (("partial", partial), ("flagged", flagged)):
        if not lst:
            continue
        md += ["", f"## {title} ({len(lst)})", "", "| surah:ayah | note |", "|---|---|"]
        for s, a, n in lst[:200]:
            md.append(f"| {s}:{a} | {n} |")
        if len(lst) > 200:
            md.append(f"| … | +{len(lst) - 200} more |")
    os.makedirs(os.path.dirname(REPORT), exist_ok=True)
    open(REPORT, "w", encoding="utf-8").write("\n".join(md) + "\n")

    print(f"tajweed.json.gz  {size/1024:.0f} KB  ·  {len(rows)} ayāt  ·  {total_spans} spans")
    print(f"  clean {clean} · partial {len(partial)} · flagged {len(flagged)}")
    print(f"  sha256 {sha}")
    for s, a, n in (partial + flagged)[:12]:
        print(f"    {s}:{a}  {n}")
    if "--strict" in sys.argv and (partial or flagged):
        sys.exit(1)


if __name__ == "__main__":
    main()
