# Source research for «الأدب عنوان السعادة» (صالح بن عبد العزيز سندي).
# Section 1: مقدمة + فضل الأدب وحسن الخلق (pp.5-14). Saves raw Turath JSON
# per query so evidence entries are grounded, not guessed.
import json, urllib.parse, urllib.request, os

OUT = 'docs/akhlaq/adab_book/_raw'
os.makedirs(OUT, exist_ok=True)

def get(url):
    req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'curl/8.4.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode('utf-8'))

# book ids confirmed against assets/turath/catalog-v3.json.gz
MUSLIM = 1727
BUKHARI = 735
TIRMIDHI = 1363          # ط الرسالة (booklet cites 4/xxx — matches this edition's vols)
IBN_MAJAH = 1198         # ت عبد الباقي (booklet cites 1/19 — matches classic numbering)
ABU_DAWUD = 117359       # ت الأرنؤوط
ADAB_MUFRAD = 12991      # ت عبد الباقي (booklet cites "ص273" page numbering)
AHMAD = 25794            # مسند أحمد ط الرسالة
BAYHAQI_KUBRA = 148486   # السنن الكبرى ت التركي
KHATIB_ADAB_RAWI = 13012 # الجامع لأخلاق الراوي وآداب السامع

QUERIES = [
    ('s1_atmimu_salih',   'إنما بعثت لأتمم صالح الأخلاق', AHMAD),
    ('s1_atmimu_salih_am', 'لأتمم صالح الأخلاق', ADAB_MUFRAD),
    ('s1_atmimu_makarim', 'إنما بعثت لأتمم مكارم الأخلاق', BAYHAQI_KUBRA),
    ('s1_dua_ahdini',      'اهدني لأحسن الأخلاق لا يهدي لأحسنها إلا أنت', MUSLIM),
    ('s1_ahsan_alnnas',    'كان رسول الله أحسن الناس خلقا', BUKHARI),
    ('s1_ahsan_alnnas_m',  'كان رسول الله أحسن الناس خلقا', MUSLIM),
    ('s1_ahabbukum_ilayya','أحبكم إلي وأقربكم مني مجلسا يوم القيامة أحاسنكم أخلاقا', TIRMIDHI),
    ('s1_akmal_muminin',   'أكمل المؤمنين إيمانا أحسنهم خلقا', TIRMIDHI),
    ('s1_akmal_muminin_ad','أكمل المؤمنين إيمانا أحسنهم خلقا', ABU_DAWUD),
    ('s1_khiyarukum',      'من خياركم أحاسنكم أخلاقا', BUKHARI),
    ('s1_khiyarukum_m',    'من خياركم أحاسنكم أخلاقا', MUSLIM),
    ('s1_albirru',         'البر حسن الخلق', MUSLIM),
    ('s1_yudriku_bihusni', 'إن المؤمن ليدرك بحسن خلقه درجة الصائم القائم', ABU_DAWUD),
    ('s1_athqal_shay',     'ما من شيء أثقل في ميزان العبد يوم القيامة من حسن الخلق', TIRMIDHI),
    ('s1_athqal_shay_ad',  'أثقل في ميزان المؤمن يوم القيامة من خلق حسن', ABU_DAWUD),
    ('s1_taqwa_husn',      'أكثر ما يدخل الناس الجنة تقوى الله وحسن الخلق', TIRMIDHI),
    ('s1_zaim_baytin',     'أنا زعيم ببيت في ربض الجنة لمن ترك المراء', ABU_DAWUD),
    ('s1_zaim_baytin_tm',  'زعيم ببيت في ربض الجنة لمن ترك المراء', TIRMIDHI),
    ('s1_zaim_baytin_im',  'ترك المراء وهو محق', IBN_MAJAH),
    ('s1_ibnmubarak_adab', 'نحن إلى كثير من الأدب أحوج منا إلى كثير من الحديث', KHATIB_ADAB_RAWI),
]

for label, q, bid in QUERIES:
    params = {'q': q, 'ver': '3'}
    if bid:
        params['book_id'] = str(bid)
    url = 'https://api.turath.io/search?' + urllib.parse.urlencode(params)
    try:
        d = get(url)
        data = d.get('data', [])
        rows = []
        for r in data[:8]:
            meta = r.get('meta')
            if isinstance(meta, str):
                try:
                    meta = json.loads(meta)
                except Exception:
                    meta = {}
            rows.append({
                'book_id': r.get('book_id'),
                'book_name': meta.get('book_name'),
                'author': meta.get('author_name'),
                'page': r.get('page'),
                'part': r.get('part'),
                'text': r.get('text') or r.get('content'),
                'headings': r.get('headings'),
            })
        json.dump({'q': q, 'book_id': bid, 'rows': rows},
                   open(f'{OUT}/{label}.json', 'w', encoding='utf-8'),
                   ensure_ascii=False, indent=1)
        print(label, '->', len(rows), 'rows')
    except Exception as e:
        print(label, 'FAILED', e)
