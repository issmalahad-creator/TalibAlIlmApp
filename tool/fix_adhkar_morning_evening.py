"""Repairs the morning/evening chapter of assets/adhkar/hisn_almuslim.json.

The upstream scrape (rn0x/hisn_almuslim_json) shifted the chapter's notes:
each dhikr from item 3 on shows a note that belongs to another one (the
«وإذا أمسى قال» notes were interleaved with the sources).
This script (idempotent — it checks the original layout first):

1. moves every footnote back onto its dhikr (sources/virtues only; no new
   text is written — a dhikr whose note is lost upstream gets none);
2. adds `when` ('both' | 'morning' | 'evening') and `evening` (the evening
   wording) — built ONLY from the book's own «وإذا أمسى قال …» instructions
   already present in this chapter, so the morning and evening lists can be
   read separately like the book prescribes;
3. strips the inline «وإذا أمسي قال …» remarks from the morning texts and
   the stray «من قال :» prefix from the 100× tasbih.

Run: python3 tool/fix_adhkar_morning_evening.py
"""
import json

P = 'assets/adhkar/hisn_almuslim.json'
data = json.load(open(P, encoding='utf-8'))
ch = next(c for c in data if c['title'] == 'أذكار الصباح والمساء')
it = ch['items']
assert len(it) == 25

if 'when' in it[0]:
    print('already repaired')
    raise SystemExit

old = [x['footnote'] for x in it]
assert old[5] == 'مسلم 4/ 2088' and 'كفاه الله' in old[15], 'unexpected upstream layout'

# 1. footnotes back in place. Read off the notes' own content: upstream
# interleaved the «وإذا أمسى» notes (3, 4, 6, 10, 12, 21, 22, 24 — now the
# `evening` texts) and a stray text fragment (8, «أقر وأعترف») among the
# sources, so the offset is not constant. new item ← old note:
SOURCE_OF = {3: 5, 4: 7, 5: 9, 6: 11, 7: 13, 8: 14, 9: 15, 10: 16, 11: 17,
             12: 18, 13: 19, 14: 20, 15: 23}
new = list(old)
for i in range(3, 25):
    new[i] = old[SOURCE_OF[i]] if i in SOURCE_OF else None
for i, f in enumerate(new):
    it[i]['footnote'] = f

# 3. morning-text cleanups
it[3]['text'] = it[3]['text'].split('وإذا أمسي')[0].strip()
it[4]['text'] = it[4]['text'].split('وإذا أمسي')[0].strip()
it[17]['text'] = it[17]['text'].replace('من قال :', '').strip()

# 2. evening wording — each from the chapter's own «وإذا أمسى قال» note.
evening = {
    3: 'أمسينا وأمسى الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير، '
       'ربِّ أسألك خير ما في هذه الليلة وخير ما بعدها، وأعوذ بك من شر ما في هذه الليلة وشر ما بعدها، '
       'ربِّ أعوذ بك من الكسل وسوء الكبر، ربِّ أعوذ بك من عذابٍ في النار وعذابٍ في القبر',
    4: 'اللهم بك أمسينا، وبك أصبحنا، وبك نحيا وبك نموت، وإليك المصير',
    6: it[6]['text'].replace('أصبحت', 'أمسيت'),
    7: it[7]['text'].replace('ما أصبح بي', 'ما أمسى بي'),
    15: 'أمسينا وأمسى الملك لله رب العالمين، اللهم إني أسألك خير هذه الليلة: فتحها ونصرها ونورها وبركتها وهداها، '
        'وأعوذ بك من شر ما فيها وشر ما بعدها',
    16: it[16]['text'].replace('أصبحنا', 'أمسينا'),
}
morning_only = {19, 20, 21}   # «إذا أصبح» in the text itself
evening_only = {23}           # «إذا أمسى» in the text itself
for i, x in enumerate(it):
    x['when'] = 'morning' if i in morning_only else 'evening' if i in evening_only else 'both'
    x['evening'] = evening.get(i)
    assert x['evening'] is None or 'أصبح' not in x['evening'].replace('وبك أصبحنا', ''), i

json.dump(data, open(P, 'w', encoding='utf-8'), ensure_ascii=False)  # same one-line layout as upstream
print('repaired', len(it), 'items')
