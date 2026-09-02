import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/ayah_study_entry.dart';
import 'package:talib_alilm_app/repositories/ayah_study_repository.dart';

/// Phase 79 `79-sa-D-ayah` — the Ayah Study Notebook against a real SQLite
/// database. The point Ismail cares about: an ayah accumulates a *journey*
/// of entries over time, each keeping its own type / stance / source, and
/// free writing needs no choices.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_ayah_notebook_test.db';
    final f = File(join('.dart_tool', 'sqflite_common_ffi', 'databases', DatabaseHelper.databaseName));
    if (f.existsSync()) f.deleteSync();
  });

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('ayah_study_entries');
  });

  group('free writing first', () {
    test('body-only entry defaults to personal, no source, no status', () async {
      final repo = AyahStudyRepository();
      final id = await repo.addEntry(2, 255, const AyahStudyEntryInput(body: '  سمعت اليوم شرح الشيخ فلان لهذه الآية  '));

      final e = (await repo.entriesForAyah(2, 255)).single;
      expect(e.id, id);
      expect(e.body, 'سمعت اليوم شرح الشيخ فلان لهذه الآية', reason: 'trimmed');
      expect(e.entryType, AyahEntryTypes.personal);
      expect(e.stance, isNull);
      expect(e.hasSource, isFalse);
      expect(e.status, AyahEntryStatus.none);
      expect(e.createdAt, isNotEmpty);
      expect(e.updatedAt, e.createdAt);
    });

    test('a question entry is created as an open question', () async {
      final repo = AyahStudyRepository();
      await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'لماذا جاء التعبير بهذه الصيغة؟', entryType: AyahEntryTypes.question));
      final e = (await repo.entriesForAyah(2, 255)).single;
      expect(e.status, AyahEntryStatus.open);

      await repo.setStatus(e.id, AyahEntryStatus.resolved);
      final after = (await repo.entriesForAyah(2, 255)).single;
      expect(after.status, AyahEntryStatus.resolved);
      expect(after.resolvedAt, isNotNull);
    });
  });

  group('the journey over time', () {
    test('entries return in chronological order, and newestFirst flips it', () async {
      final repo = AyahStudyRepository();
      final a = await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'اليوم: من درس الشيخ', entryType: AyahEntryTypes.lessonSummary));
      final b = await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'بعد شهر: من تفسير ابن كثير', entryType: AyahEntryTypes.tafsir));
      final c = await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'بعد سنة: فائدة استوقفتني', entryType: AyahEntryTypes.benefit));

      final chrono = await repo.entriesForAyah(2, 255);
      expect(chrono.map((e) => e.id).toList(), [a, b, c]);

      final newest = await repo.entriesForAyah(2, 255, newestFirst: true);
      expect(newest.map((e) => e.id).toList(), [c, b, a]);
    });

    test('one ayah holds many entries from different sources; each keeps its identity', () async {
      final repo = AyahStudyRepository();
      await repo.addEntry(2, 255, const AyahStudyEntryInput(
        body: 'ذكر الشيخ أن ...', entryType: AyahEntryTypes.tafsir, stance: AyahEntryStances.naql,
        sourceType: AyahSourceTypes.sheikhLesson, sourceName: 'دروس الشيخ فلان', sourceAuthor: 'الشيخ فلان', sourceRef: 'الدرس 12',
      ));
      await repo.addEntry(2, 255, const AyahStudyEntryInput(
        body: 'وأنا أفهم منها ...', entryType: AyahEntryTypes.personal, stance: AyahEntryStances.fahm,
      ));
      await repo.addEntry(2, 255, const AyahStudyEntryInput(
        body: 'فائدة فقهية: ...', entryType: AyahEntryTypes.fiqh, topic: 'الطهارة',
        sourceType: AyahSourceTypes.tafsirBook, sourceName: 'تفسير ابن كثير',
      ));

      final entries = await repo.entriesForAyah(2, 255);
      expect(entries.length, 3);
      expect(entries[0].stance, AyahEntryStances.naql);
      expect(entries[0].sourceAuthor, 'الشيخ فلان');
      expect(entries[0].sourceLine, contains('دروس الشيخ فلان'));
      expect(entries[1].stance, AyahEntryStances.fahm);
      expect(entries[1].hasSource, isFalse);
      expect(entries[2].topic, 'الطهارة');
      expect(entries[2].entryType, AyahEntryTypes.fiqh);
    });

    test('overview counts per entry type', () async {
      final repo = AyahStudyRepository();
      for (final t in [AyahEntryTypes.tafsir, AyahEntryTypes.tafsir, AyahEntryTypes.benefit, AyahEntryTypes.question]) {
        await repo.addEntry(2, 255, AyahStudyEntryInput(body: 'x', entryType: t));
      }
      final counts = await repo.typeCountsForAyah(2, 255);
      expect(counts[AyahEntryTypes.tafsir], 2);
      expect(counts[AyahEntryTypes.benefit], 1);
      expect(counts[AyahEntryTypes.question], 1);
      expect(await repo.countForAyah(2, 255), 4);
    });
  });

  group('edit / filter / cross-ayah', () {
    test('updateEntry keeps id + created_at, bumps updated_at, changes fields', () async {
      final repo = AyahStudyRepository();
      final id = await repo.addEntry(1, 1, const AyahStudyEntryInput(body: 'أولى'));
      final before = (await repo.entriesForAyah(1, 1)).single;

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.updateEntry(id, const AyahStudyEntryInput(
        body: 'معدَّلة', entryType: AyahEntryTypes.meaning, stance: AyahEntryStances.istinbat, sourceName: 'تفسير السعدي',
      ));
      final after = (await repo.entriesForAyah(1, 1)).single;
      expect(after.id, id);
      expect(after.createdAt, before.createdAt);
      expect(after.updatedAt.compareTo(before.updatedAt) > 0, isTrue);
      expect(after.body, 'معدَّلة');
      expect(after.entryType, AyahEntryTypes.meaning);
      expect(after.stance, AyahEntryStances.istinbat);
      expect(after.sourceName, 'تفسير السعدي');
    });

    test('entriesForAyah filters by type; delete removes only that entry', () async {
      final repo = AyahStudyRepository();
      final q = await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'سؤال', entryType: AyahEntryTypes.question));
      await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'فائدة', entryType: AyahEntryTypes.benefit));

      expect((await repo.entriesForAyah(2, 255, filterType: AyahEntryTypes.question)).length, 1);
      await repo.deleteEntry(q);
      expect((await repo.entriesForAyah(2, 255)).length, 1);
      expect((await repo.entriesForAyah(2, 255)).single.entryType, AyahEntryTypes.benefit);
    });

    test('search across body + source; richest ayat; distinct topics', () async {
      final repo = AyahStudyRepository();
      await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'عن الإخلاص وأثره', entryType: AyahEntryTypes.benefit, topic: 'الإخلاص'));
      await repo.addEntry(2, 255, const AyahStudyEntryInput(body: 'شيء آخر', sourceName: 'كتاب الإخلاص للحارث', entryType: AyahEntryTypes.tafsir));
      await repo.addEntry(112, 1, const AyahStudyEntryInput(body: 'قل هو الله أحد', entryType: AyahEntryTypes.meaning, topic: 'التوحيد'));

      expect((await repo.notebookEntries(query: 'الإخلاص')).length, 2);
      expect((await repo.notebookEntries(entryTypes: [AyahEntryTypes.benefit])).length, 1);
      expect((await repo.notebookEntries(surah: 112)).length, 1);

      final richest = await repo.ayatWithEntries();
      expect(richest.first.surah, 2);
      expect(richest.first.ayah, 255);
      expect(richest.first.count, 2);

      expect(await repo.distinctTopics(), containsAll(<String>['الإخلاص', 'التوحيد']));
    });
  });
}
