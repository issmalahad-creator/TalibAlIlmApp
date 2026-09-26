import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../db/database_helper.dart';

/// Phase 80 / QC2 — seeds the **Quran Corpus** (`quran_corpus_*`, migration
/// v54) from the bundled `assets/quran/corpus/` datasets built by
/// `tool/build_quran_corpus.py`.
///
/// Per dataset: compare the bundled `sha256` (from `corpus_manifest.json`)
/// against what's stored in `quran_corpus_meta`; if unchanged, skip. Else
/// bulk-insert inside one transaction and record the new sha. Every failure
/// is swallowed and reported — the reader never breaks because a corpus
/// dataset didn't seed.
///
/// Only the small, per-ayah-queried datasets are seeded here. Tafsīr /
/// translation / riwāya text is loaded on demand from its per-book gz asset
/// (`QuranBookCache`).
class QuranCorpusSync {
  static const _dir = 'assets/quran/corpus';
  static const _manifest = '$_dir/corpus_manifest.json';

  /// Datasets stored as `(surah, ayah) -> JSON` in a same-named table.
  static const _perAyahJson = <String, ({String table, String key})>{
    'align_qac': (table: 'quran_align', key: 'm'),
    'morphology': (table: 'quran_morphology', key: 'morphology'),
    'syntax': (table: 'quran_syntax', key: 'syntax'),
    'meanings': (table: 'quran_word_meaning', key: 'meanings'),
    'notes': (table: 'quran_note', key: 'notes'),
    'qiraat': (table: 'quran_qiraat', key: 'qiraat'),
    'similar': (table: 'quran_similar', key: 'similar'),
    'sayings': (table: 'quran_saying', key: 'sayings'),
    'tajweed': (table: 'quran_tajweed', key: 'spans'), // G-t1 — cpfair rule spans
  };

  Future<void> sync() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final man = jsonDecode(await rootBundle.loadString(_manifest))
          as Map<String, dynamic>;
      final datasets = (man['datasets'] as Map).cast<String, dynamic>();
      for (final entry in datasets.entries) {
        final name = entry.key;
        final meta = entry.value as Map<String, dynamic>;
        final sha = meta['sha256'] as String? ?? '';
        final stored = await _meta(db, name);
        if (stored == sha && sha.isNotEmpty) continue;
        try {
          await _seedOne(db, name, meta);
        } catch (e) {
          debugPrint('QuranCorpusSync: "$name" skipped ($e).');
        }
      }
    } catch (e) {
      debugPrint('QuranCorpusSync: sync skipped ($e).');
    }
  }

  Future<Map<String, dynamic>> _load(String name) async {
    final bytes = await rootBundle.load('$_dir/$name.json.gz');
    // Off the UI isolate — `sayings` alone is ~15 MB gzipped.
    return compute(_decodeGzJson, bytes.buffer.asUint8List());
  }

  Future<void> _seedOne(
      Database db, String name, Map<String, dynamic> meta) async {
    final obj = await _load(name);
    final rows = (obj['rows'] as List?) ?? const [];
    final sha = meta['sha256'] as String? ?? '';

    await db.transaction((txn) async {
      final batch = txn.batch();

      if (_perAyahJson.containsKey(name)) {
        final spec = _perAyahJson[name]!;
        await txn.delete(spec.table);
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert(spec.table, {
            'surah': m['s'],
            'ayah': m['a'],
            'data': jsonEncode(m[spec.key]),
          });
        }
      } else {
        await _seedIndex(txn, batch, name, rows);
      }

      await batch.commit(noResult: true);
      await txn.insert(
        'quran_corpus_meta',
        {
          'dataset': name,
          'source': meta['source'],
          'source_version': meta['source_version'],
          'sha256': sha,
          'licence': meta['licence'],
          'rows': meta['rows'],
          'seeded_at_ms': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    debugPrint('QuranCorpusSync: seeded "$name" (${rows.length}).');
  }

  Future<void> _seedIndex(
      Transaction txn, Batch batch, String name, List rows) async {
    // Index datasets wrap a single object: rows = [ { <coll>: [...] } ].
    final inner = rows.isEmpty ? const <String, dynamic>{} : rows.first as Map;

    switch (name) {
      case 'nasekh':
        await txn.delete('quran_nasekh');
        for (final r in (inner['entries'] as List? ?? const [])) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_nasekh', {
            'surah': m['s'],
            'ayah': m['a'],
            'data': jsonEncode({'html': m['html']}),
          });
        }
      case 'irab_books':
        await txn.delete('quran_irab_book');
        await txn.delete('quran_irab_prose');
        for (final b in (inner['books'] as List? ?? const [])) {
          final m = b as Map<String, dynamic>;
          batch.insert('quran_irab_book', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'author': m['author'], 'year': m['year']?.toString(),
          });
        }
        for (final e in (inner['entries'] as List? ?? const [])) {
          final m = e as Map<String, dynamic>;
          batch.insert('quran_irab_prose', {
            'book_id': m['b'], 'surah': m['s'], 'ayah': m['a'], 'html': m['html'],
          });
        }
      case 'asbab_books':
        await txn.delete('quran_asbab_book');
        await txn.delete('quran_asbab');
        for (final b in (inner['books'] as List? ?? const [])) {
          final m = b as Map<String, dynamic>;
          batch.insert('quran_asbab_book', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'author': m['author'], 'year': m['year']?.toString(),
          });
        }
        for (final e in (inner['entries'] as List? ?? const [])) {
          final m = e as Map<String, dynamic>;
          batch.insert('quran_asbab', {
            'book_id': m['b'], 'surah': m['s'], 'ayah': m['a'], 'html': m['html'],
          });
        }
      case 'topics':
        await txn.delete('quran_topic');
        await txn.delete('quran_topic_ayah');
        for (final t in (inner['topics'] as List? ?? const [])) {
          final m = t as Map<String, dynamic>;
          batch.insert('quran_topic',
              {'id': m['id'], 'name': m['name'], 'parent_id': m['parent']});
        }
        for (final l in (inner['links'] as List? ?? const [])) {
          final m = l as Map<String, dynamic>;
          batch.insert('quran_topic_ayah', {
            'topic_id': m['t'], 'surah': m['s'],
            'ayah_from': m['a1'], 'ayah_to': m['a2'],
          });
        }
      case 'tafsir_index':
        await txn.delete('quran_tafsir_book');
        for (final b in (inner['books'] as List? ?? const [])) {
          final m = b as Map<String, dynamic>;
          batch.insert('quran_tafsir_book', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'author': m['author'], 'year': m['year']?.toString(),
            'nasher': m['nasher'],
            'bundled': (m['bundled'] == true) ? 1 : 0, 'ayat': m['ayat'],
          });
        }
      case 'translations_index':
        await txn.delete('quran_translation_edition');
        for (final e in (inner['editions'] as List? ?? const [])) {
          final m = e as Map<String, dynamic>;
          batch.insert('quran_translation_edition', {
            'id': m['id'], 'name': m['name'], 'short': m['short'],
            'lang': m['lang'], 'locale': m['locale'], 'direction': m['dir'],
            'licence': 'author-ip', 'ayat': m['ayat'],
          });
        }
      case 'riwaya_index':
        await txn.delete('quran_riwaya');
        for (final r in (inner['riwayat'] as List? ?? const [])) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_riwaya', {
            'id': m['id'], 'name': m['name'], 'rawi': m['rawi'],
            'is_primary': (m['primary'] == true) ? 1 : 0, 'ayat': m['ayat'],
          });
        }
      case 'reciters':
        await txn.delete('quran_reciter');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_reciter', {
            'id': m['id'], 'name_ar': m['name_ar'], 'name_en': m['name_en'],
            'riwaya_ar': m['riwaya_ar'], 'audio_base': m['audio_base'],
          });
        }
      case 'book_catalog':
        await txn.delete('quran_book');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_book', {
            'id': m['id'], 'type': m['type'], 'name': m['name'],
            'short': m['short'], 'author': m['author'],
            'year': m['year']?.toString(), 'lang': m['lang'],
          });
        }
      case 'surah_info':
        await txn.delete('quran_surah_info');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_surah_info',
              {'surah': m['s'], 'intro_html': m['intro_html']});
        }
      case 'fatwas':
        await txn.delete('quran_fatwa');
        for (final r in rows) {
          final m = r as Map<String, dynamic>;
          batch.insert('quran_fatwa', {
            'id': m['id'], 'title': m['title'], 'question': m['q'],
            'answer': m['a'], 'ref': m['ref']?.toString(),
          });
        }
      default:
        throw StateError('no seeder for corpus dataset "$name"');
    }
  }

  Future<String?> _meta(DatabaseExecutor db, String dataset) async {
    final rows = await db.query('quran_corpus_meta',
        columns: ['sha256'], where: 'dataset = ?', whereArgs: [dataset], limit: 1);
    return rows.isEmpty ? null : rows.first['sha256'] as String?;
  }
}

Map<String, dynamic> _decodeGzJson(List<int> gz) =>
    jsonDecode(utf8.decode(gzip.decode(gz))) as Map<String, dynamic>;
