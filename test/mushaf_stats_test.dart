import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/data/quran_surahs.dart';
import 'package:talib_alilm_app/services/mushaf_stats.dart';

/// «إحصاءات المصحف» on the real bundled Uthmani text.
void main() {
  final rows = <AyahText>[
    for (final line in File('assets/quran/quran-uthmani.txt').readAsLinesSync())
      if (line.trim().isNotEmpty && !line.startsWith('#') && line.split('|').length == 3)
        (surah: int.parse(line.split('|')[0]), ayah: int.parse(line.split('|')[1]), text: line.split('|')[2]),
  ];
  final all = countMushaf(rows);

  test('ayat = 6236, and each surah has its known ayah count', () {
    expect(all.ayat, 6236);
    for (final s in quranSurahs) {
      expect(countMushaf(rows.where((r) => r.surah == s.number).toList()).ayat, s.ayahCount, reason: s.name);
    }
  });

  test('the 15 sajdāt, at their places', () {
    expect(all.sajdat.map((r) => '${r.surah}:${r.ayah}'), [
      '7:206', '13:15', '16:50', '17:109', '19:58', '22:18', '22:77', '25:60',
      '27:26', '32:15', '38:24', '41:38', '53:62', '84:21', '96:19',
    ]);
  });

  test('saktāt: the 5 places of Ḥafṣ — not the two «read with sīn» marks inside a word', () {
    expect(all.saktat.map((r) => '${r.surah}:${r.ayah}'), ['18:1', '36:52', '69:28', '75:27', '83:14']);
  });

  test('waqf signs by kind, as written in the text', () {
    expect(all.waqf, {
      WaqfKind.lazim: 22,
      WaqfKind.jaizWaslAwla: 1682,
      WaqfKind.jaiz: 1972,
      WaqfKind.jaizWaqfAwla: 603,
      WaqfKind.muanaqa: 12,
      WaqfKind.la: 68,
    });
    // the ∴ ∴ pair: always two marks per place
    expect(all.waqf[WaqfKind.muanaqa]! % 2, 0);
  });

  test('words and letters are additive over surahs and stable', () {
    var words = 0, letters = 0;
    for (final s in quranSurahs) {
      final st = countMushaf(rows.where((r) => r.surah == s.number).toList());
      words += st.words;
      letters += st.letters;
    }
    expect(words, all.words);
    expect(letters, all.letters);
    // Pinned so a change to the text or the definitions is noticed.
    expect(all.words, 77881);
    expect(all.letters, 327514);
    expect(all.letterFrequency.first.key, 'ا', reason: 'alif is the most frequent letter');
  });

  test('al-Fātiḥa', () {
    final f = countMushaf(rows.where((r) => r.surah == 1).toList());
    expect(f.ayat, 7);
    expect(f.words, 29);
    expect(f.sajdat, isEmpty);
  });
}
