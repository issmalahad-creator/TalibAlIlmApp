"""Builds assets/brand/daily_benefits.json — the pool of short, sourced
hadith / dhikr / ayat / fawa'id shown one at a time on the brand splash and
the Home «فائدة اليوم» card (Ismail 2026-09-27: «أحاديث وفوائد عشوائية تظهر
بشكل متجدد في كل دخول»).

Rules (docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md §6):
- every item carries its source; nothing is paraphrased or invented;
- hadith are shown WHOLE (never cut) — long ones are left out, not trimmed;
- dhikr only when the takhrij names al-Bukhari/Muslim or states a
  «صحيح» grading;
- ayat come verbatim from the bundled Uthmani text, by reference;
- Ibn al-Qayyim's «الفوائد» (d. 751 AH, public domain) short standalone
  paragraphs, with the printed page of the Turath edition.

Usage:  python tool/build_daily_benefits.py [--refresh-turath]
The Turath pages are cached under build/daily_benefits_cache/ (gitignored
build dir) so re-runs are offline and reproducible.
"""

from __future__ import annotations

import html
import json
import pathlib
import re
import sys
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'brand' / 'daily_benefits.json'
CACHE = ROOT / 'build' / 'daily_benefits_cache'

FAWAID_BOOK = 212  # «الفوائد لابن القيم - ط عطاءات العلم» on turath.io
FAWAID_NAME = 'الفوائد لابن القيم'
# Printed pages 1-10 of this edition are the modern editor's introduction,
# not Ibn al-Qayyim; his text runs from «قاعدة جليلة» (p. 11) to p. 305.
FAWAID_FIRST_PAGE = 11
FAWAID_LAST_PAGE = 305

# Short ayat for reflection — chosen by reference; the TEXT always comes from
# assets/quran/quran-uthmani.txt so it is exactly the mushaf text.
AYAT = [
    (20, 114), (2, 152), (13, 28), (94, 6), (3, 139), (40, 60), (29, 69), (3, 200), (2, 153), (49, 10),
    (55, 60), (93, 5), (93, 3), (20, 25), (68, 4), (33, 41), (51, 56), (6, 162), (65, 3), (2, 186),
    (39, 10), (3, 8), (7, 23), (14, 7), (96, 1), (2, 45), (8, 46), (11, 115), (16, 128), (35, 28),
    (58, 11), (39, 53), (57, 20), (25, 63), (23, 1), (87, 14), (91, 9), (17, 53), (41, 34), (42, 43),
]

BASMALA = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'

ARABIC_DIGITS = '٠١٢٣٤٥٦٧٨٩'


def ar_num(n: int) -> str:
    return ''.join(ARABIC_DIGITS[int(d)] for d in str(n))


def load_quran() -> tuple[dict[tuple[int, int], str], dict[int, str]]:
    ayat = {}
    for line in (ROOT / 'assets/quran/quran-uthmani.txt').read_text(encoding='utf-8').splitlines():
        parts = line.split('|')
        if len(parts) == 3 and parts[0].isdigit():
            ayat[(int(parts[0]), int(parts[1]))] = parts[2].strip()
    # Surah names from the app's own list (quran-data.js is double-encoded).
    names = {}
    dart = (ROOT / 'lib/data/quran_surahs.dart').read_text(encoding='utf-8')
    for m in re.finditer(r"QuranSurah\((\d+),\s*'([^']+)'", dart):
        names[int(m.group(1))] = m.group(2)
    assert len(names) == 114, len(names)
    return ayat, names


def build_ayat() -> list[dict]:
    ayat, names = load_quran()
    out = []
    for s, a in AYAT:
        text = ayat.get((s, a))
        if text and a == 1 and s != 1 and bare(text).startswith(bare('بسم الله الرحمن الرحيم')[:3]):
            # The file prefixes surah openings with the basmala (4 words); it is
            # not part of the ayah, so drop it.
            words = text.split()
            if bare(' '.join(words[:4])).replace('ٱ', 'ا') == 'بسم الله الرحمن الرحيم':
                text = ' '.join(words[4:])
        if not text or len(text) > 170:
            continue
        name = names.get(s, '')
        out.append({
            'id': f'ayah:{s}:{a}',
            'kind': 'ayah',
            'text': text,
            'source': f'سورة {name} — آية {ar_num(a)}' if name else f'{s}:{a}',
            'surah': s,
            'ayah': a,
        })
    return out


def build_nawawi() -> list[dict]:
    data = json.loads((ROOT / 'assets/hadith/nawawi40.json').read_text(encoding='utf-8'))
    out = []
    for i, h in enumerate(data, start=1):
        if i in NAWAWI_NEEDS_CONTEXT:
            continue
        raw = h['hadith'].strip()
        title, _, body = raw.partition('\n')
        body = re.sub(r'\s+', ' ', body).strip()
        if not body or len(body) > 300:
            continue  # shown whole or not at all
        out.append({
            'id': f'nawawi:{i}',
            'kind': 'hadith',
            'text': body,
            'source': f'الأربعون النووية — {title.strip()}',
        })
    return out


COLLECTIONS = ['البخاري', 'مسلم', 'أبو داود', 'الترمذي', 'النسائي', 'ابن ماجه', 'أحمد']

# Authentic, but misread without its explanation when shown alone on a
# launch screen; it stays in the full Nawawi section with its sharh.
NAWAWI_NEEDS_CONTEXT = {8}

# Timeless, general dhikr only — not occasion-bound ones (funeral prayer,
# entering the toilet…) that make no sense shown at random on app launch.
HISN_CATEGORY_HINTS = ('فضل', 'الصباح والمساء', 'الاستغفار', 'الهم والحزن', 'الكرب', 'بعد السلام من الصلاة', 'التسبيح')


def build_hisn() -> list[dict]:
    cats = json.loads((ROOT / 'assets/adhkar/hisn_almuslim.json').read_text(encoding='utf-8'))
    out = []
    for cat in cats:
        if not any(h in cat['title'] for h in HISN_CATEGORY_HINTS):
            continue
        for j, it in enumerate(cat['items']):
            text = re.sub(r'\s+', ' ', it.get('text') or '').strip()
            text = text.replace('صلى الله عيه وسلم', 'صلى الله عليه وسلم')  # typo in the source JSON
            fn = (it.get('footnote') or '').replace('أبي داود', 'أبو داود')
            strong = 'البخاري' in fn or 'مسلم' in fn or 'صحيح' in fn
            if not strong or not (25 <= len(text) <= 220):
                continue
            named = [c for c in COLLECTIONS if c in fn]
            out.append({
                'id': f"hisn:{cat['order']}:{j}",
                'kind': 'dhikr',
                'text': text,
                'source': 'حصن المسلم — ' + cat['title'] + (' · رواه ' + '، '.join(named) if named else ''),
                'takhrij': fn.strip(),
            })
    return out


def turath_page(pg: int, refresh: bool) -> dict | None:
    CACHE.mkdir(parents=True, exist_ok=True)
    f = CACHE / f'{FAWAID_BOOK}_{pg}.json'
    if f.exists() and not refresh:
        return json.loads(f.read_text(encoding='utf-8'))
    url = f'https://api.turath.io/page?book_id={FAWAID_BOOK}&pg={pg}'
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, headers={
                # The API rejects requests without a User-Agent (403).
                'User-Agent': 'TalibAlIlm-build/1.0 (+https://github.com/issmalahad-creator/TalibAlIlmApp)',
            })
            with urllib.request.urlopen(req, timeout=30) as r:
                d = json.loads(r.read().decode('utf-8'))
            f.write_text(json.dumps(d, ensure_ascii=False), encoding='utf-8')
            time.sleep(0.3)  # be polite to the API
            return d
        except Exception:
            time.sleep(1 + attempt)
    return None


# First-person-plural divine voice («عندنا»، «أبعدنا»، «تركتنا»…) used by Ibn
# al-Qayyim as a literary device; shown alone it could be mistaken for a
# Quranic or qudsi text, so it is never picked.
DIVINE_VOICE = re.compile(r'عندنا|أبعدنا|ابعدنا|تركتنا|إلينا|الينا|بابنا|أحببناك|عبدي')

TASHKEEL = re.compile('[ً-ٰٟـ]')


def bare(s: str) -> str:
    """Text without tashkeel/tatweel — so filters match «أحدُهُما» as «أحدهما»."""
    return TASHKEEL.sub('', s)


CONTEXT_BOUND = re.compile(
    r'^(الأول|الأولى|الثاني|الثانية|الثالث|الثالثة|الرابع|الرابعة|الخامس|الخامسة|السادس|السادسة|السابع|السابعة|'
    r'الثامن|الثامنة|التاسع|التاسعة|العاشر|العاشرة|أحدها|أحدهما|ومنها|منها|وهذا|هذا|هذه|وهذه|وهو|وهي)[ُِ]?[:،\s]'
    r'|^قلت:|^قلت |الآية|هذا الحديث|في الحديث|المذكور|ما تقدم|ما سبق|كما ذكرنا|الوجه ال|^قسم |^يوضحه|^ويوضحه|وقال:'
)

NOISE = re.compile(r'[\(\[]\s*[\d٠-٩]+\s*[\)\]]|\^|https?://|«[^»]*$')


def build_fawaid(refresh: bool) -> list[dict]:
    out = []
    seen = set()
    pg = 1
    misses = 0
    while misses < 3:
        d = turath_page(pg, refresh)
        if not d or not d.get('text'):
            misses += 1
            pg += 1
            continue
        misses = 0
        meta = d.get('meta')
        meta = json.loads(meta) if isinstance(meta, str) else (meta or {})
        printed = meta.get('page', pg)
        try:
            printed_n = int(printed)
        except (TypeError, ValueError):
            printed_n = -1
        # The range is in API page indices (what the book's heading index
        # uses): «قاعدة جليلة» — the first words of Ibn al-Qayyim — is API
        # page 11; before it is the editor's introduction.
        if not (FAWAID_FIRST_PAGE <= pg <= FAWAID_LAST_PAGE) or printed_n < 0:
            pg += 1
            continue  # editor's introduction / back matter — not Ibn al-Qayyim
        # A page's first paragraph usually continues the previous page's
        # sentence (page breaks fall mid-paragraph) — never standalone.
        for para in re.split(r'\n+', d['text'])[1:]:
            p = re.sub(r'\s+', ' ', html.unescape(para)).strip().lstrip('•').strip()
            p = re.sub(r'<[^>]+>', '', p).strip()  # stray HTML tags from the source
            if DIVINE_VOICE.search(bare(p)):
                continue  # Ibn al-Qayyim's rhetorical divine address — alone it could be read as Allah's words
            if not (70 <= len(p) <= 260):
                continue
            if NOISE.search(p) or p.startswith(('قال', 'وقال', 'فصل', 'ثم', 'ف', 'و', '-', '(', '«', '"')):
                continue  # continuation / quotation / heading / footnote — not standalone
            if CONTEXT_BOUND.search(bare(p)) or p.startswith(('﴿', '[', 'كقوله', 'وكقوله')):
                continue  # enumerated item / refers to "the verse" / "this" — needs its context
            if not p.endswith(('.', '!', '؟', '».', '».')):
                continue
            key = p[:40]
            if key in seen:
                continue
            seen.add(key)
            out.append({
                'id': f'fawaid:{FAWAID_BOOK}:{pg}:{len(out)}',
                'kind': 'faida',
                'text': p,
                'source': f'ابن القيم — {FAWAID_NAME}، ص{ar_num(int(printed))}' if str(printed).isdigit() else f'ابن القيم — {FAWAID_NAME}',
            })
        pg += 1
    return out


def main() -> int:
    refresh = '--refresh-turath' in sys.argv
    pools = {
        'hadith': build_nawawi(),
        'dhikr': build_hisn(),
        'ayah': build_ayat(),
        'faida': build_fawaid(refresh),
    }
    items = [x for pool in pools.values() for x in pool]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({'v': 1, 'items': items}, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    for k, v in pools.items():
        print(f'{k}: {len(v)}')
    print(f'total {len(items)} -> {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
