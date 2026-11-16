"""ش1 of docs/KNOWLEDGE_TREE_ZAD_PLAN.md — the data for the connected tree of
«كتاب الطهارة»: Zad al-Mustaqni' (the tree), Bulugh al-Maram (the evidence),
al-Rawd al-Murbi' (the explanation).

    python tool/knowledge/build_zad_tree.py           # uses tool/.cache/turath, fetches what's missing
    → assets/knowledge_trees/zad_taharah.json

Sources (Turath, the same library the app already reads):
  Zad   11230  «زاد المستقنع في اختصار المقنع - ت العسكر»   al-Hajjawi (d. 968)  — public domain matn
  Rawd   1679  «الروض المربع شرح زاد المستقنع»              al-Buhuti (d. 1051)  — public domain
  Bulugh 9111  «بلوغ المرام من أدلة الأحكام ت الزهيري»       Ibn Hajr (d. 852)    — public domain matn

What is taken, and what is not (plan §4, ZAD_SOURCES.md §2):
  * Taken: the authors' own words — Zad's matn line by line, Ibn Hajr's
    hadith text and his own takhrij/grading («أخرجه الأربعة، وصححه ابن خزيمة»),
    a short opening excerpt of al-Rawd per chapter, and page ids to open the
    full text in the app's Turath reader.
  * Never taken: the modern editors' footnotes (below «_________») — al-Zuhayri's
    gradings and al-Askar's variant notes are their own protected work — nor
    their variant-reading quote marks, nor any grading not from Ibn Hajr.
  * Linking: Zad chapter ↔ Bulugh chapter by an explicit, reviewable table
    (CHAPTERS below). Ruling-level evidence links are NOT inferred here.
"""
import json
import re
import sys
import time
import urllib.request
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parent.parent.parent
CACHE = ROOT / 'tool/.cache/turath'
OUT = ROOT / 'assets/knowledge_trees/zad_taharah.json'
ZAD, RAWD, BULUGH = 11230, 1679, 9111

# Zad chapter title → (stable id, Bulugh chapter title). Reviewed by hand (2026-11-16).
CHAPTERS = [
    ('مدخل', 'miyah', 'باب المياه', 'المياه'),
    ('باب الآنية', 'aniya', 'باب الآنية', None),
    ('باب الاستنجاء', 'istinja', 'باب قضاء الحاجة', None),
    ('باب السواك وسنن الوضوء', 'siwak', 'باب الوضوء', None),
    ('باب فروض الوضوء وصفته', 'wudu', 'باب الوضوء', None),
    ('باب مسح الخفين', 'khuffayn', 'باب المسح على الخفين', None),
    ('باب نواقض الوضوء', 'nawaqid', 'باب نواقض الوضوء', None),
    ('باب الغسل', 'ghusl', 'باب الغسل وحكم الجنب', None),
    ('باب التيمم', 'tayammum', 'باب التيمم', None),
    ('باب إزالة النجاسة', 'najasa', 'باب إزالة النجاسة وبيانها', None),
    ('باب الحيض', 'hayd', 'باب الحيض', None),
]

# The matn's own ruling words, highlighted (order matters: negations first).
RULING_WORDS = [
    ('لم يكره', 'لا يُكره'), ('لا يكره', 'لا يُكره'), ('كره', 'يُكره'), ('يكره', 'يُكره'),
    ('يسن', 'يُسنّ'), ('سن ', 'يُسنّ'), ('يستحب', 'يُستحبّ'),
    ('يجب', 'يجب'), ('وجب', 'يجب'), ('فرض', 'فرض'), ('فروض', 'فرض'),
    ('يحرم', 'يحرم'), ('حرم ', 'يحرم'),
    ('لا يصح', 'لا يصحّ'), ('لم يصح', 'لا يصحّ'), ('يبطل', 'يبطل'), ('بطل', 'يبطل'),
    ('شرط', 'شرط'), ('يشترط', 'شرط'),
    ('يجزئ', 'يُجزئ'), ('لا يجزئ', 'لا يُجزئ'), ('يباح', 'يُباح'), ('مباح', 'يُباح'),
]

MARKS = re.compile('[ً-ٰٟؐ-ؚ]')
SPAN = re.compile(r'<span data-type="title" id=toc-\d+>(.*?)</span>', re.S)
TAG = re.compile(r'<[^>]+>')
AR_DIGITS = str.maketrans('٠١٢٣٤٥٦٧٨٩', '0123456789')


def bare(s):
    return re.sub(r'\s+', ' ', MARKS.sub('', s)).strip()


def get(path, **params):
    key = path + '_' + '_'.join(f'{k}{v}' for k, v in sorted(params.items()))
    f = CACHE / f'{key}.json'
    if f.exists():
        return json.loads(f.read_text(encoding='utf-8'))
    q = '&'.join(f'{k}={v}' for k, v in params.items())
    req = urllib.request.Request(f'https://api.turath.io/{path}?{q}&ver=3', headers={'User-Agent': 'Mozilla/5.0'})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                data = json.loads(r.read().decode('utf-8'))
            break
        except Exception:
            if attempt == 3:
                raise
            time.sleep(2 * (attempt + 1))
    CACHE.mkdir(parents=True, exist_ok=True)
    f.write_text(json.dumps(data, ensure_ascii=False), encoding='utf-8')
    time.sleep(0.25)  # be gentle with the library
    return data


def chapter_pages(book, book_title_word, next_book_word):
    """[(title, first_page_id, end_page_id_exclusive)] of the level-2 chapters of one kitab."""
    heads = get('book', id=book, include='indexes')['indexes']['headings']
    out, on, end = [], False, None
    for h in heads:
        if h['level'] == 1:
            if on and next_book_word in h['title']:
                end = h['page']
                break
            on = book_title_word in h['title']
        elif on and h['level'] == 2:
            out.append([h['title'], h['page']])
    return [(t, p, (out[i + 1][1] if i + 1 < len(out) else end)) for i, (t, p) in enumerate(out)]


PRINT_PAGE = re.compile(r'⦗[^⦘]*⦘')


def body(text):
    """Page text without the editor's footnotes and the printed-edition page markers ⦗٣١⦘."""
    return PRINT_PAGE.sub('', text.split('_________')[0])


# ---------------------------------------------------------------- Zad: one ruling per line
def zad_lines(page_text, chapter_titles):
    out = []
    for raw in body(page_text).split('\n'):
        line = raw.strip()
        if not line or line == '...':
            continue
        m = SPAN.fullmatch(line)
        if m:
            out.append(('title', bare(m.group(1))))
            continue
        line = TAG.sub('', line)
        line = re.sub('[٠-٩]+', '', line)            # footnote markers (editor's)
        line = line.replace('"', '').replace('“', '').replace('”', '')  # editor's variant marks
        line = re.sub(r'\s+', ' ', line).strip()
        if not line or bare(line) in chapter_titles or bare(line) == 'كتاب الطهارة':
            continue
        out.append(('text', line))
    return out


def ruling_words(line):
    b = ' ' + bare(line) + ' '
    found = []
    for w, label in RULING_WORDS:
        if (' ' + w) in b and label not in found:
            found.append(label)
            b = b.replace(' ' + w, ' ' + '_' * len(w))  # «لم يكره» must not also count as «كره»
    return found


# ---------------------------------------------------------------- Bulugh: numbered hadith
HADITH_START = re.compile(r'(?m)^\s*([٠-٩]+)\s*-\s*')


def bulugh_hadith(pages_text):
    """[{n, text}] from a chapter's page text.

    `text` is Ibn Hajr's words as he wrote them: the hadith and his own
    takhrij/grading together (they interleave — «ولمسلم…», «وصححه…» — so
    they are not split). The library's per-hadith topic titles are not
    taken: they sit in its index without a position per hadith, and they
    are the editor's, not Ibn Hajr's."""
    text = '\n'.join(body(t) for t in pages_text)
    out = []
    parts = HADITH_START.split(text)  # [pre, num1, text1, num2, text2, ...]
    for i in range(1, len(parts) - 1, 2):
        chunk = TAG.sub('', parts[i + 1])
        chunk = re.sub(r'\(\s*[٠-٩]+\s*\)', '', chunk)   # (١) → the editor's footnote ref
        chunk = re.sub(r'\s+', ' ', chunk).strip()
        out.append({'n': int(parts[i].translate(AR_DIGITS)), 'text': chunk})
    return out


def rawd_excerpt(page_text, chapter_title, limit=420):
    t = body(page_text)
    # start at the chapter's own heading («[باب الاستنجاء]» in al-Rawd's text), not mid-way
    # through the previous chapter that shares the page
    for m in SPAN.finditer(t):
        if bare(m.group(1)) == bare(chapter_title):
            t = t[m.end():]
            break
    else:
        i = t.find('[' + chapter_title + ']')
        if i < 0:  # e.g. «[باب مسح الخفين وغيرهما…]»: match on the chapter's last word
            i = t.find('[' + chapter_title.split()[-1])
        if i >= 0:
            t = t[t.find(']', i) + 1:]
    t = TAG.sub('', t)
    t = re.sub(r'\(\s*[٠-٩]+\s*\)|[٠-٩]+(?=\s)', '', t)
    t = re.sub(r'\s+', ' ', t).strip()
    if len(t) <= limit:
        return t
    cut = t.rfind('.', 0, limit)
    return t[: (cut + 1 if cut > 120 else limit)].strip() + ('' if cut > 120 else '…')


def main():
    zad_ch = chapter_pages(ZAD, 'الطهارة', 'الصلاة')
    bul_ch = {t: (p, e) for t, p, e in chapter_pages(BULUGH, 'الطهارة', 'الصلاة')}
    rawd_ch = chapter_pages(RAWD, 'الطهارة', 'الصلاة')
    assert [t for t, *_ in zad_ch] == [c[0] for c in CHAPTERS], [t for t, *_ in zad_ch]
    assert len(rawd_ch) == len(zad_ch)
    titles = {bare(t) for t, *_ in zad_ch} | {'مدخل'}

    chapters = []
    bulugh_cache = {}
    for (title, start, end), (ztitle, cid, btitle, label), (rtitle, rpage, _) in zip(zad_ch, CHAPTERS, rawd_ch):
        lines = []
        for pg in range(start, end):
            for kind, val in zad_lines(get('page', book_id=ZAD, pg=pg)['text'], titles):
                if kind == 'text':
                    lines.append(val)
        if btitle not in bulugh_cache:
            bp, be = bul_ch[btitle]
            bulugh_cache[btitle] = bulugh_hadith([get('page', book_id=BULUGH, pg=pg)['text'] for pg in range(bp, be)])
        hadith = bulugh_cache[btitle]
        chapters.append({
            'id': f'zad.taharah.{cid}',
            'title': label or title,
            'masail': [{'id': f'zad.taharah.{cid}.{i + 1}', 'text': l, 'ruling': ruling_words(l)} for i, l in enumerate(lines)],
            'sharh': {'source': 'rawd', 'chapter': rtitle, 'page': rpage,
                      'excerpt': rawd_excerpt(get('page', book_id=RAWD, pg=rpage)['text'], rtitle)},
            'evidence': {'source': 'bulugh', 'chapter': btitle, 'first': hadith[0]['n'] if hadith else None,
                         'last': hadith[-1]['n'] if hadith else None},
        })

    data = {
        'version': 1,
        'id': 'zad.taharah',
        'title': 'كتاب الطهارة',
        'sources': {
            'zad': {'turath_id': ZAD, 'title': 'زاد المستقنع في اختصار المقنع', 'author': 'شرف الدين الحجاوي (ت 968هـ)'},
            'rawd': {'turath_id': RAWD, 'title': 'الروض المربع شرح زاد المستقنع', 'author': 'منصور البهوتي (ت 1051هـ)'},
            'bulugh': {'turath_id': BULUGH, 'title': 'بلوغ المرام من أدلة الأحكام', 'author': 'ابن حجر العسقلاني (ت 852هـ)',
                       'numbering': 'ترقيم طبعة الزهيري (دار الفلق) كما في مكتبة تراث'},
        },
        'chapters': chapters,
        'bulugh': {t: h for t, h in bulugh_cache.items()},
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=0), encoding='utf-8')
    nm = sum(len(c['masail']) for c in chapters)
    nh = sum(len(h) for h in bulugh_cache.values())
    print(f'{len(chapters)} chapters, {nm} rulings (masail), {nh} hadith → {OUT} ({OUT.stat().st_size // 1024} KB)')
    for c in chapters:
        print(f"  {c['title']:28s} {len(c['masail']):3d} rulings  ← Bulugh «{c['evidence']['chapter']}» #{c['evidence']['first']}–{c['evidence']['last']}")


if __name__ == '__main__':
    main()
