# Resolve the remaining "لم يُستعلَم" items from P1 and P3.
import json, urllib.parse, urllib.request, os, time

OUT = 'docs/akhlaq/adab_book/_raw'
os.makedirs(OUT, exist_ok=True)

MUSLIM = 1727
BUKHARI = 735
TIRMIDHI = 1363
IBN_MAJAH = 1198
ABU_DAWUD = 117359
ADAB_MUFRAD = 12991
SHUAB_IMAN = 10660
KHATIB_ADAB_RAWI = 13012

QUERIES = [
    # EV-AB-04: كان رسول الله أحسن الناس خلقا (Bukhari)
    ('r_ahsan_alnnas_bukhari', 'أحسن الناس خلقا', BUKHARI),
    # EV-AB-06 Tirmidhi side: أكمل المؤمنين من حديث أبي هريرة (حق المرأة) / عائشة
    ('r_akmal_muminin_aisha', 'أكمل المؤمنين إيمانا أحسنهم خلقا وخياركم لنسائهم', TIRMIDHI),
    # EV-AB-10 exact: ما من شيء أثقل في ميزان المؤمن يوم القيامة من خلق حسن (Tirmidhi)
    ('r_athqal_mizan_tm', 'ما من شيء أثقل في ميزان المؤمن يوم القيامة من خلق حسن', TIRMIDHI),
    ('r_athqal_mizan_ad', 'أثقل في ميزان المؤمن يوم القيامة من خلق حسن', ABU_DAWUD),
    # EV-AB-11: سئل عن أكثر ما يدخل الناس الجنة فقال تقوى الله وحسن الخلق (already got a hit before, retry direct)
    ('r_taqwa_husn_v3', 'سئل رسول الله عن أكثر ما يدخل الناس الجنة فقال تقوى الله وحسن الخلق', TIRMIDHI),
    # EV-AB-13: ibn Sirin / Ibrahim b. Habib
    ('r_ibnsirin_hady', 'كانوا يتعلمون الهدي كما يتعلمون العلم', KHATIB_ADAB_RAWI),
    ('r_ibrahim_habib', 'ائت الفقهاء والعلماء وتعلم منهم وخذ من أدبهم وأخلاقهم', KHATIB_ADAB_RAWI),
    # EV-AB-18: Ata' b. Abi Rabah via Shuab al-Iman
    ('r_ataa_yuhadithuni', 'الشاب ليحدثني بحديث فأستمع إليه كأني لم أسمعه', SHUAB_IMAN),
    # EV-AB-21: Ibn 'Umar - لم يجلس في هذا المجلس (Muslim)
    ('r_ibnumar_majlis', 'قام له رجل من مجلسه لم يجلس فيه', MUSLIM),
    # EV-AB-23: tajashshu' hadith (Tirmidhi)
    ('r_tajashshaa_v2', 'تجشأ رجل عند النبي فقال كف عنا جشاءك', TIRMIDHI),
    # EV-AB-25: كثرة الضحك تميت القلب
    ('r_kathrat_dahik_v2', 'كثرة الضحك تميت القلب', TIRMIDHI),
    ('r_kathrat_dahik_im', 'كثرة الضحك تميت القلب', IBN_MAJAH),
    # EV-AB-27: لا يأخذ أحدكم متاع أخيه لاعبا ولا جادا
    ('r_la_yakhudh_v2', 'لا يأخذن أحدكم متاع أخيه لاعبا ولا جادا', ABU_DAWUD),
    ('r_la_yakhudh_v3', 'لا يأخذن أحدكم متاع أخيه لاعبا ولا جادا', TIRMIDHI),
    # EV-AB-28: تبسمك في وجه أخيك لك صدقة
    ('r_tabassum_v3', 'تبسمك في وجه أخيك لك صدقة', TIRMIDHI),
]

def get(url):
    req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'curl/8.4.0'})
    with urllib.request.urlopen(req, timeout=50) as r:
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
            for r in data[:5]:
                rows.append({'page': r.get('page'), 'text': (r.get('text') or r.get('content') or '')[:450]})
            json.dump({'q': q, 'book_id': bid, 'rows': rows},
                       open(f'{OUT}/{label}.json', 'w', encoding='utf-8'),
                       ensure_ascii=False, indent=1)
            print(label, '->', len(rows), 'rows')
            break
        except Exception as e:
            print(label, 'attempt', attempt, 'FAILED', e)
            time.sleep(3)
