import 'dart:convert';
import 'dart:io';

/// Diagnostic: validate every line of the converted Ibn Ashur JSONL parses
/// exactly the way `quran_import_service.dart`'s `_importTafsirEdition`
/// expects (surah/ayah as int, text as String), and that all 6236 ayat are
/// present with no gaps/duplicates — checking for the actual bug instead of
/// guessing.
Future<void> main() async {
  final bytes = await File('assets/quran/tafsir-ibn_ashur.jsonl.gz').readAsBytes();
  final decompressed = gzip.decode(bytes);
  final text = utf8.decode(decompressed);
  final lines = const LineSplitter().convert(text);
  stdout.writeln('Total lines: ${lines.length}');

  var errors = 0;
  final seen = <String>{};
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) continue;
    try {
      final obj = jsonDecode(line) as Map<String, dynamic>;
      final surah = obj['surah'] as int;
      final ayah = obj['ayah'] as int;
      final txt = obj['text'] as String;
      final key = '$surah:$ayah';
      if (seen.contains(key)) {
        stdout.writeln('DUPLICATE at line ${i + 1}: $key');
        errors++;
      }
      seen.add(key);
      if (txt.isEmpty) {
        stdout.writeln('EMPTY TEXT at line ${i + 1}: $key');
        errors++;
      }
    } catch (e) {
      stdout.writeln('PARSE ERROR at line ${i + 1}: $e');
      stdout.writeln('  Line content (first 200 chars): ${line.substring(0, line.length > 200 ? 200 : line.length)}');
      errors++;
    }
  }
  stdout.writeln('Unique surah:ayah keys: ${seen.length} (expect 6236)');
  stdout.writeln('Errors found: $errors');
}
