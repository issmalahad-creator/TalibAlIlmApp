"""ش1/ش7 of docs/KNOWLEDGE_TREE_ZAD_PLAN.md — the data for the connected trees
of Zad's worship: Zad al-Mustaqni' (the tree), Bulugh al-Maram (the
evidence), al-Rawd al-Murbi' (the explanation).

    python tool/knowledge/build_zad_tree.py           # uses tool/.cache/turath, fetches what's missing
    → assets/knowledge_trees/zad_<kitab>.json (one per kitab) + index.json

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
OUT_DIR = ROOT / 'assets/knowledge_trees'
ZAD, RAWD, BULUGH = 11230, 1679, 9111
INTRO = None  # a chapter's al-Rawd / Bulugh counterpart is the kitab's own opening

# One entry per kitab: Zad's kitab title, Bulugh's, al-Rawd's, and per Zad
# chapter (in Zad's order): (Zad chapter title, stable id, display label or
# None, Bulugh chapter title or INTRO, al-Rawd chapter title or INTRO).
# Reviewed by hand against all three books' tables of contents (2026-11-16).
# INTRO for Bulugh = the hadith of the kitab before its first «باب» (Bulugh
# gives Zakat and Fasting few chapters); for al-Rawd = the kitab's first page.
KITABS = [
    ('taharah', 'كتاب الطهارة', 'كتاب الطهارة', 'كتاب الطهارة', [
        ('مدخل', 'miyah', 'المياه', 'باب المياه', 'أنواع المياه'),
        ('باب الآنية', 'aniya', None, 'باب الآنية', 'باب الآنية'),
        ('باب الاستنجاء', 'istinja', None, 'باب قضاء الحاجة', 'باب الاستنجاء'),
        ('باب السواك وسنن الوضوء', 'siwak', None, 'باب الوضوء', 'باب السواك وسنن الوضوء'),
        ('باب فروض الوضوء وصفته', 'wudu', None, 'باب الوضوء', 'باب فروض الوضوء وصفته'),
        ('باب مسح الخفين', 'khuffayn', None, 'باب المسح على الخفين', 'باب مسح الخفين'),
        ('باب نواقض الوضوء', 'nawaqid', None, 'باب نواقض الوضوء', 'باب نواقض الوضوء'),
        ('باب الغسل', 'ghusl', None, 'باب الغسل وحكم الجنب', 'باب الغسل'),
        ('باب التيمم', 'tayammum', None, 'باب التيمم', 'باب التيمم'),
        ('باب إزالة النجاسة', 'najasa', None, 'باب إزالة النجاسة وبيانها', 'باب إزالة النجاسة الحكمية'),
        ('باب الحيض', 'hayd', None, 'باب الحيض', 'باب الحيض'),
    ]),
    ('salah', 'كتاب الصلاة', 'كتاب الصلاة', 'كتاب الصلاة', [
        ('مدخل', 'wujub', 'أول كتاب الصلاة', 'باب المواقيت', INTRO),
        ('باب الأذان والإقامة', 'adhan', None, 'باب الأذان', 'باب الأذان'),
        ('باب شروط الصلاة', 'shurut', None, 'باب شروط الصلاة', 'باب شروط الصلاة'),
        ('باب صفة الصلاة', 'sifa', None, 'باب صفة الصلاة', 'باب صفة الصلاة'),
        ('باب سجود السهو', 'sahw', None, 'باب سجود السهو وغيره', 'باب سجود السهو'),
        ('باب صلاة التطوع', 'tatawwu', None, 'باب صلاة التطوع', 'باب صلاة التطوع وأوقات النهي'),
        ('باب صلاة الجماعة', 'jamaa', None, 'باب صلاة الجماعة والإمامة', 'باب صلاة الجماعة'),
        ('باب صلاة أهل الأعذار', 'aadhar', None, 'باب صلاة المسافر والمريض', 'باب صلاة أهل الأعذار'),
        ('باب صلاة الجمعة', 'jumua', None, 'باب صلاة الجمعة', 'باب صلاة الجمعة'),
        ('باب صلاة العيدين', 'eidayn', None, 'باب صلاة العيدين', 'باب صلاة العيدين'),
        ('باب صلاة الكسوف', 'kusuf', None, 'باب صلاة الكسوف', 'باب صلاة الكسوف'),
        ('باب صلاة الاستسقاء', 'istisqa', None, 'باب صلاة الاستسقاء', 'باب صلاة الاستسقاء'),
    ]),
    ('janaiz', 'كتاب الجنائز', 'كتاب الجنائز', 'كتاب الجنائز', [
        (None, 'janaiz', 'كتاب الجنائز', INTRO, INTRO),
    ]),
    ('zakah', 'كتاب الزكاة', 'كتاب الزكاة', 'كتاب الزكاة', [
        ('مدخل', 'wujub', 'أول كتاب الزكاة', INTRO, INTRO),
        ('باب زكاة بهيمة الأنعام', 'anaam', None, INTRO, 'باب زكاة بهيمة الأنعام'),
        ('باب زكاة الحبوب والثمار', 'hubub', None, INTRO, 'باب زكاة الحبوب والثمار'),
        ('باب زكاة النقدين', 'naqdayn', None, INTRO, 'باب زكاة النقدين'),
        ('باب زكاة العروض', 'urud', None, INTRO, 'باب زكاة العروض'),
        ('باب زكاة الفطر', 'fitr', None, 'باب صدقة الفطر', 'باب زكاة الفطر'),
        ('باب إخراج الزكاة', 'ikhraj', None, INTRO, 'باب إخراج الزكاة'),
        ('باب أهل الزكاة', 'ahl', None, 'باب قسم الصدقات', 'باب أهل الزكاة'),
    ]),
    ('siyam', 'كتاب الصيام', 'كتاب الصيام', 'كتاب الصيام', [
        ('مدخل', 'wujub', 'أول كتاب الصيام', INTRO, INTRO),
        ('باب ما يفسد الصوم ويوجب الكفارة', 'mufsidat', None, INTRO, 'باب ما يفسد الصوم ويوجب الكفارة'),
        ('باب ما يكره ويستحب في الصوم وحكم القضاء', 'qada', None, INTRO, 'باب ما يكره وما يستحب في الصوم وحكم القضاء'),
        ('باب صوم التطوع', 'tatawwu', None, 'باب صوم التطوع وما نهي عن صومه', 'باب صوم التطوع'),
        ('باب الاعتكاف', 'itikaf', None, 'باب الاعتكاف وقيام رمضان', 'باب الاعتكاف'),
    ]),
    ('hajj', 'كتاب المناسك', 'كتاب الحج', 'كتاب المناسك', [
        ('مدخل', 'wujub', 'أول كتاب المناسك', 'باب فضله وبيان من فرض عليه', INTRO),
        ('باب المواقيت', 'mawaqit', None, 'باب المواقيت', 'باب المواقيت'),
        # Zad leaves this chapter untitled; al-Rawd calls it «باب الإحرام»
        ('باب', 'ihram', 'باب الإحرام', 'باب وجوه الإحرام وصفته', 'باب الإحرام'),
        ('باب محظورات الإحرام', 'mahzurat', None, 'باب الإحرام وما يتعلق به', 'باب الإحرام'),
        ('باب الفدية', 'fidya', None, 'باب الإحرام وما يتعلق به', 'باب الفدية'),
        ('باب جزاء الصيد', 'jaza', None, 'باب الإحرام وما يتعلق به', 'باب جزاء الصيد'),
        ('باب صيد الحرم', 'haram', None, 'باب الإحرام وما يتعلق به', 'باب حكم صيد الحرم'),
        ('باب ذكر دخول مكة', 'dukhul', None, 'باب صفة الحج ودخول مكة', 'باب ذكر دخول مكة وما يتعلق به'),
        ('باب صفة الحج والعمرة', 'sifa', None, 'باب صفة الحج ودخول مكة', 'باب صفة الحج والعمرة'),
        ('باب الفوات والإحصار', 'fawat', None, 'باب الفوات والإحصار', 'باب الفوات والإحصار'),
        ('باب الهدي والأضحية', 'hady', None, 'باب الأضاحي', 'باب الهدي والأضحية والعقيقة'),
    ]),
]

# The matn's own ruling words, highlighted (order matters: negations first).
RULING_WORDS = [
    # negations first: «لم يكره» must not also count as «كره»
    ('لم يكره', 'لا يُكره'), ('لا يكره', 'لا يُكره'), ('لا تكره', 'لا يُكره'),
    ('لا يصح', 'لا يصحّ'), ('لم يصح', 'لا يصحّ'), ('لا تصح', 'لا يصحّ'), ('لم تصح', 'لا يصحّ'),
    ('لا يجزئ', 'لا يُجزئ'), ('لم يجزئ', 'لا يُجزئ'), ('لا تجزئ', 'لا يُجزئ'),
    ('لا يجب', 'لا يجب'), ('لا تجب', 'لا يجب'),
    ('كره', 'يُكره'), ('يكره', 'يُكره'), ('تكره', 'يُكره'),
    ('يسن', 'يُسنّ'), ('تسن', 'يُسنّ'), ('سن ', 'يُسنّ'), ('يستحب', 'يُستحبّ'), ('تستحب', 'يُستحبّ'),
    ('يجب', 'يجب'), ('تجب', 'يجب'), ('وجب', 'يجب'), ('فرض', 'فرض'), ('فروض', 'فرض'),
    ('يحرم', 'يحرم'), ('تحرم', 'يحرم'), ('حرم ', 'يحرم'),
    ('يبطل', 'يبطل'), ('تبطل', 'يبطل'), ('بطل', 'يبطل'),
    ('شرط', 'شرط'), ('يشترط', 'شرط'), ('شروط', 'شرط'),
    ('يجزئ', 'يُجزئ'), ('تجزئ', 'يُجزئ'), ('يباح', 'يُباح'), ('مباح', 'يُباح'),
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


def headings(book):
    return get('book', id=book, include='indexes')['indexes']['headings']


def kitab_bounds(book, kitab):
    """(first page, end page exclusive) of the level-1 «كتاب …» titled exactly [kitab]."""
    hs = headings(book)
    for i, h in enumerate(hs):
        if h['level'] == 1 and bare(h['title']) == bare(kitab):
            end = next((x['page'] for x in hs[i + 1:] if x['level'] == 1), 10 ** 6)
            return h['page'], end
    raise KeyError(f'{book}: no kitab {kitab!r}')


def chapters_in(book, kitab, only_bab=False):
    """[(title, first page, end page exclusive)] of a kitab's level-2 chapters."""
    start, end = kitab_bounds(book, kitab)
    hs = [h for h in headings(book) if h['level'] == 2 and start <= h['page'] < end
          and (not only_bab or h['title'].startswith('باب'))]
    return [(h['title'], h['page'], hs[i + 1]['page'] if i + 1 < len(hs) else end) for i, h in enumerate(hs)]


def bulugh_babs():
    """Every «باب» of Bulugh al-Maram → [(title, first page, end page exclusive)].
    A bab ends at the next «باب» or «كتاب» (Bulugh's per-hadith topic titles are level 2
    too in some kitabs, and must not cut a bab short). A list, not a dict: the same
    title occurs in two kitabs («باب المواقيت» in Salah and in Hajj)."""
    hs = headings(BULUGH)
    cuts = [h for h in hs if h['level'] == 1 or (h['level'] == 2 and h['title'].startswith('باب'))]
    return [(h['title'], h['page'], cuts[i + 1]['page'] if i + 1 < len(cuts) else 10 ** 6)
            for i, h in enumerate(cuts) if h['level'] == 2]


def find_bab(babs, title, kitab_start, kitab_end):
    """The bab [title] inside the kitab if it has one, else the one elsewhere in the book
    (Zad's «الهدي والأضحية» ↔ Bulugh's «باب الأضاحي» in كتاب الأطعمة)."""
    hits = [(s, e) for t, s, e in babs if t == title]
    inside = [(s, e) for s, e in hits if kitab_start <= s < kitab_end]
    if not hits:
        raise KeyError(f'Bulugh has no {title!r}')
    return (inside or hits)[0]


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
        for p in ('', 'و', 'ف'):  # «ويحرم تأخيرها»، «فيجب»
            if (' ' + p + w) in b:
                if label not in found:
                    found.append(label)
                b = b.replace(' ' + p + w, ' ' + '_' * (len(p) + len(w)))  # consumed: «لم يكره» ≠ «كره»
    return found


# ---------------------------------------------------------------- Bulugh: numbered hadith
HADITH_START = re.compile(r'(?m)^\s*([٠-٩]+)(?:\s*و\s*[٠-٩]+)?\s*-\s*')


def bulugh_hadith(pages_text):
    """[{n, text}] from a chapter's page text.

    `text` is Ibn Hajr's words as he wrote them: the hadith and his own
    takhrij/grading together (they interleave — «ولمسلم…», «وصححه…» — so
    they are not split). The library's per-hadith topic titles are not
    taken: they sit in its index without a position per hadith, and they
    are the editor's, not Ibn Hajr's."""
    text = '\n'.join(body(t) for t in pages_text)
    parts = HADITH_START.split(text)  # [pre, num1, text1, num2, text2, ...]
    # How this edition prints its numbers:
    #   «٢٠٣ - …» then «٢٠٣ (أ) [ … ]» — an added hadith under the same number;
    #   «٥٣٥ و٥٣٦ - …» — two numbers on one hadith (HADITH_START takes the first);
    #   a smaller number at a line start is a numbered line inside the current hadith.
    raw = []  # [n, sub letter or None, text]
    for i in range(1, len(parts) - 1, 2):
        n = int(parts[i].translate(AR_DIGITS))
        chunk = parts[i + 1]
        sub = re.match(r'\s*\(([أ-ي])\)\s*', chunk)
        if not raw or n > raw[-1][0]:
            raw.append([n, None, chunk])
        elif n == raw[-1][0] and sub:
            raw.append([n, sub.group(1), chunk[sub.end():]])
        else:
            raw[-1][2] += f'\n{parts[i]} - {chunk}'
    out = []
    for n, sub, chunk in raw:
        chunk = re.sub(r'^\s*و\s*[٠-٩]+\s*-\s*', '', chunk)  # «٥٣٥ - و٥٣٦ - …»: one hadith, two numbers
        chunk = TAG.sub('', chunk)
        chunk = re.sub(r'\(\s*[٠-٩]+\s*\)', '', chunk)   # (١) → the editor's footnote ref
        chunk = re.sub(r'\s+', ' ', chunk).strip()
        h = {'n': n, 'text': chunk}
        if sub:
            h['sub'] = sub
        out.append(h)
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


SOURCES = {
    'zad': {'turath_id': ZAD, 'title': 'زاد المستقنع في اختصار المقنع', 'author': 'شرف الدين الحجاوي (ت 968هـ)'},
    'rawd': {'turath_id': RAWD, 'title': 'الروض المربع شرح زاد المستقنع', 'author': 'منصور البهوتي (ت 1051هـ)'},
    'bulugh': {'turath_id': BULUGH, 'title': 'بلوغ المرام من أدلة الأحكام', 'author': 'ابن حجر العسقلاني (ت 852هـ)',
               'numbering': 'ترقيم طبعة الزهيري (دار الفلق) كما في مكتبة تراث'},
}


def zad_rulings(start, end, titles):
    lines = []
    for pg in range(start, end):
        for kind, val in zad_lines(get('page', book_id=ZAD, pg=pg)['text'], titles):
            if kind != 'text':
                continue
            # a ruling the print split across two pages («…أو رفع بقليله / حدث…»):
            # a line that doesn't end in a stop continues on the next line
            if lines and not re.search(r'[.:؛؟!]$', lines[-1]):
                lines[-1] = lines[-1] + ' ' + val
            else:
                lines.append(val)
    return lines


def build_kitab(key, zad_kitab, bulugh_kitab, rawd_kitab, table, babs):
    zstart, zend = kitab_bounds(ZAD, zad_kitab)
    zch = chapters_in(ZAD, zad_kitab) or [(None, zstart, zend)]  # a kitab with no chapters is one chapter
    assert [t for t, *_ in zch] == [row[0] for row in table], (zad_kitab, [t for t, *_ in zch])
    titles = {bare(t) for t, *_ in zch if t} | {'مدخل', bare(zad_kitab)}

    rawd_start, _ = kitab_bounds(RAWD, rawd_kitab)
    rawd_pages = {t: p for t, p, _ in chapters_in(RAWD, rawd_kitab)}
    bstart, bend = kitab_bounds(BULUGH, bulugh_kitab)
    first_bab = min([p for _, p, _ in babs if bstart <= p < bend] or [bend])
    intro_key = f'{bulugh_kitab}: أوله'

    hadith_by = {}

    def hadith_for(btitle):
        k = intro_key if btitle is INTRO else btitle
        if k not in hadith_by:
            s, e = (bstart, first_bab) if btitle is INTRO else find_bab(babs, btitle, bstart, bend)
            hadith_by[k] = bulugh_hadith([get('page', book_id=BULUGH, pg=p)['text'] for p in range(s, e)])
        return k

    chapters = []
    for (ztitle, start, end), (_, cid, label, btitle, rtitle) in zip(zch, table):
        rulings = zad_rulings(start, end, titles)
        rpage = rawd_start if rtitle is INTRO else rawd_pages[rtitle]
        rname = rawd_kitab if rtitle is INTRO else rtitle
        bkey = hadith_for(btitle)
        chapters.append({
            'id': f'zad.{key}.{cid}',
            'title': label or ztitle,
            'masail': [{'id': f'zad.{key}.{cid}.{i + 1}', 'text': l, 'ruling': ruling_words(l)} for i, l in enumerate(rulings)],
            'sharh': {'source': 'rawd', 'chapter': rname, 'page': rpage,
                      'excerpt': rawd_excerpt(get('page', book_id=RAWD, pg=rpage)['text'], rname)},
            'evidence': {'source': 'bulugh', 'chapter': bkey},
        })
    return {'version': 1, 'id': f'zad.{key}', 'title': zad_kitab, 'sources': SOURCES,
            'chapters': chapters, 'bulugh': hadith_by}


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    babs = bulugh_babs()
    index = []
    for key, zad_kitab, bulugh_kitab, rawd_kitab, table in KITABS:
        data = build_kitab(key, zad_kitab, bulugh_kitab, rawd_kitab, table, babs)
        out = OUT_DIR / f'zad_{key}.json'
        out.write_text(json.dumps(data, ensure_ascii=False, indent=0), encoding='utf-8')
        nm = sum(len(c['masail']) for c in data['chapters'])
        nums = sorted(h['n'] for hs in data['bulugh'].values() for h in hs)
        index.append({'id': data['id'], 'title': zad_kitab, 'asset': f'assets/knowledge_trees/zad_{key}.json',
                      'chapters': len(data['chapters']), 'masail': nm, 'hadith': len(nums)})
        print(f'{zad_kitab}: {len(data["chapters"])} chapters, {nm} rulings, {len(nums)} hadith '
              f'(#{nums[0] if nums else "-"}–{nums[-1] if nums else "-"}) → {out.name} ({out.stat().st_size // 1024} KB)')
        for c in data['chapters']:
            n = len(data['bulugh'][c['evidence']['chapter']])
            print(f"    {c['title'][:32]:32s} {len(c['masail']):3d} rulings  ← «{c['evidence']['chapter']}» ({n})")
    (OUT_DIR / 'index.json').write_text(json.dumps({'version': 1, 'trees': index}, ensure_ascii=False, indent=1), encoding='utf-8')


if __name__ == '__main__':
    main()
