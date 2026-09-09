# One-shot: real Turath API research for الرفق. Saves raw JSON per query.
import json, time, urllib.parse, urllib.request, os

OUT = 'docs/akhlaq/alrifq/_raw'
os.makedirs(OUT, exist_ok=True)

def get(url):
    req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'curl/8.4.0'})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode('utf-8'))

QUERIES = [
    # (label, q, book_id or None)
    ('muslim_rifq',            'الرفق',                       1727),
    ('muslim_yassiru',         'يسروا ولا تعسروا',            1727),
    ('bukhari_rifq',           'الرفق',                       735),
    ('bukhari_yassiru',        'يسروا ولا تعسروا',            735),
    ('bukhari_daooh',          'دعوه وأريقوا',                735),
    ('riyad_rifq',             'الرفق',                       12014),
    ('adabmufrad_rifq',        'الرفق',                       9647),
    ('sahih_adabmufrad_rifq',  'الرفق',                       1341),
    ('abudawud_rifq',          'الرفق',                       117359),
    ('tirmidhi_rifq',          'الرفق',                       7895),
    ('jamiulum_rifq',          'الرفق',                       4268),
    ('muawiya_hakam',          'فما كهرني ولا ضربني',         None),
    ('rifq_bayt',              'إذا أراد الله بأهل بيت',       None),
    ('rifq_hazzah',            'من أعطي حظه من الرفق',         None),
    ('sam_alaykum_aisha',      'عليك بالرفق وإياك والعنف',     None),
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
        for r in data[:12]:
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
                'vol': meta.get('vol'),
                'page': meta.get('page'),
                'headings': meta.get('headings'),
                'text': (r.get('text') or '')[:1600],
            })
        out = {'query': q, 'book_id': bid, 'count': d.get('count'), 'rows': rows}
        open(f'{OUT}/{label}.json', 'w', encoding='utf-8').write(
            json.dumps(out, ensure_ascii=False, indent=1))
        print(f'{label:24s} count={d.get("count"):>8}  saved {len(rows)} rows')
    except Exception as e:
        print(f'{label:24s} ERROR {e}')
    time.sleep(0.5)
