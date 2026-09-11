# Source research for «الأدب عنوان السعادة» — Section 5 (آداب المعاشرة
# والمجالسة والمحادثة، pp.19-28).
import json, urllib.parse, urllib.request, os, time

OUT = 'docs/akhlaq/adab_book/_raw'
os.makedirs(OUT, exist_ok=True)

MUSLIM = 1727
BUKHARI = 735
TIRMIDHI = 1363
IBN_MAJAH = 1198
ABU_DAWUD = 117359
ADAB_MUFRAD = 12991
AHMAD = 25794
NASAI_KUBRA = 8361
SHUAB_IMAN = 10660
JAMI_MAMAR = 5610
KHATIB_ADAB_RAWI = 13012

QUERIES = [
    ('s5_yahqiru_akhah',    'بحسب امرئ من الشر أن يحقر أخاه المسلم', MUSLIM),
    ('s5_yajlis_haythu',    'كنا إذا أتينا النبي جلس أحدنا حيث ينتهي', TIRMIDHI),
    ('s5_yajlis_haythu_ad', 'جلس أحدنا حيث ينتهي', ABU_DAWUD),
    ('s5_qama_lah_rajul',   'إذا قام له رجل من المجلس لم يجلس', MUSLIM),
    ('s5_manistamaa',       'من استمع إلى قوم وهم كارهون له أو يفرون منه', BUKHARI),
    ('s5_tajashshaa',       'أن رجلا تجشأ بحضرة النبي فقال كف عنا جشاءك', TIRMIDHI),
    ('s5_kadhib_yudhik',    'ويل لمن يحدث فيكذب ليضحك به القوم', ABU_DAWUD),
    ('s5_kadhib_yudhik_tm', 'يتكلم بالكلمة يضحك بها الناس', TIRMIDHI),
    ('s5_kathrat_dhik',     'كثرة الضحك تميت القلب', TIRMIDHI),
    ('s5_la_yakhudh_mataa', 'لا يأخذ أحدكم متاع صاحبه لا لاعبا ولا جادا', ABU_DAWUD),
    ('s5_la_yakhudh_mataa_tm', 'لا يأخذن أحدكم متاع أخيه لاعبا', TIRMIDHI),
    ('s5_tabassumuka',      'تبسمك في وجه أخيك صدقة', TIRMIDHI),
    ('s5_la_tahqiranna',    'لا تحقرن من المعروف شيئا ولو أن تلقى أخاك بوجه طلق', MUSLIM),
    ('s5_lam_yarham_saghir','من لم يرحم صغيرنا ويجل كبيرنا فليس منا', ADAB_MUFRAD),
    ('s5_laysa_minna',      'ليس منا من لم يرحم صغيرنا ويوقر كبيرنا', TIRMIDHI),
    ('s5_ijlal_dhi_shayba', 'إن من إجلال الله إكرام ذي الشيبة المسلم', ABU_DAWUD),
    ('s5_tawus_arbaa',      'إن من السنة أن يوقر أربعة العالم وذو الشيبة والسلطان والوالد', JAMI_MAMAR),
    ('s5_tanzil_manazil',   'أمرني ربي بمداراة الناس كما أمرني بأداء الفرائض', None),
    ('s5_manazilahum',      'أنزلوا الناس منازلهم', ABU_DAWUD),
]

def get(url):
    req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'curl/8.4.0'})
    with urllib.request.urlopen(req, timeout=45) as r:
        return json.loads(r.read().decode('utf-8'))

for label, q, bid in QUERIES:
    params = {'q': q, 'ver': '3'}
    if bid:
        params['book_id'] = str(bid)
    url = 'https://api.turath.io/search?' + urllib.parse.urlencode(params)
    for attempt in range(3):
        try:
            d = get(url)
            data = d.get('data', [])
            rows = []
            for r in data[:6]:
                rows.append({'book_id': r.get('book_id'), 'page': r.get('page'),
                             'text': (r.get('text') or r.get('content') or '')[:400]})
            json.dump({'q': q, 'book_id': bid, 'rows': rows},
                       open(f'{OUT}/{label}.json', 'w', encoding='utf-8'),
                       ensure_ascii=False, indent=1)
            print(label, '->', len(rows), 'rows')
            break
        except Exception as e:
            print(label, 'attempt', attempt, 'FAILED', e)
            time.sleep(3)
