# Real scan of the bundled Turath catalog for adab/akhlaq source material.
# Output: docs/akhlaq/AKHLAQ_SOURCE_SCAN.md  (facts, not guesses)
import gzip, json, io, re, collections

CAT = 'assets/turath/catalog-v3.json.gz'
OUT = 'docs/akhlaq/AKHLAQ_SOURCE_SCAN.md'

raw = gzip.decompress(open(CAT, 'rb').read())
doc = json.loads(raw)

cats = doc.get('cats') or doc.get('categories') or {}
books = doc.get('books') or {}
authors = doc.get('authors') or {}

# normalise: cats can be dict{ id: {...} } or list[ {...} ]
def as_items(x):
    if isinstance(x, dict):
        return list(x.items())
    return [(str(i.get('id', n)), i) for n, i in enumerate(x)]

cat_items = as_items(cats)

def bname(bid):
    b = books.get(str(bid)) or {}
    return b.get('name') or b.get('title') or f'#{bid}'

def bauthor(bid):
    b = books.get(str(bid)) or {}
    aid = b.get('author_id') or b.get('author')
    a = authors.get(str(aid)) if aid is not None else None
    if isinstance(a, dict):
        return a.get('name') or a.get('death') or str(aid)
    return str(aid) if aid is not None else '?'

def bpages(bid):
    b = books.get(str(bid)) or {}
    for k in ('pages', 'page_count', 'pdf_pages', 'npages'):
        if b.get(k):
            return b[k]
    return ''

L = []
L.append('# مسح مصادر الأدب والأخلاق — فحص فعلي للفهرس المبذول (Turath)\n')
L.append('> ليس تقديرًا. هذا فحص فعلي لملف `assets/turath/catalog-v3.json.gz`')
L.append('> (نسخة turath.io الرسمية المبذولة في التطبيق). الأرقام مستخرَجة برمجيًّا.\n')
L.append(f'- إجمالي التصنيفات في الفهرس: **{len(cat_items)}**')
L.append(f'- إجمالي الكتب في الفهرس: **{len(books)}**')
L.append(f'- إجمالي المؤلّفين: **{len(authors)}**\n')

L.append('## 1. كل التصنيفات (id · الاسم · عدد الكتب)\n')
rows = []
for cid, c in cat_items:
    nm = c.get('name') or c.get('title') or ''
    bl = c.get('books') or c.get('book_ids') or []
    rows.append((int(len(bl)), cid, nm))
for n, cid, nm in sorted(rows, reverse=True):
    L.append(f'- `{cid}` — {nm} — **{n}** كتاب')

# categories whose NAME matches adab/akhlaq themes
theme_cat = re.compile(r'الأدب|آداب|أخلاق|الخلق|رقائق|الزهد|تزكية|السلوك|مواعظ|السيرة|التراجم|شمائل|الأذكار')
L.append('\n## 2. التصنيفات ذات الصلة بالأدب/الأخلاق (بالاسم)\n')
rel_cats = [(cid, c) for cid, c in cat_items
            if theme_cat.search((c.get('name') or c.get('title') or ''))]
if not rel_cats:
    L.append('_لا تصنيف اسمه صريح في الأدب/الأخلاق — نعتمد على بحث العناوين (§3)._')
for cid, c in rel_cats:
    nm = c.get('name') or ''
    bl = c.get('books') or c.get('book_ids') or []
    L.append(f'\n### `{cid}` — {nm} — {len(bl)} كتاب\n')
    for bid in bl[:40]:
        L.append(f'- {bname(bid)} — {bauthor(bid)} — id `{bid}`'
                 + (f' — {bpages(bid)} ص' if bpages(bid) else ''))
    if len(bl) > 120:
        L.append(f'- … و{len(bl)-40} كتابًا آخر في هذا التصنيف')

# keyword scan across ALL book titles
kw = {
  'أدب/آداب': re.compile(r'الأدب|آداب|أدب '),
  'أخلاق/خُلُق': re.compile(r'الأخلاق|أخلاق|الخُلُق|الخلق|مكارم'),
  'الزهد': re.compile(r'الزهد|زهد'),
  'الرقائق': re.compile(r'الرقائق|رقائق|الرقاق'),
  'تزكية/النفس/السلوك': re.compile(r'تزكية|النفوس|النفس|مجاهدة|محاسبة النفس|أمراض القلوب|القلوب'),
  'الشمائل/السيرة': re.compile(r'الشمائل|شمائل|السيرة النبوية|أخلاق النبي|هدي'),
  'أدب الطلب/العالم': re.compile(r'طالب العلم|المتعلّم|المتعلم|العالم والمتعلم|حلية|جامع بيان العلم|اقتضاء العلم'),
  'المجالس/الصحبة/العشرة': re.compile(r'المجالس|مجالسة|الصحبة|الإخوان|العشرة|المعاشرة|جليس'),
}
hit = collections.defaultdict(list)
for bid, b in books.items():
    nm = b.get('name') or b.get('title') or ''
    for label, rx in kw.items():
        if rx.search(nm):
            hit[label].append((nm, bauthor(bid), bid, bpages(bid)))

L.append('\n## 3. مسح عناوين كل الكتب بالكلمات المفتاحية\n')
total_unique = set()
for label, rx in kw.items():
    lst = sorted(set(hit[label]))
    for _, _, bid, _ in lst:
        total_unique.add(bid)
    L.append(f'\n### {label} — {len(lst)} عنوانًا\n')
    for nm, au, bid, pg in lst[:100]:
        L.append(f'- {nm} — {au} — id `{bid}`' + (f' — {pg} ص' if pg else ''))
    if len(lst) > 80:
        L.append(f'- … و{len(lst)-100} عنوانًا آخر')

L.append(f'\n## 4. الخلاصة\n')
L.append(f'- كتب فريدة لامست إحدى كلمات الأدب/الأخلاق في عنوانها: **{len(total_unique)}**')
L.append(f'- هذه قائمة **مرشّحة**، لم تُفحَص بعدُ طبعةً وتحقيقًا وترخيصَ اقتباس (بوّابة `AKHLAQ_SOURCES §6`).')
L.append(f'- الخطوة التالية: اختيار ~15–25 كتابًا أساسيًّا من هذه القائمة، وفحص كلٍّ فعليًّا عبر `/book?id=` و`/page`.')

open(OUT, 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
print(f'wrote {OUT}')
print(f'cats={len(cat_items)} books={len(books)} authors={len(authors)} unique_akhlaq_titles={len(total_unique)}')
