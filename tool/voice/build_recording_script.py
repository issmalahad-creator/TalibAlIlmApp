"""The recording script for Ismail's reading voice — "every Arabic Islamic
book, fluently, with the fewest sentences".

    python tool/voice/build_recording_script.py [--count 1000] [--studio D:/_wt/piper-recording-studio]

Writes
  docs/audio-reader/voice_script_ar.tsv          id<TAB>genre<TAB>text, in recording order
  docs/audio-reader/VOICE_SCRIPT_REPORT.md       coverage numbers per milestone
  <studio>/prompts/Arabic (Talib books voice)_ar-SA-talib/6000000001_<last>_Script.txt
                                                 (only with --studio; what the studio shows)

How the sentences are chosen (docs/audio-reader/MY_VOICE_PLAN_2026-11-13.md §9):
  * Pool = the Islamic books already in the app, one or more per genre
    (tafsir, hadith, fiqh/sira, aqeedah, tazkiya, akhlaq, adhkar), plus a
    short hand-written set (numbers, dates, honorifics, headings, questions)
    that books need and the pool lacks.
  * No Quran: anything in ﴿﴾ or {} is dropped, and so is any sentence that
    shares five consecutive words with an ayah (the Quran is read in the app
    by real reciters, never by this voice).
  * Greedy cover, ordered: each next sentence is the one adding the most
    still-needed sound units (approximate phoneme pairs; vowel units only
    where the text is voweled), common-in-books units first, per second of
    reading, with soft genre quotas. Stopping anywhere = the best script of
    that length.
  * Voweled sentences are preferred (the transcript then says exactly what
    was read). Double quotes are replaced by « » (the studio reads TSV with
    Python's csv module, where " would swallow text).
"""
import argparse
import collections
import glob
import gzip
import heapq
import json
import math
import os
import random
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
A = os.path.join(ROOT, 'assets')

MARKS = re.compile('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]')
AR_LETTER = re.compile('[\u0621-\u064A\u0671]')
HARAKA = re.compile('[\u064B-\u0652]')

# ---------------------------------------------------------------- the hand-written set
# Fully voweled; neutral book prose (no hadith wording or chains are invented,
# no Quran). Real hadith, isnad and tafsir prose comes from the books below.
SPECIAL = [
    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
    'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ، وَالصَّلَاةُ وَالسَّلَامُ عَلَى نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ.',
    'أَمَّا بَعْدُ: فَهَذِهِ رِسَالَةٌ مُخْتَصَرَةٌ فِي بَيَانِ أَحْكَامِ الصِّيَامِ.',
    'الْفَصْلُ الْأَوَّلُ: فِي فَضْلِ الْعِلْمِ وَأَهْلِهِ.',
    'الْبَابُ الْعَاشِرُ: فِي أَحْكَامِ الطَّهَارَةِ.',
    'الْمَسْأَلَةُ الثَّالِثَةُ: إِذَا نَسِيَ الْمُصَلِّي سَجْدَةً، فَمَاذَا يَفْعَلُ؟',
    'فَإِنْ قِيلَ: لِمَاذَا قَدَّمَ هَذَا عَلَى ذَاكَ؟ قُلْنَا: لِأَنَّهُ أَهَمُّ.',
    'هَلْ تَعْلَمُ أَنَّ طَلَبَ الْعِلْمِ عِبَادَةٌ؟',
    'يَا لَهُ مِنْ فَضْلٍ عَظِيمٍ!',
    'سُبْحَانَ اللَّهِ! مَا أَعْظَمَ هَذِهِ النِّعْمَةَ!',
    'قَالَ الْمُصَنِّفُ رَحِمَهُ اللَّهُ تَعَالَى: وَهَذَا أَصْلٌ عَظِيمٌ مِنْ أُصُولِ الدِّينِ.',
    'وَاخْتَلَفَ الْعُلَمَاءُ فِي هَذِهِ الْمَسْأَلَةِ عَلَى ثَلَاثَةِ أَقْوَالٍ.',
    'الْقَوْلُ الْأَوَّلُ: الْوُجُوبُ، وَالثَّانِي: الِاسْتِحْبَابُ، وَالثَّالِثُ: الْإِبَاحَةُ.',
    'وَالرَّاجِحُ - وَاللَّهُ أَعْلَمُ - هُوَ الْقَوْلُ الثَّانِي.',
    'قَالَ شَيْخُ الْإِسْلَامِ ابْنُ تَيْمِيَّةَ رَحِمَهُ اللَّهُ فِي هَذَا الْمَوْضِعِ كَلَامًا نَفِيسًا.',
    'النَّبِيُّ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ، وَالصَّحَابَةُ رَضِيَ اللَّهُ عَنْهُمْ، وَالتَّابِعُونَ رَحِمَهُمُ اللَّهُ.',
    'قَالَ اللَّهُ عَزَّ وَجَلَّ، وَقَالَ سُبْحَانَهُ وَتَعَالَى، وَقَالَ جَلَّ جَلَالُهُ.',
    'عَلَيْهِ الصَّلَاةُ وَالسَّلَامُ، وَعَلَيْهِ السَّلَامُ، وَرَضِيَ اللَّهُ عَنْهَا.',
    'انْتَهَى كَلَامُهُ رَحِمَهُ اللَّهُ.',
    'يُنْظَرُ: الْمُغْنِي لِابْنِ قُدَامَةَ، وَالْمَجْمُوعُ لِلنَّوَوِيِّ.',
    'أَخْرَجَهُ الْبُخَارِيُّ فِي صَحِيحِهِ، فِي كِتَابِ الْإِيمَانِ.',
    'وَفِي إِسْنَادِهِ ضَعْفٌ، لَكِنْ لَهُ شَوَاهِدُ يَتَقَوَّى بِهَا.',
    'قُلْتُ: وَهَذَا مِنْ أَحْسَنِ مَا قِيلَ فِي هَذَا الْبَابِ.',
    'أَبُو هُرَيْرَةَ، وَعَائِشَةُ، وَعَبْدُ اللَّهِ بْنُ عَبَّاسٍ، وَأَنَسُ بْنُ مَالِكٍ رَضِيَ اللَّهُ عَنْهُمْ.',
    'الْأَئِمَّةُ الْأَرْبَعَةُ: أَبُو حَنِيفَةَ، وَمَالِكٌ، وَالشَّافِعِيُّ، وَأَحْمَدُ بْنُ حَنْبَلٍ.',
    'تُوُفِّيَ ابْنُ الْقَيِّمِ سَنَةَ إِحْدَى وَخَمْسِينَ وَسَبْعِمِائَةٍ لِلْهِجْرَةِ.',
    'يَقَعُ الْكِتَابُ فِي خَمْسَةِ مُجَلَّدَاتٍ، وَفِيهِ ثَلَاثُمِائَةٍ وَعِشْرُونَ بَابًا.',
    'الْجُزْءُ الثَّانِي، الصَّفْحَةُ الْخَامِسَةُ وَالْعِشْرُونَ بَعْدَ الْمِائَةِ.',
    'صَلَاةُ الظُّهْرِ أَرْبَعُ رَكَعَاتٍ، وَالْمَغْرِبُ ثَلَاثٌ، وَالْفَجْرُ رَكْعَتَانِ.',
    'فِي الْيَوْمِ السَّابِعِ وَالْعِشْرِينَ مِنْ شَهْرِ رَمَضَانَ.',
    'أَوَّلًا، ثَانِيًا، ثَالِثًا، رَابِعًا، خَامِسًا، سَادِسًا، سَابِعًا.',
    'وَاحِدٌ، اثْنَانِ، ثَلَاثَةٌ، أَرْبَعَةٌ، خَمْسَةٌ، سِتَّةٌ، سَبْعَةٌ، ثَمَانِيَةٌ، تِسْعَةٌ، عَشَرَةٌ.',
    'أَحَدَ عَشَرَ، وَاثْنَا عَشَرَ، وَعِشْرُونَ، وَمِائَةٌ، وَأَلْفٌ، وَأَلْفَانِ، وَمِائَةُ أَلْفٍ.',
    'مُحَرَّمٌ، وَصَفَرٌ، وَرَبِيعٌ الْأَوَّلُ، وَرَبِيعٌ الْآخِرُ، وَجُمَادَى الْأُولَى، وَجُمَادَى الْآخِرَةُ.',
    'رَجَبٌ، وَشَعْبَانُ، وَرَمَضَانُ، وَشَوَّالٌ، وَذُو الْقَعْدَةِ، وَذُو الْحِجَّةِ.',
    'وَصَلَّى اللَّهُ وَسَلَّمَ عَلَى نَبِيِّنَا مُحَمَّدٍ، وَآخِرُ دَعْوَانَا أَنِ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ.',
]

# genre → (sources, target share of the script)
GENRES = {
    'tafsir': 0.20, 'hadith': 0.15, 'fiqh_sira': 0.15, 'aqeedah': 0.06,
    'tazkiya': 0.20, 'akhlaq': 0.10, 'adhkar': 0.06, 'special': 0.04,
}


def walk(o):
    if isinstance(o, str):
        yield o
    elif isinstance(o, dict):
        for v in o.values():
            yield from walk(v)
    elif isinstance(o, list):
        for v in o:
            yield from walk(v)


def jsonl_texts(path):
    with gzip.open(path, 'rt', encoding='utf-8') as f:
        for line in f:
            try:
                for v in json.loads(line).values():
                    if isinstance(v, str) and len(v) > 30:
                        yield v
            except Exception:
                pass


def sources():
    J = lambda p: list(walk(json.load(open(os.path.join(A, p), encoding='utf-8'))))
    yield 'hadith', 'nawawi40', J('hadith/nawawi40.json')
    yield 'aqeedah', 'wasitiyyah', J('aqeedah/wasitiyyah.json')
    yield 'tazkiya', 'madarij', J('aqeedah/madarij_part1.json')
    yield 'fiqh_sira', 'zad', J('fiqh_seerah/zad_almaad_vol1.json')
    yield 'adhkar', 'hisn', J('adhkar/hisn_almuslim.json')
    yield 'akhlaq', 'akhlaq', [s for f in sorted(glob.glob(os.path.join(A, 'akhlaq', '*.gz')))
                               for s in walk(json.load(gzip.open(f, 'rt', encoding='utf-8')))]
    for name in ('muyassar', 'almukhtasar', 'saadi'):
        yield 'tafsir', name, list(jsonl_texts(os.path.join(A, 'quran', f'tafsir-{name}.jsonl.gz')))


def norm(s):
    s = MARKS.sub('', s).replace('\u0640', '')
    for a, b in (('ٱ', 'ا'), ('أ', 'ا'), ('إ', 'ا'), ('آ', 'ا'), ('ى', 'ي'), ('ة', 'ه'), ('ؤ', 'و'), ('ئ', 'ي')):
        s = s.replace(a, b)
    return re.sub('[^\u0621-\u064A ]', ' ', s).split()


def quran_shingles():
    out = set()
    for line in open(os.path.join(A, 'quran', 'quran-uthmani.txt'), encoding='utf-8'):
        p = line.rstrip('\n').split('|', 2)
        if len(p) == 3:
            w = norm(p[2])
            out.update(tuple(w[i:i + 5]) for i in range(len(w) - 4))
    return out


FOOTNOTE = re.compile(r'\(\s*\d+\s*\)|\[\s*\d+\s*\]')
BAD = re.compile(r'[﴿﴾{}\[\]<>&;=_#*/\\|@]|[A-Za-z0-9٠-٩]')


LIGATURES = {'ﷺ': 'صلى الله عليه وسلم', 'ﷻ': 'جل جلاله', '﷽': 'بسم الله الرحمن الرحيم'}
HONORIFIC_MARKS = re.compile('[ؐ-ؔ﵀-﷿]')


def clean_sentences(text):
    text = FOOTNOTE.sub('', text)
    for k, v in LIGATURES.items():
        text = text.replace(k, ' ' + v + ' ')
    text = HONORIFIC_MARKS.sub('', text)
    text = re.sub(r'\s+([،,؛:.!؟])', r'\1', text)
    text = text.replace('"', '«', 1).replace('"', '»', 1) if text.count('"') == 2 else text.replace('"', '')
    text = text.replace('“', '«').replace('”', '»')
    for s in re.split(r'(?<=[.!؟?؛])\s+|\n+', text):
        s = re.sub(r'\s+', ' ', s).strip(' -–—،:')
        if not s or BAD.search(s):
            continue
        if s.count('«') != s.count('»') or s.count('(') != s.count(')'):
            continue
        w = len(s.split())
        if 6 <= w <= 22 and len(s) <= 170:
            if not s.endswith(('.', '؟', '!', '؛', ':')):
                s += '.'
            yield s


# ---------------------------------------------------------------- sound units
SUN = set('تثدذرزسشصضطظلن')
VOW = {'\u064E': 'a', '\u0650': 'i', '\u064F': 'u', '\u064B': 'an', '\u064D': 'in', '\u064C': 'un', '\u0652': '0'}
CONS = {'ء': 'Q', 'أ': 'Q', 'إ': 'Q', 'ؤ': 'Q', 'ئ': 'Q', 'آ': 'Q', 'ة': 't', 'ى': 'A'}


def voweled(s):
    lets = len(AR_LETTER.findall(s))
    return lets > 0 and len(HARAKA.findall(s)) >= 0.6 * lets


def units(s):
    """Approximate phoneme-pair units. Voweled text → consonant+vowel
    tokens (sun-letter lām assimilated, shadda = doubled); otherwise the
    consonant skeleton only (vowels unknown), marked with S:."""
    full = voweled(s)
    toks = []
    for word in s.split():
        w = word.replace('\u0640', '')
        if w.startswith(('ال', 'ٱل')) and len(w) > 3:
            first = MARKS.sub('', w)[2:3]
            w = w[1:] if first in SUN else w  # الشّمس → (a)sh-shams: drop the lām
        prev = None
        for ch in w:
            if AR_LETTER.match(ch):
                c = CONS.get(ch, ch)
                if ch == 'ا' and prev is not None:
                    toks.append('aa'); prev = 'aa'; continue
                if ch == 'ا':
                    toks.append('Q'); prev = 'Q'; continue
                toks.append(c); prev = c
            elif ch == '\u0651' and prev:
                toks.append(prev)  # gemination
            elif full and ch in VOW:
                toks.append(VOW[ch])
        toks.append('|')  # word boundary
    if not full:
        toks = [t for t in toks if t not in VOW.values()]
    pref = '' if full else 'S:'
    us = {pref + a + '_' + b for a, b in zip(toks, toks[1:]) if not (a == '|' and b == '|')}
    if '؟' in s or '?' in s:
        us.add('P:question')
    if '!' in s:
        us.add('P:exclaim')
    if ':' in s:
        us.add('P:colon')
    if s.count('،') >= 3:
        us.add('P:list')
    if '«' in s:
        us.add('P:quote')
    for phrase in ('صلى الله عليه وسلم', 'رضي الله عنه', 'رحمه الله', 'تعالى', 'عز وجل', 'حدثنا', 'اخبرنا', 'قال رسول الله'):
        if phrase in ' '.join(norm(s)).replace('ه ', 'ه ') or phrase in MARKS.sub('', s):
            us.add('F:' + phrase)
    return us


def seconds(s):
    return max(2.0, len(s) / 10.0)  # measured: Ismail reads ~10 characters/second


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--count', type=int, default=1000)
    ap.add_argument('--per-source', type=int, default=6000, help='candidates sampled per source (speed)')
    ap.add_argument('--studio', help='piper-recording-studio folder: also write its prompts file')
    a = ap.parse_args()
    random.seed(13)

    qsh = quran_shingles()
    already = set()
    if a.studio:
        for f in glob.glob(os.path.join(a.studio, 'output', '**', '*.txt'), recursive=True):
            already.add(' '.join(norm(open(f, encoding='utf-8').read())))

    all_sources = list(sources())
    wfreq = collections.Counter(w for _, _, texts in all_sources for t in texts for w in norm(t))
    glued = re.compile('^(الي|علي|لا|في|من|عن|ما)[ء-ي]{3,}$')

    def typo(s):
        # source typos where two words were glued («إلىنفس», «لاتنفذ»): a word
        # seen once in all the books that starts with a particle
        return any(wfreq[w] <= 1 and glued.match(w) for w in norm(s))

    cands, seen, dropped_q, dropped_t = [], set(), 0, 0
    for genre, src, texts in all_sources:
        pool = []
        for t in texts:
            for s in clean_sentences(t):
                if typo(s):
                    dropped_t += 1
                    continue
                key = ' '.join(norm(s))
                if key in seen or key in already:
                    continue
                w = key.split()
                if any(tuple(w[i:i + 5]) in qsh for i in range(len(w) - 4)):
                    dropped_q += 1
                    continue
                seen.add(key)
                pool.append(s)
        random.shuffle(pool)
        pool = pool[:a.per_source]
        cands += [(genre, src, s) for s in pool]
        print(f'{genre:10s} {src:12s} {len(pool):6d} candidates')
    cands += [('special', 'hand', s) for s in SPECIAL]
    print(f'dropped {dropped_q} sentences sharing 5+ words with an ayah, {dropped_t} with a glued-word typo')

    U = [units(s) for _, _, s in cands]
    freq = collections.Counter(u for us in U for u in us)
    weight = {u: (2.0 if u.startswith(('P:', 'F:')) else 1.0) * (1 + math.log(1 + c)) for u, c in freq.items()}
    need = {u: (5 if u.startswith(('P:', 'F:')) else 3) for u in freq}

    have = collections.Counter()
    genre_n = collections.Counter()
    chosen = []

    def gain(i):
        g, _, s = cands[i]
        v = sum(weight[u] * min(1, need[u] - have[u]) for u in U[i] if have[u] < need[u])
        if g == 'special':
            v *= 3  # few, hand-picked, and books need them early
        if voweled(s):
            v *= 1.5
        share = genre_n[g] / max(1, len(chosen))
        v *= min(2.0, max(0.25, (GENRES[g] + 0.02) / (share + 0.02))) ** 0.5
        return v / seconds(s)

    heap = [(-gain(i), i) for i in range(len(cands))]
    heapq.heapify(heap)
    taken = set()
    while heap and len(chosen) < a.count:
        neg, i = heapq.heappop(heap)
        if i in taken:
            continue
        g = gain(i)
        if heap and g < -heap[0][0] - 1e-9:
            heapq.heappush(heap, (-g, i))  # stale score: re-queue (lazy greedy)
            continue
        taken.add(i)
        chosen.append(i)
        genre_n[cands[i][0]] += 1
        for u in U[i]:
            have[u] += 1

    # every hand-written sentence is in, spread through the first 400
    missing = [i for i in range(len(cands)) if cands[i][0] == 'special' and i not in taken]
    for n, i in enumerate(missing):
        chosen.insert(min(len(chosen), 40 + n * 25), i)
        genre_n['special'] += 1
    chosen = chosen[:a.count]

    sound = [u for u in freq if not u.startswith(('P:', 'F:'))]
    vsound = [u for u in sound if not u.startswith('S:')]

    def coverage(k, pool):
        c = collections.Counter(u for i in chosen[:k] for u in U[i])
        return 100 * sum(1 for u in pool if c[u] >= min(3, freq[u])) / len(pool)

    def tok_cov(k):
        c = collections.Counter(u for i in chosen[:k] for u in U[i])
        tot = sum(freq[u] for u in sound)
        return 100 * sum(freq[u] for u in sound if c[u] >= min(3, freq[u])) / tot

    rows = [(f'{6000000001 + n}', cands[i][0], cands[i][2]) for n, i in enumerate(chosen)]
    os.makedirs(os.path.join(ROOT, 'docs', 'audio-reader'), exist_ok=True)
    with open(os.path.join(ROOT, 'docs', 'audio-reader', 'voice_script_ar.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        for r in rows:
            f.write('\t'.join(r) + '\n')

    mins = lambda k: sum(seconds(cands[i][2]) for i in chosen[:k]) / 60
    lines = ['# نصّ تسجيل صوت إسماعيل — تقرير التغطية', '',
             'يولّده `tool/voice/build_recording_script.py`؛ لا يُعدَّل يدويًّا.', '',
             '- **أزواج الأصوات المختلفة:** نسبة أزواج الأصوات المتجاورة الموجودة في كتب المصدر التي قُرئت **3 مرات على الأقل** (أو كل مرات وجودها إن كانت أندر).',
             '- **منها في نص مشكول:** النسبة نفسها، لكن للأزواج التي تُعرف فيها الحركة.',
             '- **من نص الكتب الفعلي:** النسبة نفسها، لكن موزونة بكثرة ورود كل زوج في الكتب.', '',
             '| بعد الجملة | دقائق قراءة تقريبًا | أزواج الأصوات المختلفة | منها في نص مشكول | من نص الكتب الفعلي |', '|---|---|---|---|---|']
    for k in (100, 300, 600, len(chosen)):
        k = min(k, len(chosen))
        lines.append(f'| {k} | {mins(k):.0f} | {coverage(k, sound):.1f}٪ | {coverage(k, vsound):.1f}٪ | {tok_cov(k):.1f}٪ |')
    lines += ['', '| النوع | الجمل |', '|---|---|']
    for g in GENRES:
        lines.append(f'| {g} | {genre_n[g]} |')
    vow = sum(1 for i in chosen if voweled(cands[i][2]))
    lines += ['', f'جمل مشكولة: {vow} من {len(chosen)}.', f'حُذفت {dropped_q} جملة تشارك آيةً في خمس كلمات متتالية، و{dropped_t} جملة فيها كلمتان ملتصقتان خطأً.']
    open(os.path.join(ROOT, 'docs', 'audio-reader', 'VOICE_SCRIPT_REPORT.md'), 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
    print('\n'.join(lines))

    if a.studio:
        d = os.path.join(a.studio, 'prompts', 'Arabic (Talib books voice)_ar-SA-talib')
        os.makedirs(d, exist_ok=True)
        for old in glob.glob(os.path.join(d, '*.txt')):
            os.remove(old)
        name = f'{rows[0][0]}_{rows[-1][0]}_Script.txt'
        with open(os.path.join(d, name), 'w', encoding='utf-8', newline='\n') as f:
            for rid, _, text in rows:
                f.write(f'{rid}\t{text}\n')
        print('studio prompts ->', os.path.join(d, name))


if __name__ == '__main__':
    main()
