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
import unicodedata
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / "tool/.cache/muqaddima"
OUT = ROOT / "assets/quran_learning/usul_tree.json"
BOOK_ID = 12081
UA = "TalibAlIlm-build/1.0 (+https://github.com/issmalahad-creator/TalibAlIlmApp)"
VERSION = 2

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


# U5 — the ayat Ibn Taymiyya himself uses as examples in the Muqaddima,
# each shown on its node for that ayah with his words verbatim + page.
#   (node, [(surah, ayah, probe)], kind, opening, end[, lead])
#   kind:  example — an example of this principle
#          error   — a mistaken tafsir he cites to warn against it
#          basis   — the ayah is itself evidence for the principle
#   end:   None = up to the first «.» or «؛»; "،" = just this clause;
#          any other string = up to and including that text.
#   probe: a word that must occur in the ayah (normalized) — catches a
#          wrong surah/ayah before it ships. Refs in «[…]» come from the
#          edition; the rest are words that occur once in the Quran
#          (قسورة، عسعس…) or named passages (آية الظهار، اللعان، الكلالة).
EXAMPLES = [
    # اتحاد المسمى واختلاف العبارة — and «ألفاظ متقاربة لا مترادفة» (same kind)
    ("tanawwu_ibara", [(1, 6, "صراط")], "example", "فهذان القولان متفقان", None),
    ("tanawwu_ibara", [(20, 124, "ذكري")], "example", "فسواء قيل: ذكري كتابي", None),
    ("tanawwu_ibara", [(52, 9, "تمور")], "example", "إن المور هو الحركة كان تقريبا", None),
    ("tanawwu_ibara", [(2, 2, "ريب")], "example", "ومن قال: ﴿لاريب﴾: لا شك، فهذا تقريب", "فيه اضطراب وحركة"),
    ("tanawwu_ibara", [(6, 70, "تبسل")], "example", "فإذا قال أحدهم: ﴿أَن تُبْسَلَ﴾", "تقريب للمعنى كما تقدم"),
    ("tanawwu_ibara", [(4, 163, "اوحينا"), (17, 4, "قضينا")], "example", "وكذلك إذا قال: الوحي: الإعلام", None),
    # ذكر بعض أفراد العام مثالًا
    ("tanawwu_mithal", [(35, 32, "ظالم")], "example", "فمعلوم أن الظالم لنفسه يتناول", "هم أصحاب اليمين"),
    ("tanawwu_mithal", [(35, 32, "ظالم")], "example", "فكل قول فيه ذكر نوع داخل في الآية", None),
    # اللفظ المحتمل لأمرين
    ("muhtamal", [(74, 51, "قسوره")], "example", "إما لكونه مشتركًا في اللفظ كلفظ", "ويراد به الأسد،"),
    ("muhtamal", [(81, 17, "عسعس")], "example", "ولفظ ﴿عَسْعَسَ﴾", "،"),
    ("muhtamal", [(53, 8, "دنا"), (53, 9, "قوسين")], "example", "كالضمائر في قوله", "،"),
    ("muhtamal", [(89, 1, "الفجر"), (89, 2, "عشر"), (89, 3, "الوتر")], "example", "وكلفظ ﴿وَالْفَجْرِ", None),
    ("muhtamal", [(74, 51, "قسوره"), (81, 17, "عسعس")], "example", "فمثل هذا قد يجوز أن يراد به كل المعاني", None),
    # أسباب النزول — named as examples; the ruling is never limited to them
    ("nuzul", [(58, 1, "تجادلك")], "example", "إن آية الظهار نزلت في امرأة", "،"),
    ("nuzul", [(24, 6, "يرمون")], "example", "وإن آية اللعان نزلت في", "،"),
    ("nuzul", [(4, 176, "الكلاله")], "example", "وإن آية الكلالة نزلت في", "،"),
    ("nuzul", [(5, 49, "احكم بينهم")], "example", "وإن قوله: ﴿وَأَنِ احْكُم بَيْنَهُم", "،"),
    ("nuzul", [(8, 16, "يولهم")], "example", "وأن قوله: ﴿وَمَن يُوَلِّهِمْ", "،"),
    ("nuzul", [(5, 106, "شهاده بينكم")], "example", "وأن قوله: ﴿شَهَادَةُ بَيْنِكُمْ", "،"),
    ("nuzul", [(2, 195, "التهلكه")], "example", "وقول أبي أيوب إن قوله", None),
    ("nuzul", [(58, 1, "تجادلك"), (24, 6, "يرمون"), (4, 176, "الكلاله"), (5, 49, "احكم بينهم"),
               (8, 16, "يولهم"), (5, 106, "شهاده بينكم"), (2, 195, "التهلكه")],
     "example", "والآية التي لها سبب معين، إن كانت أمرا ونهيا", None),
    # ما مستنده النقل — what cannot be known and brings no benefit; fabrications
    ("naql", [(18, 18, "كلبهم")], "example", "فمثال ما لا يفيد ولا دليل على الصحيح منه", "،"),
    ("naql", [(2, 73, "ببعضها")], "example", "وفي البعض الذي ضرب به موسى", "،"),
    ("naql", [(18, 74, "غلاما")], "example", "وفي اسم الغلام الذي قتله الخضر", "،"),
    ("naql", [(18, 22, "رابعهم")], "basis", "فقد اشتملت هذه الآية الكريمة على الأدب", None),
    ("naql", [(18, 22, "رابعهم")], "basis", "فهذا أحسن ما يكون في حكاية الخلاف", None),
    ("naql", [(13, 7, "هاد"), (69, 12, "واعيه"), (5, 55, "وليكم")], "error", "والموضوعات في كتب التفسير كثيرة", None),
    # ما يُعلم بالاستدلال — a belief first, then the words carried onto it
    ("istidlal", [(111, 1, "تبت")], "error", "فتفسير الرافضة كقولهم", "،"),
    ("istidlal", [(39, 65, "اشركت")], "error", "و﴿لَئِنْ أَشْرَكْتَ", "،", "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(2, 67, "بقره")], "error", "و﴿إِنَّ اللهَ يَأْمُرُكُمْ", "،", "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(9, 12, "ئمة الكفر")], "error", "و﴿فَقَاتِلُواْ أَئِمَّةَ الْكُفْرِ﴾", "،", "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(55, 19, "مرج")], "error", "و﴿مَرَجَ الْبَحْرَيْنِ﴾", "،", "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(55, 22, "المرجان")], "error", "و﴿اللُّؤْلُؤُ وَالْمَرْجَانُ﴾", "،", "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(36, 12, "امام مبين")], "error", "و﴿وَكُلَّ شَيْءٍ أحْصَيْنَاهُ", "،", "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(78, 1, "يتسا"), (78, 2, "النبا العظيم")], "error", "و﴿عَمَّ يَتَسَاءلُونَ", "،", "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(5, 55, "وليكم")], "error", "و﴿إِنَّمَا وَلِيُّكُمُ اللهُ", None, "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(2, 157, "صلوات")], "error", "وكذلك قوله: ﴿أُولَئِكَ عَلَيْهِمْ صَلَوَاتٌ", None, "فتفسير الرافضة كقولهم:"),
    ("istidlal", [(95, 1, "التين"), (95, 2, "سينين"), (95, 3, "البلد")], "error", "وأعجب من ذلك قول بعضهم", "،"),
    ("istidlal", [(95, 1, "التين"), (95, 2, "سينين"), (95, 3, "البلد"), (48, 29, "اشداء")],
     "error", "وأمثال هذه الخرافات التي تتضمن", "،"),
    ("istidlal", [(48, 29, "اشداء")], "error", "وقوله تعالى: ﴿وَالَّذِينَ مَعَهُ أَشِدَّاء", None),
    ("istidlal", [(5, 55, "وليكم"), (39, 33, "بالصدق"), (57, 10, "الفتح")], "error",
     "وتتضمن تارة جعل اللفظ المطلق العام منحصرا في شخص واحد", "،"),
    ("istidlal", [(39, 33, "بالصدق")], "error", "وقول بعضهم: إن قوله: ﴿وَالَّذِي جَاء بِالصِّدْقِ", "،"),
    ("istidlal", [(57, 10, "الفتح")], "error", "وقوله: ﴿لَا يَسْتَوِي مِنكُم", " ونحو ذلك."),
    ("istidlal", [(111, 1, "تبت"), (39, 65, "اشركت"), (2, 67, "بقره"), (9, 12, "ئمة الكفر"),
                  (55, 19, "مرج"), (55, 22, "المرجان"), (36, 12, "امام مبين"), (78, 1, "يتسا"), (78, 2, "النبا العظيم"),
                  (5, 55, "وليكم"), (2, 157, "صلوات"), (48, 29, "اشداء"), (95, 1, "التين"),
                  (95, 2, "سينين"), (95, 3, "البلد"), (39, 33, "بالصدق"), (57, 10, "الفتح")],
     "error", "والمقصود أن مثل هؤلاء اعتقدوا رأيا ثم حملوا ألفاظ القرآن عليه", "،"),
    # التفسير بمجرد الرأي — the Companions' restraint
    ("bil_ray", [(80, 31, "وابا")], "example", "أن أبا بكر الصديق سئل عن قوله", "منقطع"),
    ("bil_ray", [(80, 31, "وابا")], "example", "أن عمر بن الخطاب قرأ على المنبر", "يا عمر."),
    ("bil_ray", [(80, 31, "وابا")], "example", "وهذا كله محمول على أنهما", None),
    ("bil_ray", [(32, 5, "الف سنه"), (70, 4, "خمسين الف")], "example", "سأل رجل ابن عباس عن", "ما لا يعلم."),
    # تفسيره بالسنة — the ayat that make the Sunnah the Quran's explanation
    ("bil_sunna", [(4, 105, "لتحكم"), (16, 44, "لتبين"), (16, 64, "لتبين")], "basis",
     "فإن أعياك ذلك فعليك بالسنة", "،"),
    ("bil_sunna", [(4, 105, "لتحكم"), (16, 44, "لتبين"), (16, 64, "لتبين")], "basis",
     "قال الإمام أبو عبد الله محمد بن إدريس الشافعي", "،"),
]

_TASHKEEL = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـ]")


def norm(s: str) -> str:
    s = _TASHKEEL.sub("", s)
    # The Uthmani script drops or reshapes alifs and hamza seats (الصرط،
    # أئمة): compare skeletons without them, on both sides.
    for a, b in (("ى", "ي"), ("ة", "ه")):
        s = s.replace(a, b)
    return re.sub("[اأإآٱءئؤ]", "", s)


def quran_text() -> dict[tuple[int, int], str]:
    out = {}
    for line in (ROOT / "assets/quran/quran-uthmani.txt").read_text(encoding="utf-8").splitlines():
        parts = line.split("|", 2)
        if len(parts) == 3 and parts[0].isdigit():
            out[(int(parts[0]), int(parts[1]))] = norm(parts[2]).replace(" ", "")
    return out


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
        # NFC: the same mark sequence typed in two orders (shadda+kasra) must match.
        text = unicodedata.normalize("NFC", re.sub(r"<[^>]+>", "", j.get("text") or ""))
        if text.strip():
            pages.append((pg, int(meta.get("page") or 0), text))
    return pages


def quote(pages, opening: str, max_len: int = 260) -> tuple[str, int]:
    opening = unicodedata.normalize("NFC", opening)
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


def clause(pages, opening: str, end: str | None) -> tuple[str, int]:
    """An example's quote: to a sentence end (None), to the first «،» ("،"),
    or up to and including `end`. A quote that stops mid-sentence ends in «…»."""
    if end is None:
        return quote(pages, opening, max_len=520)
    opening = unicodedata.normalize("NFC", opening)
    for _, printed, text in pages:
        i = text.find(opening)
        if i < 0:
            continue
        rest = re.sub(r"\s+", " ", text[i:])
        if end == "،":
            # The first «،» outside a reference or an ayah — «[النجم: ٨، ٩]»
            # must never end a clause.
            depth, j = 0, -1
            for k, ch in enumerate(rest):
                if ch in "[﴿(":
                    depth += 1
                elif ch in "]﴾)":
                    depth = max(0, depth - 1)
                elif ch == "،" and depth == 0 and k >= len(opening) - 1:
                    j = k
                    break
            if j < 0 or j > 520:
                raise SystemExit(f"no clause end after «{opening}»")
            return rest[:j].strip() + " …", printed
        j = rest.find(end)
        if j < 0 or j > 700:
            raise SystemExit(f"end «{end}» not found after «{opening}»")
        return rest[:j + len(end)].strip().rstrip("،") + ("" if end.endswith((".", "؟")) else " …"), printed
    raise SystemExit(f"quote not found verbatim: «{opening}»")


def build_examples(pages) -> list[dict]:
    quran = quran_text()
    facts, seen = [], set()
    for n, (node, ayat, kind, opening, end, *lead) in enumerate(EXAMPLES):
        if node not in {c[0] for c in NODES}:
            raise SystemExit(f"example {n}: unknown node {node}")
        text, printed = clause(pages, opening, end)
        if lead:
            # A list item that continues its lead-in («فتفسير الرافضة كقولهم: …»):
            # the lead is quoted too, the words between them elided with «…».
            head = unicodedata.normalize("NFC", lead[0])
            if not any(head in t for _, _, t in pages):
                raise SystemExit(f"example {n}: lead not found verbatim: «{head}»")
            text = f"{head} … {text}"
        for s, a, probe in ayat:
            if norm(probe).replace(" ", "") not in quran.get((s, a), ""):
                raise SystemExit(f"example {n}: «{probe}» is not in {s}:{a} — wrong reference")
            fid = f"usul:{node}:{s:03d}:{a:03d}:{n:03d}"
            assert fid not in seen, fid
            seen.add(fid)
            facts.append({
                "id": fid,
                "domain": "usul_tafsir",
                "anchor": {"surah": s, "ayah": a, "scope": "ayah"},
                "payload": {"concept_id": f"concept:usul:{node}", "kind": kind, "text": text, "locator": f"ص {printed}"},
                "source_ref_id": SOURCE["id"],
            })
    return facts


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
    facts = build_examples(pages)
    out = {"version": VERSION, "sources": [SOURCE], "concepts": concepts, "facts": facts, "relations": relations}
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")
    ayat = {(f["anchor"]["surah"], f["anchor"]["ayah"]) for f in facts}
    print(f"{len(concepts)} nodes, {len(relations)} relations, {len(facts)} examples on {len(ayat)} ayat"
          f" -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
