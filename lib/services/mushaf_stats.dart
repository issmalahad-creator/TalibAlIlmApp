/// «إحصاءات المصحف» — counts from the muṣḥaf text itself, nothing else:
/// ayat, words, letters, every waqf sign by kind, the saktāt, the sajdāt,
/// and how often each letter occurs. Pure functions over `(surah, ayah,
/// uthmani text)` rows, so the same code counts the whole muṣḥaf, a surah,
/// a juzʼ, a ḥizb or a page, and `test/` checks it against the real text.
///
/// Definitions (shown to the reader next to the numbers — published counts
/// differ because they count differently, `docs/quran/QURAN_DATA_MODEL.md`):
/// * **word** = a written word of the Uthmani rasm, as printed between
///   spaces (waqf signs and the ۞ ۩ ornaments are not words);
/// * **letter** = a written letter of the rasm, without ḥarakāt and without
///   the small (dagger) alif, which is a reading sign, not a written letter;
/// * **sakta** = the small sīn ۜ written *after* a word. Inside a word (2:245
///   «يَبۡصُۜطُ», 7:69 «بَصۡۜطَةٗ») it means "read with sīn" and is not a sakta.
library;

import 'package:flutter/foundation.dart';

/// The waqf signs of the Madani muṣḥaf, with the Unicode mark the text uses.
enum WaqfKind {
  lazim('ۘ'), // م — stopping is required
  jaizWaslAwla('ۖ'), // صلى — either; joining is better
  jaiz('ۚ'), // ج — either, equally
  jaizWaqfAwla('ۗ'), // قلى — either; stopping is better
  muanaqa('ۛ'), // ∴ ∴ — stop at one of the two, not both
  la('ۙ'); // لا — do not stop

  const WaqfKind(this.mark);
  final String mark;
}

const _sakta = 'ۜ';
const _sajda = '۩';
const _rub = '۞';

final _letter = RegExp('[ء-غف-يٱ]');
final _hasLetter = RegExp('[ء-يٱ]');

/// One ayah row: what the counts are made from.
typedef AyahText = ({int surah, int ayah, String text});

/// A place in the muṣḥaf, for the lists (saktāt, sajdāt).
typedef AyahRef = ({int surah, int ayah});

@immutable
class MushafStats {
  final int ayat;
  final int words;
  final int letters;
  final Map<WaqfKind, int> waqf;
  final List<AyahRef> saktat;
  final List<AyahRef> sajdat;
  final int rubMarks;

  /// Letter → occurrences, most frequent first.
  final List<MapEntry<String, int>> letterFrequency;

  const MushafStats({
    required this.ayat,
    required this.words,
    required this.letters,
    required this.waqf,
    required this.saktat,
    required this.sajdat,
    required this.rubMarks,
    required this.letterFrequency,
  });

  int get waqfTotal => waqf.values.fold(0, (a, b) => a + b);
}

/// Counts [rows]. Fast enough for the whole muṣḥaf (~6k rows, ~700k
/// characters) to run in an isolate via [computeMushafStats].
MushafStats countMushaf(List<AyahText> rows) {
  var words = 0;
  var letters = 0;
  var rub = 0;
  final waqf = {for (final k in WaqfKind.values) k: 0};
  final byMark = {for (final k in WaqfKind.values) k.mark: k};
  final saktat = <AyahRef>[];
  final sajdat = <AyahRef>[];
  final freq = <String, int>{};

  for (final r in rows) {
    final t = r.text;
    var hasSakta = false;
    for (var i = 0; i < t.length; i++) {
      final ch = t[i];
      final kind = byMark[ch];
      if (kind != null) {
        waqf[kind] = waqf[kind]! + 1;
      } else if (ch == _sakta) {
        // after a word = a sakta; inside a word = "read with sīn"
        final next = i + 1 < t.length ? t[i + 1] : ' ';
        final prev = i > 0 ? t[i - 1] : ' ';
        if (next == ' ' || prev == ' ') hasSakta = true;
      } else if (ch == _sajda) {
        sajdat.add((surah: r.surah, ayah: r.ayah));
      } else if (ch == _rub) {
        rub++;
      } else if (_letter.hasMatch(ch)) {
        letters++;
        final key = ch == 'ٱ' ? 'ا' : ch; // ٱ is an alif
        freq[key] = (freq[key] ?? 0) + 1;
      }
    }
    if (hasSakta) saktat.add((surah: r.surah, ayah: r.ayah));
    for (final w in t.split(' ')) {
      if (_hasLetter.hasMatch(w)) words++;
    }
  }
  final sortedFreq = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return MushafStats(
    ayat: rows.length,
    words: words,
    letters: letters,
    waqf: waqf,
    saktat: saktat,
    sajdat: sajdat,
    rubMarks: rub,
    letterFrequency: sortedFreq,
  );
}

/// [countMushaf] off the UI isolate (the whole muṣḥaf is ~700k characters).
Future<MushafStats> computeMushafStats(List<AyahText> rows) => compute(countMushaf, rows);
