import 'dart:convert';
import 'dart:io';

/// One-time converter: KSU-sourced Ibn Ashur tafsir (via
/// Mr-DDDAlKilanny/tafseer-sqlite-db, itself citing quran.ksu.edu.sa as the
/// original source — verified 2026-08-18) dumped as a JSON array by
/// `sqlite3 -json`, converted into this app's existing per-line JSONL+gzip
/// tafsir format so it slots into `quran_import_service.dart`'s
/// `_tafsirEditions` exactly like the other editions — no new import logic
/// needed.
Future<void> main(List<String> args) async {
  final inputPath = args.isNotEmpty ? args[0] : 'tanweer_raw.json';
  final outputPath = args.length > 1 ? args[1] : 'assets/quran/tafsir-ibn_ashur.jsonl.gz';

  final raw = await File(inputPath).readAsString();
  final rows = jsonDecode(raw) as List<dynamic>;
  stdout.writeln('Read ${rows.length} rows.');

  // 2026-08-18 (Ismail's explicit choice, after 156/6236 ayat came back
  // with empty text): Ibn Ashur often comments on a *group* of ayat under
  // the group's first ayah — the source only stores the text there, same
  // as reading a classical tafsir that discusses a passage together. Any
  // ayah with empty text inherits the nearest PRECEDING non-empty text
  // within the same surah (never crosses a surah boundary — a new surah
  // always starts its own commentary).
  final buffer = StringBuffer();
  int? currentSurah;
  String lastNonEmptyText = '';
  var filledCount = 0;
  for (final row in rows) {
    final map = row as Map<String, dynamic>;
    final surah = map['surah'] as int;
    final ayah = map['ayah'] as int;
    var text = map['text'] as String;
    if (surah != currentSurah) {
      currentSurah = surah;
      lastNonEmptyText = '';
    }
    if (text.isEmpty) {
      // 2026-08-18: no preceding non-empty text this early in the surah —
      // confirmed (checked two independent sources) this means the whole
      // surah is genuinely missing from Ibn Ashur's digitized text here
      // (Surah 18/Al-Kahf specifically, 110/110 ayat), not just grouped
      // under an earlier ayah. An honest placeholder beats either silence
      // or borrowing unrelated text from the previous surah.
      text = lastNonEmptyText.isEmpty
          ? 'نص ابن عاشور غير متوفر لهذه السورة في المصدر المستخدم حاليًا.'
          : lastNonEmptyText;
      filledCount++;
    } else {
      lastNonEmptyText = text;
    }
    buffer.writeln(jsonEncode({'surah': surah, 'ayah': ayah, 'text': text}));
  }
  stdout.writeln('Forward-filled $filledCount empty entries from the preceding ayah in the same surah.');

  final bytes = utf8.encode(buffer.toString());
  final compressed = gzip.encode(bytes);
  await File(outputPath).writeAsBytes(compressed);
  stdout.writeln('Wrote $outputPath (${compressed.length} bytes, ${rows.length} ayat).');
}
