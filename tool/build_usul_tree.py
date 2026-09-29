#!/usr/bin/env python3
"""U1 — build assets/quran_learning/usul_tree.json, the usul-tafsir tree.

docs/quran/USUL_TAFSIR_TREE.md §10: the backbone is Ibn Taymiyya's
«مقدمة في أصول التفسير» (public domain; turath.io book 12081). Every
definition is a VERBATIM quote located in the fetched text by its opening
words, cut at a sentence end, with the printed page — the build fails if a
quote isn't found, so nothing is paraphrased or recalled from memory.

    python tool/build_usul_tree.py            # uses tool/.cache/muqaddima (fetches if missing)

Merged into the knowledge seed by QuranLearningSync (concepts + sources +
relations), so it lives in the same tables as the rest of the engine.
"""
from __future__ import annotations

import json
import re
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "tool/.cache/muqaddima"
OUT = ROOT / "assets/quran_learning/usul_tree.json"
BOOK_ID = 12081
UA = "TalibAlIlm-build/1.0 (+https://github.com/issmalahad-creator/TalibAlIlmApp)"
VERSION = 1

SOURCE = {
    "id": "src:muqaddima_usul_tafsir",
    "source_type": "classical_text",
    "name": "مقدمة في أصول التفسير",
    "author": "شيخ الإسلام أحمد بن عبد الحليم ابن تيمية (ت 728هـ)",
    "edition": "turath.io #12081",
    "url": "https://app.turath.io/book/12081",
    "license": "public-domain",
    "license_use": "bundled_ok",
    "authority": "classical",
    "retrieved_at": time.strftime("%Y-%m-%d"),
    "confidence": 1.0,
    "classification": "VERIFIED",
    "notes": "Backbone of the usul-tafsir tree (USUL_TAFSIR_TREE.md §10). Quotes are verbatim, located by tool/build_usul_tree.py.",
}

# (id, parent, rel, title, question, quote-opening, answer-key, mode)
#   mode: sourced — answered per ayah from shipped data (U2);
#         curated — only from reviewed book examples (U5), never auto-classified.
NODES = [
    ("usul", None, None, "أصول التفسير", "كيف نفهم هذه الآية على طريقة السلف؟", None, None, "root"),
    ("bayan", "usul", "أقسامه", "بيان النبي ﷺ لمعاني القرآن",
     "هل ورد في الآية بيان من النبي ﷺ؟", "يجب أن يعلم أن النبي ﷺ", "bayan_nabawi", "sourced"),
    ("ikhtilaf", "usul", "أقسامه", "اختلاف السلف في التفسير",
     "هل في الآية أقوال؟ ومن أي نوع؟", "الخلاف بين السلف في التفسير قليل", "ikhtilaf_explicit", "sourced"),
    ("tanawwu_ibara", "ikhtilaf", "أنواعه", "اتحاد المسمى واختلاف العبارة",
     "هل عبّر كل مفسّر عن المعنى نفسه بعبارة؟", "أحدهما: أن يعبر كل واحد منهم", None, "curated"),
    ("tanawwu_mithal", "ikhtilaf", "أنواعه", "ذكر بعض أفراد العام مثالًا",
     "هل ذكر كل مفسّر نوعًا من المعنى العام على سبيل المثال؟", "الصنف الثاني: أن يذكر كل منهم", None, "curated"),
    ("muhtamal", "ikhtilaf", "أنواعه", "اللفظ المحتمل لأمرين",
     "هل في الآية لفظ مشترك أو متواطئ يحتمل أكثر من معنى؟", "ومن التنازع الموجود عنهم", None, "curated"),
    ("nuzul", "ikhtilaf", "أنواعه", "أسباب النزول",
     "هل للآية سبب نزول؟", "ومعرفة سبب النزول يعين على فهم الآية", "nuzul", "sourced"),
    ("ijma", "ikhtilaf", "أنواعه", "الإجماع",
     "هل نُقل في الآية إجماع؟", None, "ijma", "sourced"),
    ("naql_istidlal", "usul", "أقسامه", "الاختلاف من جهة النقل ومن جهة الاستدلال",
     "ما حال المنقول في تفسير الآية؟", "الاختلاف في التفسير على نوعين", None, "group"),
    ("naql", "naql_istidlal", "أنواعه", "ما مستنده النقل",
     "هل حُكم على إسناد ما رُوي في الآية؟", "والمنقول إما عن المعصوم", "naql", "sourced"),
    ("istidlal", "naql_istidlal", "أنواعه", "ما يُعلم بالاستدلال",
     "هل فُسّرت الآية بحمل اللفظ على معتقد أو بمجرد اللغة؟", "وأما النوع الثاني من مستندي الاختلاف", None, "curated"),
    ("turuq", "usul", "أقسامه", "أحسن طرق التفسير",
     "بماذا فُسّرت هذه الآية؟", "فإن قال قائل: فما أحسن طرق التفسير", None, "group"),
    ("bil_quran", "turuq", "مراتبه", "تفسير القرآن بالقرآن",
     "هل فُسّرت الآية بآية أخرى؟", "إن أصح الطرق في ذلك أن يفسر القرآن بالقرآن", None, "curated"),
    ("bil_sunna", "turuq", "مراتبه", "تفسيره بالسنة",
     "هل فُسّرت الآية بحديث؟", "فإن أعياك ذلك فعليك بالسنة", "bayan_nabawi", "sourced"),
    ("bil_sahaba", "turuq", "مراتبه", "تفسيره بأقوال الصحابة",
     "هل للصحابة قول في الآية؟", "وحينئذ، إذا لم نجد التفسير في القرآن ولا في السنة", "turuq_sahabi", "sourced"),
    ("bil_tabiin", "turuq", "مراتبه", "تفسيره بأقوال التابعين",
     "هل للتابعين قول في الآية؟", "إذا لم تجد التفسير في القرآن ولا في السنة، ولا وجدته عن الصحابة", "turuq_tabii", "sourced"),
    ("bil_ray", "turuq", "مراتبه", "التفسير بمجرد الرأي",
     "هل في تفسيرها رأي مجرد؟", "فأما تفسير القرآن بمجرد الرأي", None, "curated"),
]


def fetch_pages() -> list[tuple[int, int, str]]:
    CACHE.mkdir(parents=True, exist_ok=True)
    pages = []
    for pg in range(1, 70):
        f = CACHE / f"{pg}.json"
        if not f.exists():
            req = urllib.request.Request(f"https://api.turath.io/page?book_id={BOOK_ID}&pg={pg}", headers={"User-Agent": UA})
            try:
                f.write_bytes(urllib.request.urlopen(req, timeout=40).read())
            except Exception:
                break
        try:
            j = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        meta = json.loads(j.get("meta") or "{}")
        text = re.sub(r"<[^>]+>", "", j.get("text") or "")
        if text.strip():
            pages.append((pg, int(meta.get("page") or 0), text))
    return pages


def quote(pages, opening: str, max_len: int = 260) -> tuple[str, int]:
    for _, printed, text in pages:
        i = text.find(opening)
        if i < 0:
            continue
        rest = re.sub(r"\s+", " ", text[i:])
        # Cut at the first sentence end (. or ؛) after a short minimum — a
        # whole sentence, never mid-word; else at the last space in range.
        m = re.search(r"[.؛](?:\s|$)", rest[30:max_len])
        if m:
            return rest[:30 + m.start() + 1].strip(), printed
        # No sentence end in range: cut at a word and say so («…») — an
        # honest quote never pretends a clipped sentence is whole.
        return rest[:rest.rfind(" ", 0, max_len)].strip().rstrip("،,:") + " …", printed
    raise SystemExit(f"quote not found verbatim: «{opening}»")


def main() -> None:
    pages = fetch_pages()
    if len(pages) < 40:
        raise SystemExit(f"only {len(pages)} pages fetched — refusing to build from a partial book")
    concepts, relations = [], []
    for ord_, (cid, parent, rel, title, question, opening, answer, mode) in enumerate(NODES):
        blocks = [["question", question, None]]
        if answer:  # U2 answers this node per ayah from shipped data
            blocks.append(["usul_answer", answer, None])
        short = None
        if opening:
            text, printed = quote(pages, opening)
            short = text
            blocks.insert(0, ["definition", text, SOURCE["id"], f"ص {printed}"])
        concepts.append({
            "id": f"concept:usul:{cid}",
            "domain": "usul_tafsir",
            "title_ar": title,
            "short_def_ar": short,
            "source_ref_ids": [SOURCE["id"]] if opening else [],
            "blocks": blocks,
        })
        if parent:
            relations.append({"from": f"concept:usul:{parent}", "rel": rel, "to": f"concept:usul:{cid}",
                              "ord": ord_, "source_ref_id": SOURCE["id"]})
    out = {"version": VERSION, "sources": [SOURCE], "concepts": concepts, "facts": [], "relations": relations}
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(concepts)} nodes, {len(relations)} relations -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
