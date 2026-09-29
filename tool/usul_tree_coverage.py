#!/usr/bin/env python3
"""U0 — how many ayat can each node of the usul-tafsir tree answer from data
we already ship? (docs/quran/USUL_TAFSIR_TREE.md §6, U0). Writes
docs/quran/reports/USUL_TREE_COVERAGE.md. No app code; read-only on assets.

Every count is of ayat with a SOURCED answer (a quoted text + its sayer +
its source), never an inferred one. Narrator tiers are a DRAFT list for
Ismail's review — scholarly classification, not something to guess.
"""
from __future__ import annotations

import gzip
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORPUS = ROOT / "assets/quran/corpus"
OUT = ROOT / "docs/quran/reports/USUL_TREE_COVERAGE.md"
TOTAL_AYAT = 6236

# DRAFT — for review. Top narrators by frequency; the rest stay "unclassified".
SAHABA = {
    "عبد الله بن عباس", "عبد الله بن مسعود", "أبو هريرة", "عبد الله بن عمر", "أنس بن مالك",
    "علي بن أبي طالب", "علي", "عائشة", "جابر بن عبد الله", "أبو سعيد الخدري", "عبد الله بن عمرو بن العاص",
    "عمر بن الخطاب", "أبو بن كعب", "أبي بن كعب", "أبو أمامة", "أبو الدرداء", "حذيفة بن اليمان", "البراء بن عازب",
    "أبو موسى الأشعري", "أبو ذر", "عبد الله بن الزبير", "سلمان الفارسي", "معاذ بن جبل",
}
TABIIN = {
    "قتادة بن دعامة", "مجاهد بن جبر", "الحسن البصري", "الحسن", "إسماعيل السدي", "الضحاك بن مزاحم",
    "سعيد بن جبير", "عكرمة مولى ابن عباس", "الربيع بن أنس", "عطاء", "عطاء بن أبي رباح", "أبو العالية الرياحي",
    "عامر الشعبي", "محمد بن كعب القرظي", "إبراهيم النخعي", "إبراهيم", "محمد بن شهاب الزهري", "زيد بن أسلم",
    "عطاء الخراساني", "أبو مالك غزوان الغفاري", "سعيد بن المسيب", "أبو صالح باذام", "عطية بن سعد العوفي",
    "عروة بن الزبير", "طاووس بن كيسان", "محمد بن سيرين", "مسروق بن الأجدع الهمداني", "عبيد بن عمير",
    "مكحول الشامي", "ميمون بن مهران", "وهب بن منبه", "كعب الأحبار", "الأعمش", "سليمان بن مهران الأعمش",
    "عاصم بن أبي النجود",
}
LATER = {  # أتباع التابعين ومن بعدهم (أصحاب التفاسير المسندة/المصنَّفة)
    "مقاتل بن سليمان", "مقاتل", "يحيى بن سلام", "عبد الرحمن بن زيد بن أسلم", "عبد الملك بن جريج",
    "محمد بن السائب الكلبي", "محمد بن إسحاق", "مقاتل بن حيان", "سفيان الثوري", "سفيان", "سفيان بن عيينة",
    "مالك بن أنس",
}
MARFU = re.compile(r"(قال رسول الله ﷺ|أنّ? (?:رسول الله|النبي) ﷺ قال|سمعت (?:رسول الله|النبي) ﷺ|سألت (?:رسول الله|النبي) ﷺ|عن النبي ﷺ)")
JUDGMENTS = {
    "صحيح": re.compile(r"إسناده صحيح|إسناد صحيح"),
    "حسن": re.compile(r"إسناده حسن"),
    "ضعيف": re.compile(r"إسناده ضعيف"),
    "مرسل": re.compile(r"مرسل"),
    "منقطع": re.compile(r"منقطع"),
    "موضوع": re.compile(r"موضوع"),
    "إسرائيلي": re.compile(r"إسرائيلي"),
}


def load(name: str) -> dict:
    for p in (CORPUS / f"{name}.json.gz", CORPUS / "packs" / f"{name}.json.gz"):
        if p.exists():
            return json.load(gzip.open(p))
    raise FileNotFoundError(name)


def main() -> None:
    sayings = load("sayings")
    node_ayat: dict[str, set] = defaultdict(set)
    tier_items = Counter()
    unclassified = Counter()
    judg_items = Counter()
    examples: dict[str, tuple] = {}

    for row in sayings["rows"]:
        key = (row["s"], row["a"])
        per_tier = set()
        for sy in row["sayings"]:
            text = sy.get("text") or ""
            body = re.sub(r"<[^>]+>", " ", text.split("<footer")[0])
            notes = " ".join(re.findall(r'title="([^"]*)"', text))
            typ = sy.get("type") or ""
            names = [n["name"] for n in sy.get("narrators") or []]

            # 1 — بيان النبي ﷺ
            if MARFU.search(body):
                node_ayat["bayan_nabawi"].add(key)
                examples.setdefault("bayan_nabawi", (key, body[:140]))
            # 4 — طرق التفسير: بمن فُسّرت؟
            for n in names:
                tier = "sahabi" if n in SAHABA else "tabii" if n in TABIIN else "later" if n in LATER else None
                if tier:
                    tier_items[tier] += 1
                    per_tier.add(tier)
                else:
                    unclassified[n] += 1
            # 3 — النقل: حكم الإسناد المقتبَس من التخريج
            for label, rx in JUDGMENTS.items():
                if rx.search(notes):
                    judg_items[label] += 1
                    node_ayat[f"naql_{label}"].add(key)
            if any(rx.search(notes) for rx in JUDGMENTS.values()):
                node_ayat["naql_any"].add(key)
            # 2 — النزول / النسخ / القراءات / الأحكام (تصنيف المصدر نفسه)
            if "نزول" in typ or "نزلت" in body:
                node_ayat["nuzul"].add(key)
            if "نسخ" in typ or "منسوخ" in typ:
                node_ayat["naskh"].add(key)
            if "قراء" in typ:
                node_ayat["qiraat"].add(key)
            if "حكام" in typ:
                node_ayat["ahkam"].add(key)
            # 2 — الإجماع / الاختلاف: عبارة صريحة في النص فقط
            if re.search(r"أجمع|إجماع|لا خلاف", body):
                node_ayat["ijma"].add(key)
                examples.setdefault("ijma", (key, body[:140]))
            if re.search(r"اختلف|اختلاف", body):
                node_ayat["ikhtilaf_explicit"].add(key)
        for t in per_tier:
            node_ayat[f"turuq_{t}"].add(key)
        if len([sy for sy in row["sayings"] if (sy.get("type") or "").startswith("تفسير")]) >= 2:
            node_ayat["ikhtilaf_hint"].add(key)  # several tafsir sayings — a hint, not a verdict

    # Other shipped datasets that answer branches directly — merged into the
    # node (the tree shows whichever source has the answer).
    extra = {}
    asbab_rows = load("asbab_books")["rows"][0]
    asbab_ayat = {(e["s"], e["a"]) for e in asbab_rows.get("entries", [])}
    extra["asbab_entries"] = len(asbab_rows.get("entries", []))
    extra["asbab_books"] = " + ".join(b["name"] for b in asbab_rows.get("books", []))
    nasekh_rows = load("nasekh")["rows"][0]
    nasekh_ayat = {(e["s"], e["a"]) for e in nasekh_rows.get("entries", [])}
    extra["nasekh_entries"] = len(nasekh_rows.get("entries", []))
    extra["qiraat_ayat"] = len(load("qiraat")["rows"])
    node_ayat["nuzul_all"] = node_ayat["nuzul"] | asbab_ayat
    node_ayat["naskh_all"] = node_ayat["naskh"] | nasekh_ayat
    all_names = set(unclassified) | {n for n in SAHABA | TABIIN | LATER}

    tier_names_seen = len({n for n in all_names if n in SAHABA | TABIIN | LATER})
    classified = sum(tier_items.values())
    total_names = classified + sum(unclassified.values())

    def pct(n: int) -> str:
        return f"{n} ({n * 100 / TOTAL_AYAT:.1f}%)"

    lines = [
        "# USUL_TREE_COVERAGE.md — تغطية شجرة أصول التفسير من بياناتنا (U0)",
        "",
        "مولَّد بـ`tool/usul_tree_coverage.py` من `sayings` (Quranpedia، 6193 آية، 84,421 نصًّا) وبقية مجموعات العلوم المضمَّنة. "
        "كل رقم = آيات لها **جواب مصدَّر** (نص مقتبس + قائله + مصدره) — لا استنتاج.",
        "",
        "## هوية `sayings`",
        "",
        "الشكل يطابق «موسوعة التفسير المأثور» (مركز الدراسات القرآنية بمعهد الإمام الشاطبي): آثار مسندة بصيغة «عن فلان -من طريق فلان-»، "
        f"قائمة رواة منظّمة ({len(unclassified) + len([n for n in SAHABA | TABIIN | LATER])}+ اسمًا)، وحاشية «التخريج» بحكم الإسناد، "
        "وتصنيف كل نص (تفسير/نزول/نسخ/قراءات/أحكام). **يبقى تأكيد الهوية والترخيص نصًّا** من صفحة المصدر أو من إسماعيل قبل U1.",
        "",
        f"## التغطية لكل عقدة (من {TOTAL_AYAT} آية)",
        "",
        "| الفرع (مقدمة ابن تيمية) | العقدة | آيات بجواب مصدَّر | نوع الجواب |",
        "|---|---|---:|---|",
        f"| ١. بيان النبي ﷺ | ورد في الآية حديث مرفوع | {pct(len(node_ayat['bayan_nabawi']))} | اقتباس النص + الراوي + التخريج |",
        f"| ٢. التنوع والتضاد | الإجماع (عبارة صريحة) | {pct(len(node_ayat['ijma']))} | اقتباس قائل الإجماع |",
        f"| ٢. التنوع والتضاد | الاختلاف (مذكور صراحة) | {pct(len(node_ayat['ikhtilaf_explicit']))} | اقتباس |",
        f"| ٢. التنوع والتضاد | تعدد أقوال التفسير (تلميح) | {pct(len(node_ayat['ikhtilaf_hint']))} | «قد ينطبق — للمراجعة»، ونوع الخلاف منسَّق فقط |",
        f"| ٢. أسباب النزول | نزول مذكور (الآثار ∪ كتب الأسباب) | {pct(len(node_ayat['nuzul_all']))} | نص + مصدره — الآثار وحدها {len(node_ayat['nuzul'])}، و`asbab_books` ({extra['asbab_books']}) {extra['asbab_entries']} مدخلًا |",
        f"| ٢. — | النسخ (الآثار ∪ «الإيضاح») | {pct(len(node_ayat['naskh_all']))} | نص — الآثار وحدها {len(node_ayat['naskh'])}، و`nasekh` {extra['nasekh_entries']} مدخلًا |",
        f"| ٢. — | القراءات | {pct(len(node_ayat['qiraat']))} | نص؛ و`qiraat` يغطي {extra['qiraat_ayat']} آية |",
        f"| ٢. — | الأحكام | {pct(len(node_ayat['ahkam']))} | نص |",
        f"| ٣. النقل | في التخريج حكم على الإسناد | {pct(len(node_ayat['naql_any']))} | **حكم المخرِّج مقتبسًا** — لا حكم منّا |",
    ]
    for label in JUDGMENTS:
        lines.append(f"| ٣. النقل | — منها «{label}» | {pct(len(node_ayat[f'naql_{label}']))} | ({judg_items[label]} نصًّا) |")
    lines += [
        f"| ٤. طرق التفسير | بأقوال الصحابة | {pct(len(node_ayat['turuq_sahabi']))} | نص منسوب |",
        f"| ٤. طرق التفسير | بأقوال التابعين | {pct(len(node_ayat['turuq_tabii']))} | نص منسوب |",
        f"| ٤. طرق التفسير | بأقوال أتباع التابعين ومن بعدهم | {pct(len(node_ayat['turuq_later']))} | نص منسوب |",
        "",
        "## تصنيف الرواة (مسوّدة للمراجعة)",
        "",
        f"صُنّف {classified} من {total_names} إسنادًا ({classified * 100 / max(total_names, 1):.1f}%) بقائمة ثابتة لأشهر {len(SAHABA | TABIIN | LATER)} اسمًا "
        "(صحابي/تابعي/أتباع). **القائمة في `tool/usul_tree_coverage.py` تحتاج مراجعة إسماعيل** — التصنيف علم لا تخمين، "
        "وما لم يُصنَّف يبقى «غير مصنّف» ولا يُعرض في فرع الطرق.",
        "",
        "أكثر غير المصنّفين تكرارًا (مرشحون للإضافة بعد المراجعة):",
        "",
    ]
    for name, c in unclassified.most_common(15):
        lines.append(f"- {name} — {c}")
    lines += [
        "",
        "## ما لا تجيبه البيانات آليًّا (منسَّق من الكتب في U5)",
        "",
        "- **نوع الخلاف** (تنوّع/تضاد) وأصنافه (اتحاد المسمى، ذكر بعض الأفراد، المشترك، المتواطئ): لا تصنيف آلي — من أمثلة شرح الطيار وقواعد الترجيح بالصفحة.",
        "- **أسباب الاختلاف**: من «أسباب اختلاف المفسرين» (الشايع) — PDF مطلوب من إسماعيل.",
        "- **خطأ الاستدلال** (حمل اللفظ على معتقد، التفسير بمجرد اللغة): منسَّق فقط.",
        "- **الإجماع — صريح/غير صريح، حكمه، أقسامه**: تعريفات «التمهير» المقتبسة + أمثلة الشرح.",
        "",
        "## أمثلة (للتحقق اليدوي)",
        "",
    ]
    for k, (key, snippet) in examples.items():
        lines.append(f"- `{k}` — {key[0]}:{key[1]} — «{snippet.strip()}…»")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
