import '../../data/quran_surahs.dart';
import '../../utils/arabic_normalize.dart';
import '../../utils/digits.dart';

/// What a typed «انتقل إلى» query can mean.
enum GoToKind { page, juz, hizb, surah, ayah }

/// One reading of the query. [n] is the page/juzʼ/ḥizb/surah number; [ayah]
/// is set only for [GoToKind.ayah].
class GoToHit {
  final GoToKind kind;
  final int n;
  final int? ayah;
  const GoToHit(this.kind, this.n, [this.ayah]);

  @override
  bool operator ==(Object other) => other is GoToHit && other.kind == kind && other.n == n && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(kind, n, ayah);

  @override
  String toString() => 'GoToHit($kind, $n, $ayah)';
}

const _pageWords = {'صفحه', 'صفحة', 'ص', 'page', 'p', 'pg'};
const _juzWords = {'جزء', 'الجزء', 'جز', 'juz', 'j', 'para'};
const _hizbWords = {'حزب', 'الحزب', 'hizb', 'h'};
const _surahWords = {'سوره', 'سورة', 'surah', 'sura', 's'};

String _norm(String s) {
  var t = normalizeArabicForSearch(s).trim();
  if (t.startsWith('ال')) t = t.substring(2);
  return t;
}

/// Every surah's search key, without «ال».
final List<String> _surahKeys = [for (final s in quranSurahs) _norm(s.name)];

/// Reads a free query — «٣٢٣», «جزء ١٧», «حزب 33», «الكهف», «كهف»,
/// «البقرة ٢٥٥», «2:255» — into ranked hits, best first. Pure: the sheet
/// turns each hit into a page.
List<GoToHit> parseGoToQuery(String raw, {int pages = 604}) {
  final q = latinDigits(raw).trim().toLowerCase();
  if (q.isEmpty) return const [];

  // «2:255» / «2 : 255»
  final ref = RegExp(r'^(\d{1,3})\s*[:：.]\s*(\d{1,3})$').firstMatch(q);
  if (ref != null) {
    final s = int.parse(ref.group(1)!), a = int.parse(ref.group(2)!);
    if (s >= 1 && s <= 114 && a >= 1 && a <= quranSurahs[s - 1].ayahCount) return [GoToHit(GoToKind.ayah, s, a)];
    return const [];
  }

  // a bare number: page first, then juzʼ / surah with that number
  final bare = RegExp(r'^\d{1,3}$').hasMatch(q) ? int.parse(q) : null;
  if (bare != null) {
    return [
      if (bare >= 1 && bare <= pages) GoToHit(GoToKind.page, bare),
      if (bare >= 1 && bare <= 30) GoToHit(GoToKind.juz, bare),
      if (bare >= 1 && bare <= 114) GoToHit(GoToKind.surah, bare),
    ];
  }

  // «word number»
  final m = RegExp(r'^(.+?)\s*(\d{1,3})$').firstMatch(q);
  final word = (m?.group(1) ?? q).trim();
  final num = m == null ? null : int.parse(m.group(2)!);
  final w = _norm(word);

  if (num != null) {
    if (_pageWords.contains(word) || _pageWords.contains(w)) {
      return num >= 1 && num <= pages ? [GoToHit(GoToKind.page, num)] : const [];
    }
    if (_juzWords.contains(word) || _juzWords.contains(w)) {
      return num >= 1 && num <= 30 ? [GoToHit(GoToKind.juz, num)] : const [];
    }
    if (_hizbWords.contains(word) || _hizbWords.contains(w)) {
      return num >= 1 && num <= 60 ? [GoToHit(GoToKind.hizb, num)] : const [];
    }
    if (_surahWords.contains(word) || _surahWords.contains(w)) {
      return num >= 1 && num <= 114 ? [GoToHit(GoToKind.surah, num)] : const [];
    }
  }

  // a surah name (optionally «سورة …»), then an ayah number
  var name = w;
  for (final p in _surahWords) {
    final pn = _norm(p);
    if (name.startsWith('$pn ')) name = _norm(name.substring(pn.length + 1));
  }
  if (name.isEmpty) return const [];
  final exact = <int>[], prefix = <int>[], inside = <int>[];
  for (var i = 0; i < _surahKeys.length; i++) {
    final k = _surahKeys[i];
    if (k == name) {
      exact.add(i + 1);
    } else if (k.startsWith(name)) {
      prefix.add(i + 1);
    } else if (name.length >= 2 && k.contains(name)) {
      inside.add(i + 1);
    }
  }
  final surahs = [...exact, ...prefix, ...inside].take(5);
  return [
    for (final s in surahs)
      if (num == null)
        GoToHit(GoToKind.surah, s)
      else if (num >= 1 && num <= quranSurahs[s - 1].ayahCount)
        GoToHit(GoToKind.ayah, s, num),
  ];
}
