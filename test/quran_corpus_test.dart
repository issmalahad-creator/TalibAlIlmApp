import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_repository.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';

/// Phase 80 / QC2 — the Quran Corpus seeds from the real bundled assets and
/// every per-ayah lookup resolves via the canonical `(surah, ayah)` spine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late QuranCorpusRepository repo;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_quran_corpus_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
    repo = QuranCorpusRepository();
  });

  test('sync seeded every corpus dataset (meta rows present)', () async {
    final db = await DatabaseHelper.instance.database;
    expect(await repo.isReady(), isTrue);
    final metas = await db.query('quran_corpus_meta');
    final names = {for (final m in metas) m['dataset'] as String};
    // the small, per-ayah + catalog datasets seeded here
    expect(
      names,
      containsAll(<String>{
        'morphology', 'syntax', 'meanings', 'notes', 'qiraat', 'similar',
        'sayings', 'nasekh', 'irab_books', 'asbab_books', 'topics',
        'tafsir_index', 'translations_index', 'riwaya_index', 'reciters',
        'book_catalog', 'surah_info',
      }),
    );
  });

  test('morphology & syntax cover all 6236 ayat', () async {
    final db = await DatabaseHelper.instance.database;
    expect(
      Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM quran_morphology')),
      6236,
    );
    expect(
      Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM quran_syntax')),
      6236,
    );
  });

  test('per-ayah lookups resolve for al-Fatiha 1:1', () async {
    final m = await repo.morphology(1, 1);
    expect(m, isNotNull);
    expect(m.toString(), contains('source'));
    expect(await repo.syntax(1, 1), isNotNull);
    expect(await repo.wordMeanings(1, 1), isNotNull);
    // some ayat have no note/qiraat — those return null, not throw
    expect(() => repo.notes(2, 255), returnsNormally);
  });

  test('catalogs are populated and sane', () async {
    final tafsirs = await repo.tafsirBooks();
    expect(tafsirs.length, 149);
    final bundled = await repo.tafsirBooks(bundled: true);
    expect(bundled.length, greaterThan(100));
    expect(bundled.length, lessThan(149)); // some are Supabase-mirror

    final eds = await repo.translationEditions();
    expect(eds.length, greaterThanOrEqualTo(130));

    final riw = await repo.riwayat();
    expect(riw.first['is_primary'], 1); // Hafs first
    expect(riw.first['ayat'], 6236);

    final rec = await repo.reciters();
    expect(rec.length, greaterThan(100));
    expect(rec.first['audio_base'], startsWith('http'));

    expect(await repo.surahIntro(1), isNotNull);
    expect((await repo.booksByType('tafsir', limit: 10)).length, 10);
  });

  test('topics → ayah and ayah → topics both resolve', () async {
    final db = await DatabaseHelper.instance.database;
    expect(
      Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM quran_topic')),
      6100,
    );
    expect(
      Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM quran_topic_ayah')),
      greaterThan(15000),
    );
    // 7:26 (اللباس/الريش) had a topic in the raw dump
    final topics = await repo.topicsForAyah(7, 26);
    expect(topics, isNotEmpty);
    final ranges = await repo.ayatForTopic(topics.first['id'] as int);
    expect(ranges, isNotEmpty);
  });

  test('irab prose + asbab join their book metadata', () async {
    final db = await DatabaseHelper.instance.database;
    // pick any ayah that has irab prose
    final row = await db.rawQuery(
        'SELECT surah, ayah FROM quran_irab_prose LIMIT 1');
    final s = row.first['surah'] as int, a = row.first['ayah'] as int;
    final prose = await repo.irabProse(s, a);
    expect(prose, isNotEmpty);
    expect(prose.first['html'], isNotNull);
    expect(prose.first['name'], isNotNull); // joined from quran_irab_book
  });

  test('VT-3 align_qac maps word_index → QAC word → ṣarf', () async {
    final db = await DatabaseHelper.instance.database;
    // near-full coverage: ~6196/6236 clean, the rest still get a partial map
    expect(
      Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM quran_align')),
      6236,
    );
    // al-Ikhlāṣ 112:1 — 4 words, 1:1 with QAC
    expect(await repo.qacWordFor(112, 1, 1), 1);
    expect(await repo.qacWordFor(112, 1, 3), 3);
    final sarf = await repo.morphologyForWord(112, 1, 3); // ٱللَّهُ
    expect(sarf, isNotNull);
    expect((sarf as Map)['text'], isNotNull);
    // an unaligned/absent word → null, never throws
    expect(() => repo.morphologyForWord(2, 255, 99), returnsNormally);
  });

  test('re-running sync is a no-op when sha is unchanged', () async {
    final db = await DatabaseHelper.instance.database;
    final before = (await db.query('quran_corpus_meta',
            columns: ['seeded_at_ms'],
            where: 'dataset = ?',
            whereArgs: ['morphology']))
        .first['seeded_at_ms'];
    await QuranCorpusSync().sync();
    final after = (await db.query('quran_corpus_meta',
            columns: ['seeded_at_ms'],
            where: 'dataset = ?',
            whereArgs: ['morphology']))
        .first['seeded_at_ms'];
    expect(after, before, reason: 'unchanged sha → not re-seeded');
  });
}
