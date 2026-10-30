import 'arabic_normalize.dart';
import 'fuzzy_match.dart';

/// Text rules for «التسميع» (ت1 in `docs/memorization/RECITATION_REBUILD_PLAN.md`).
///
/// The speech recognizer returns plain modern spelling («ذلك الكتاب لا ريب»)
/// while the muṣḥaf is Uthmani with full tashkeel («ذَٰلِكَ ٱلۡكِتَٰبُ»). Both
/// sides are reduced to one comparable key before any word is judged, so a
/// correct recitation is never scored as mistakes (cause #1 of the plan).

/// The comparable key of one word: no tashkeel, no Quranic small marks, one
/// alef, ي for ى, ه for ة, ء for seated hamzas, letters only.
String recitationKey(String word) {
  var s = normalizeArabicForSearch(word);
  s = s.replaceAll(RegExp('[ؤئ]'), 'ء');
  // Anything that is not an Arabic letter (digits, punctuation, the ayah-end
  // ornament, stray Latin from the recognizer) carries no recited sound.
  s = s.replaceAll(RegExp('[^ء-ي]'), '');
  return s;
}

/// A muṣḥaf "word" that is never pronounced: the waqf signs (ۛ ۖ ۗ ۚ …) that
/// the layout stores as words of their own (cause #2), or an empty token.
bool isSilentMark(String word) => recitationKey(word).isEmpty;

/// How each disjoined letter of the muqaṭṭaʿāt is read aloud — the recognizer
/// writes «الف لام ميم» or «الم», and both must match «الٓمٓ».
const Map<String, String> _letterNames = {
  'ا': 'الف',
  'ل': 'لام',
  'م': 'ميم',
  'ص': 'صاد',
  'ر': 'را',
  'ك': 'كاف',
  'ه': 'ها',
  'ي': 'يا',
  'ع': 'عين',
  'ط': 'طا',
  'س': 'سين',
  'ح': 'حا',
  'ق': 'قاف',
  'ن': 'نون',
};

/// The spoken form of a muqaṭṭaʿa word («الم» → «الفلامميم»), or null when
/// [key] is an ordinary word.
String? _spokenLetters(String key) {
  if (key.isEmpty || key.length > 5) return null;
  final out = StringBuffer();
  for (final ch in key.split('')) {
    final name = _letterNames[ch];
    if (name == null) return null;
    out.write(recitationKey(name));
  }
  return out.toString();
}

/// The opening letters of the 29 surahs that begin with muqaṭṭaʿāt, as keys.
/// Only these words get the letter-name reading, so an ordinary «من» is never
/// accepted as «ميم نون».
const Set<String> muqattaatKeys = {
  'الم', 'المص', 'الر', 'المر', 'كهيعص', 'طه', 'طسم', 'طس', 'يس', 'ص',
  'حم', 'عسق', 'ق', 'ن',
};

/// Whether [expected] (a muṣḥaf word) was said as [said] (a recognizer word).
/// Exact key match, a muqaṭṭaʿa read by its letter names, or a near spelling
/// within the length-adaptive tolerance of [isFuzzyMatch].
bool recitationWordsMatch(String expected, String said) {
  final e = recitationKey(expected);
  final s = recitationKey(said);
  if (e.isEmpty || s.isEmpty) return false;
  if (e == s) return true;
  if (muqattaatKeys.contains(e)) {
    final spoken = _spokenLetters(e);
    if (spoken != null && (spoken == s || isFuzzyMatch(spoken, s))) return true;
  }
  return isFuzzyMatch(e, s);
}

/// Splits a recognizer transcript into words and joins a run of spoken letter
/// names («الف لام ميم») into one token, so it lines up with the single muṣḥaf
/// word «الٓمٓ» instead of counting as three extra words.
List<String> splitRecitedTranscript(String text) {
  final raw = text.trim().isEmpty ? <String>[] : text.trim().split(RegExp(r'\s+'));
  final names = {for (final n in _letterNames.values) recitationKey(n)};
  final out = <String>[];
  var i = 0;
  while (i < raw.length) {
    var j = i;
    while (j < raw.length && names.contains(recitationKey(raw[j]))) {
      j++;
    }
    if (j - i >= 2) {
      out.add(raw.sublist(i, j).join());
      i = j;
    } else {
      if (recitationKey(raw[i]).isNotEmpty) out.add(raw[i]);
      i++;
    }
  }
  return out;
}
