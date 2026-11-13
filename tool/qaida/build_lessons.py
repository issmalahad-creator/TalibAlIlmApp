"""Builds the Noorani Qaida lessons — the ONE source for the app and for
the recording workflow.

    python tool/qaida/build_lessons.py

Writes:
  assets/qaida/qaida_lessons.json   — read by the app (lib/services/qaida_content.dart)
  docs/qaida/RECORDING_LIST.md      — what Ismail reads aloud, lesson by lesson

The items are generated from the alphabet (letter x mark combinations are
not anyone's text). The disjointed letters (الحروف المقطعة) are copied
from the bundled Uthmani text (assets/quran/quran-uthmani.txt), never
typed by hand, so they match the mushaf exactly.

Every item has an `a` (audio id). Items that sound the same share one id
(a letter's name in lesson 1 and its joined shapes in lesson 2), so it is
recorded once. A recording of lesson N contains each NEW audio id of that
lesson once, in order (see RECORDING_LIST.md).
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

FATHA, KASRA, DAMMA = 'َ', 'ِ', 'ُ'
FATHATAN, KASRATAN, DAMMATAN = 'ً', 'ٍ', 'ٌ'
SUKUN, SHADDA, TATWEEL = 'ْ', 'ّ', 'ـ'

# (letter, ascii name, Arabic letter name read aloud)
LETTERS = [
    ('ا', 'alif', 'أَلِف'), ('ب', 'ba', 'بَاء'), ('ت', 'ta', 'تَاء'), ('ث', 'tha', 'ثَاء'),
    ('ج', 'jim', 'جِيم'), ('ح', 'hha', 'حَاء'), ('خ', 'kha', 'خَاء'), ('د', 'dal', 'دَال'),
    ('ذ', 'dhal', 'ذَال'), ('ر', 'ra', 'رَاء'), ('ز', 'zay', 'زَاي'), ('س', 'sin', 'سِين'),
    ('ش', 'shin', 'شِين'), ('ص', 'sad', 'صَاد'), ('ض', 'dad', 'ضَاد'), ('ط', 'tta', 'طَاء'),
    ('ظ', 'zza', 'ظَاء'), ('ع', 'ain', 'عَيْن'), ('غ', 'ghain', 'غَيْن'), ('ف', 'fa', 'فَاء'),
    ('ق', 'qaf', 'قَاف'), ('ك', 'kaf', 'كَاف'), ('ل', 'lam', 'لَام'), ('م', 'mim', 'مِيم'),
    ('ن', 'nun', 'نُون'), ('و', 'waw', 'وَاو'), ('ه', 'ha', 'هَاء'), ('ء', 'hamza', 'هَمْزَة'),
    ('ي', 'ya', 'يَاء'),
]
NON_JOINING = set('ادذرزو')  # never join the letter after them

# letters that carry a vowel: hamza first (written on its seat), then ب…ي
CARRIERS = [l for l in LETTERS if l[0] != 'ا']
CARRIERS = [CARRIERS[-2]] + [l for l in CARRIERS if l[0] != 'ء']  # ء, ب … ي
CONSONANTS = [l for l in LETTERS if l[0] not in 'اء']  # ب … ي (27)

MUQATTAAT_REFS = [(2, 1), (7, 1), (10, 1), (13, 1), (19, 1), (20, 1), (26, 1), (27, 1),
                  (36, 1), (38, 1), (40, 1), (42, 2), (50, 1), (68, 1)]


def quran_first_words():
    out = {}
    with open(os.path.join(ROOT, 'assets/quran/quran-uthmani.txt'), encoding='utf-8') as f:
        for line in f:
            parts = line.rstrip('\n').split('|', 2)
            if len(parts) != 3 or not parts[0].isdigit():
                continue
            s, a, text = int(parts[0]), int(parts[1]), parts[2]
            if (s, a) in MUQATTAAT_REFS:
                words = text.split(' ')
                if s != 1 and a == 1 and words[0] == 'بِسْمِ':
                    words = words[4:]  # the file prefixes the basmala to āyah 1
                out[(s, a)] = words[0]
    return out


def seat(letter, mark):
    """Hamza is written on a seat: أَ إِ أُ."""
    if letter != 'ء':
        return letter + mark
    return ('إ' if mark in (KASRA, KASRATAN) else 'أ') + mark


def item(text, audio, say=None):
    d = {'t': text, 'a': audio}
    if say and say != text:
        d['say'] = say  # what is read aloud, when it differs from what is shown
    return d


def build():
    words = quran_first_words()
    lessons = []

    lessons.append({'id': 'q01', 'cols': 5, 'items': [
        item(l, 'n_' + n, say) for l, n, say in LETTERS]})

    shapes = []
    for l, n, say in LETTERS:
        if l == 'ء':
            continue
        if l in NON_JOINING:
            t = f'{l}  {TATWEEL}{l}'
        else:
            t = f'{l}{TATWEEL}  {TATWEEL}{l}{TATWEEL}  {TATWEEL}{l}'
        shapes.append(item(t, 'n_' + n, say))
    lessons.append({'id': 'q02', 'cols': 2, 'items': shapes})

    lessons.append({'id': 'q03', 'cols': 3, 'items': [
        dict(item(words[ref], f'm_{ref[0]:03d}'), ref=f'{ref[0]}:{ref[1]}') for ref in MUQATTAAT_REFS]})

    lessons.append({'id': 'q04', 'cols': 3, 'items': [
        item(seat(l, m), f'h_{n}_{v}') for l, n, _ in CARRIERS
        for m, v in ((FATHA, 'a'), (KASRA, 'i'), (DAMMA, 'u'))]})

    lessons.append({'id': 'q05', 'cols': 3, 'items': [
        item(seat(l, m), f't_{n}_{v}') for l, n, _ in CARRIERS
        for m, v in ((FATHATAN, 'an'), (KASRATAN, 'in'), (DAMMATAN, 'un'))]})

    lessons.append({'id': 'q06', 'cols': 3, 'items': [
        item(t, f'd_{n}_{v}') for l, n, _ in CARRIERS
        for t, v in ((l + FATHA + 'ا', 'a'), (l + KASRA + 'ي', 'i'), (l + DAMMA + 'و', 'u'))]})

    lessons.append({'id': 'q07', 'cols': 2, 'items': [
        item(t, f'l_{n}_{v}') for l, n, _ in CARRIERS
        for t, v in ((l + FATHA + 'ي' + SUKUN, 'ay'), (l + FATHA + 'و' + SUKUN, 'aw'))]})

    lessons.append({'id': 'q08', 'cols': 3, 'items': [
        item('أَ' + l + SUKUN, f's_{n}') for l, n, _ in CONSONANTS]})

    lessons.append({'id': 'q09', 'cols': 3, 'items': [
        item('أَ' + l + SHADDA + FATHA, f'sh_{n}') for l, n, _ in CONSONANTS]})

    return {'version': 1, 'lessons': lessons}


def recording_list(data):
    seen = set()
    out = ['# القاعدة النورانية — قائمة التسجيل', '',
           'يولَّد هذا الملف من `tool/qaida/build_lessons.py`؛ لا تعدّله يدويًّا.', '',
           '**الطريقة:** سجّل كل درس في ملف واحد. اقرأ الأصوات بالترتيب، صوتًا واحدًا كل مرّة،',
           'واسكت **ثانية كاملة** بين كل صوتين. إن أخطأت في صوت فأعد الدرس من أوله',
           '(الأداة تعدّ الأصوات، فلا تقبل التسجيل إن زاد عددها أو نقص). التفاصيل في `RECORDING_GUIDE.md`.', '']
    total = 0
    for les in data['lessons']:
        new = []
        for it in les['items']:
            if it['a'] in seen:
                continue
            seen.add(it['a'])
            new.append(it)
        total += len(new)
        out.append(f"## {les['id']} — {len(new)} صوتًا")
        out.append('')
        if not new:
            out.append('لا يحتاج تسجيلًا: أصواته سُجِّلت في درس سابق.')
        for i, it in enumerate(new, 1):
            out.append(f"{i}. {it.get('say', it['t'])}")
        out.append('')
    out.insert(2, f'**المجموع: {total} صوتًا في {sum(1 for l in data["lessons"])} دروس.**\n')
    return '\n'.join(out) + '\n'


def main():
    data = build()
    path = os.path.join(ROOT, 'assets/qaida/qaida_lessons.json')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
    doc = os.path.join(ROOT, 'docs/qaida/RECORDING_LIST.md')
    os.makedirs(os.path.dirname(doc), exist_ok=True)
    with open(doc, 'w', encoding='utf-8', newline='\n') as f:
        f.write(recording_list(data))
    n = sum(len(l['items']) for l in data['lessons'])
    print(f'{len(data["lessons"])} lessons, {n} items -> {path} ({os.path.getsize(path)} bytes)')


if __name__ == '__main__':
    sys.exit(main())
