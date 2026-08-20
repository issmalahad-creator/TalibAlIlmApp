// One-time offline fetch script (NOT part of the app) — run manually via
// `dart run tool/fetch_quranenc_translations.dart` to (re)generate the
// gzip-compressed JSONL tafsir/translation assets under assets/quran/.
// Source: QuranEnc.com's public API (https://quranenc.com/en/home/api/),
// terms verified directly this session — bulk export/redistribution is
// permitted with attribution + no content modification, no commercial
// restriction found. See quirky-gliding-shell.md's "مكتبة التفسير/الترجمة
// متعددة اللغات" plan for the full licensing research.
//
// Output JSONL shape matches the existing Arabic tafsir assets exactly
// ({"surah": int, "ayah": int, "text": string} per line), so
// QuranImportService._importTafsirEdition can import it unmodified.
import 'dart:convert';
import 'dart:io';

const _editions = [
  ('english_rwwad', 'tafsir-english_rwwad.jsonl.gz'),
  ('amharic_sadiq', 'tafsir-amharic_sadiq.jsonl.gz'),
  // Batch 2 — same source/terms, expanding language coverage per Ismail's
  // "لغات كثيرة" request.
  ('french_rashid', 'tafsir-french_rashid.jsonl.gz'),
  ('turkish_rwwad', 'tafsir-turkish_rwwad.jsonl.gz'),
  ('indonesian_sabiq', 'tafsir-indonesian_sabiq.jsonl.gz'),
  ('urdu_junagarhi', 'tafsir-urdu_junagarhi.jsonl.gz'),
  ('bengali_zakaria', 'tafsir-bengali_zakaria.jsonl.gz'),
  // Batch 3 — as many more QuranEnc languages as verified to actually work
  // (every key here confirmed live via curl before adding), per Ismail's
  // "ادخل اكبر كم ممكن او كل اللغات ان امكن" request.
  ('spanish_garcia', 'tafsir-spanish_garcia.jsonl.gz'),
  ('portuguese_nasr', 'tafsir-portuguese_nasr.jsonl.gz'),
  ('greek_rwwad', 'tafsir-greek_rwwad.jsonl.gz'),
  ('german_rwwad', 'tafsir-german_rwwad.jsonl.gz'),
  ('italian_rwwad', 'tafsir-italian_rwwad.jsonl.gz'),
  ('bulgarian_translation', 'tafsir-bulgarian_translation.jsonl.gz'),
  ('romanian_project', 'tafsir-romanian_project.jsonl.gz'),
  ('dutch_center', 'tafsir-dutch_center.jsonl.gz'),
  ('swedish_rwwad', 'tafsir-swedish_rwwad.jsonl.gz'),
  ('azeri_musayev', 'tafsir-azeri_musayev.jsonl.gz'),
  ('georgian_rwwad', 'tafsir-georgian_rwwad.jsonl.gz'),
  ('macedonian_group', 'tafsir-macedonian_group.jsonl.gz'),
  ('albanian_rwwad', 'tafsir-albanian_rwwad.jsonl.gz'),
  ('bosnian_rwwad', 'tafsir-bosnian_rwwad.jsonl.gz'),
  ('russian_rwwad', 'tafsir-russian_rwwad.jsonl.gz'),
  ('belarusian_krivtsov', 'tafsir-belarusian_krivtsov.jsonl.gz'),
  ('serbian_rwwad', 'tafsir-serbian_rwwad.jsonl.gz'),
  ('croatian_rwwad', 'tafsir-croatian_rwwad.jsonl.gz'),
  ('lithuanian_rwwad', 'tafsir-lithuanian_rwwad.jsonl.gz'),
  ('ukrainian_yakubovych', 'tafsir-ukrainian_yakubovych.jsonl.gz'),
  ('kazakh_altai', 'tafsir-kazakh_altai.jsonl.gz'),
  ('uzbek_rwwad', 'tafsir-uzbek_rwwad.jsonl.gz'),
  ('tajik_arifi', 'tafsir-tajik_arifi.jsonl.gz'),
  ('kyrgyz_hakimov', 'tafsir-kyrgyz_hakimov.jsonl.gz'),
  ('circassian_rwwad', 'tafsir-circassian_rwwad.jsonl.gz'),
  ('tagalog_rwwad', 'tafsir-tagalog_rwwad.jsonl.gz'),
  ('bisayan_rwwad', 'tafsir-bisayan_rwwad.jsonl.gz'),
  ('iranun_sarro', 'tafsir-iranun_sarro.jsonl.gz'),
  ('maguindanao_rwwad', 'tafsir-maguindanao_rwwad.jsonl.gz'),
  ('malay_basumayyah', 'tafsir-malay_basumayyah.jsonl.gz'),
  ('chinese_suliman', 'tafsir-chinese_suliman.jsonl.gz'),
  ('uyghur_saleh', 'tafsir-uyghur_saleh.jsonl.gz'),
  ('japanese_saeedsato', 'tafsir-japanese_saeedsato.jsonl.gz'),
  ('somali_abduh', 'tafsir-somali_abduh.jsonl.gz'),
  ('hindi_omari', 'tafsir-hindi_omari.jsonl.gz'),
  ('luganda_foundation', 'tafsir-luganda_foundation.jsonl.gz'),
];

const _suraCount = 114;

Future<void> main() async {
  final client = HttpClient();
  final outDir = Directory('assets/quran');

  for (final (translationKey, outFileName) in _editions) {
    final existing = File('${outDir.path}/$outFileName');
    if (await existing.exists()) {
      stdout.writeln('Skipping $translationKey — ${existing.path} already exists.');
      continue;
    }
    stdout.writeln('Fetching $translationKey...');
    final lines = <String>[];

    for (var sura = 1; sura <= _suraCount; sura++) {
      final uri = Uri.parse('https://quranenc.com/api/v1/translation/sura/$translationKey/$sura');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        stderr.writeln('  sura $sura: HTTP ${response.statusCode} — aborting $translationKey');
        break;
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final result = decoded['result'] as List<dynamic>;
      for (final entry in result) {
        final map = entry as Map<String, dynamic>;
        final row = {
          'surah': int.parse(map['sura'] as String),
          'ayah': int.parse(map['aya'] as String),
          'text': map['translation'] as String,
        };
        lines.add(jsonEncode(row));
      }
      stdout.write('\r  sura $sura/$_suraCount (${lines.length} ayat so far)');
      // Small courtesy delay between requests — not a documented
      // requirement, just standard etiquette for a public API.
      await Future.delayed(const Duration(milliseconds: 120));
    }
    stdout.writeln();

    final jsonlText = lines.join('\n');
    final compressed = gzip.encode(utf8.encode(jsonlText));
    final outFile = File('${outDir.path}/$outFileName');
    await outFile.writeAsBytes(compressed);
    stdout.writeln('  wrote ${outFile.path} (${compressed.length} bytes, ${lines.length} ayat)');
  }

  client.close();
  stdout.writeln('Done.');
}
