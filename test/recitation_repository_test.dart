import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_reading_repository.dart';
import 'package:talib_alilm_app/repositories/recitation_repository.dart';

/// Real, database-backed proof that page-level "تسميع" (76.3-redesign)
/// actually counts and persists mistakes -- not just that the UI opens.
/// An Android emulator's virtual microphone can't produce real speech, so
/// this is the rigorous way to verify the deterministic half of the
/// pipeline (everything after the recognizer hands back text) end-to-end:
/// real SQLite (via `sqflite_common_ffi`), the real migration chain
/// (`DatabaseHelper`, v45's `recitation_sessions`/`recitation_mistakes`),
/// and the real `RecitationRepository.recordPageAttempt`/`alignRecitation`
/// -- simulating only the one thing an emulator genuinely cannot supply:
/// the recognizer's output text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    final dbDir = join('.dart_tool', 'sqflite_common_ffi', 'databases');
    final dbFile = File(join(dbDir, 'talib_alilm.db'));
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('recitation_sessions');
    await db.delete('recitation_mistakes');
  });

  group('RecitationRepository.recordPageAttempt (real SQLite)', () {
    test('a perfect page-length recitation persists every ayah as a separate row, all scored 1.0', () async {
      final ayat = [
        QuranAyahText(surah: 112, ayah: 1, text: 'قل هو الله أحد'),
        QuranAyahText(surah: 112, ayah: 2, text: 'الله الصمد'),
        QuranAyahText(surah: 112, ayah: 3, text: 'لم يلد ولم يولد'),
      ];
      final said = 'قل هو الله أحد الله الصمد لم يلد ولم يولد'.split(' ');

      final repo = RecitationRepository();
      final result = await repo.recordPageAttempt(ayat: ayat, mode: 'recite', saidWords: said);

      expect(result.overallScore, 1.0);
      expect(result.ayat.length, 3);
      expect(result.ayat.every((s) => s.result.score == 1.0), isTrue);

      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('recitation_sessions', orderBy: 'ayah');
      expect(rows.length, 3, reason: 'one persisted session row per ayah, not one row for the whole page');
      expect(rows.map((r) => r['ayah']).toList(), [1, 2, 3]);
      expect(rows.every((r) => r['score'] == 1.0), isTrue);

      final mistakes = await db.query('recitation_mistakes');
      expect(mistakes, isEmpty, reason: 'a perfect recitation has no mistake rows at all');
    });

    test('a missed ayah is detected, attributed to the RIGHT ayah, and persisted as real mistake rows', () async {
      final ayat = [
        QuranAyahText(surah: 112, ayah: 1, text: 'قل هو الله أحد'),
        QuranAyahText(surah: 112, ayah: 2, text: 'الله الصمد'), // will be skipped entirely
        QuranAyahText(surah: 112, ayah: 3, text: 'لم يلد ولم يولد'),
      ];
      final said = 'قل هو الله أحد لم يلد ولم يولد'.split(' '); // ayah 2 never recited

      final repo = RecitationRepository();
      final result = await repo.recordPageAttempt(ayat: ayat, mode: 'recite', saidWords: said);

      expect(result.ayat[0].result.score, 1.0);
      expect(result.ayat[1].result.score, 0.0, reason: 'ayah 2 was never said -- both its words must show as missing');
      expect(result.ayat[2].result.score, 1.0);

      final db = await DatabaseHelper.instance.database;
      final mistakeRows = await db.query('recitation_mistakes', where: 'ayah = ?', whereArgs: [2]);
      expect(mistakeRows.length, 2, reason: 'both words of the skipped ayah must be persisted as real mistake rows');
      expect(mistakeRows.every((r) => r['status'] == 'missing'), isTrue);
      expect(mistakeRows.map((r) => r['expected_word']).toSet(), {'الله', 'الصمد'});

      // No mistake rows should leak onto the ayat that were actually correct.
      final ayah1Mistakes = await db.query('recitation_mistakes', where: 'ayah = ?', whereArgs: [1]);
      final ayah3Mistakes = await db.query('recitation_mistakes', where: 'ayah = ?', whereArgs: [3]);
      expect(ayah1Mistakes, isEmpty);
      expect(ayah3Mistakes, isEmpty);
    });

    test('a wrong word and an extra word are counted, attributed to the right ayah, and queryable via recurringMistakes', () async {
      final ayat = [
        QuranAyahText(surah: 1, ayah: 2, text: 'الحمد لله رب العالمين'),
        QuranAyahText(surah: 1, ayah: 3, text: 'الرحمن الرحيم'),
      ];
      // ayah 2: "لله" mis-said as "لربي" (a real, different word -- wrong,
      // not a fuzzy-tolerated typo). ayah 3: an extra word "سبحانه" inserted.
      final said = 'الحمد لربي رب العالمين الرحمن سبحانه الرحيم'.split(' ');

      final repo = RecitationRepository();
      final result = await repo.recordPageAttempt(ayat: ayat, mode: 'recite', saidWords: said);

      expect(result.ayat[0].result.words[1].status.name, 'wrong');
      expect(result.ayat[0].result.words[1].saidWord, 'لربي');
      expect(result.ayat[1].result.extraWordCount, 1, reason: 'the extra word must be attributed to ayah 3, not ayah 2 or lost');

      final db = await DatabaseHelper.instance.database;
      final wrongRows = await db.query('recitation_mistakes', where: 'status = ?', whereArgs: ['wrong']);
      expect(wrongRows.length, 1);
      expect(wrongRows.first['ayah'], 2);
      expect(wrongRows.first['expected_word'], 'لله');
      expect(wrongRows.first['said_word'], 'لربي');

      final ayah2Session = await db.query('recitation_sessions', where: 'ayah = ?', whereArgs: [2]);
      final ayah3Session = await db.query('recitation_sessions', where: 'ayah = ?', whereArgs: [3]);
      expect(ayah3Session.first['extra_word_count'], 1);
      expect(ayah2Session.first['extra_word_count'], 0);

      // recurringMistakes must surface this real, persisted mistake.
      final recurring = await repo.recurringMistakes();
      expect(recurring.any((m) => m.surah == 1 && m.ayah == 2 && m.expectedWord == 'لله'), isTrue);
    });

    test('repeated attempts on the same page accumulate real session history', () async {
      final ayat = [QuranAyahText(surah: 112, ayah: 1, text: 'قل هو الله أحد')];
      final repo = RecitationRepository();

      await repo.recordPageAttempt(ayat: ayat, mode: 'recite', saidWords: 'قل هو الله أحد'.split(' '));
      await repo.recordPageAttempt(ayat: ayat, mode: 'recite', saidWords: 'قل هو الله'.split(' ')); // second, worse attempt

      final history = await repo.sessionHistory(112, 1);
      expect(history.length, 2);
      expect(history.map((h) => h.$2).toSet(), {1.0, 0.75});
    });
  });
}
