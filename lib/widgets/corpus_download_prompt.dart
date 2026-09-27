import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import 'packs/pack_ui.dart';

/// Asks before one Quran corpus book (a tafsir / translation / riwāya that
/// the lite build doesn't bundle) is downloaded from `corpus-v1` — now the
/// same sheet as content packs: the book's own name and author, its size,
/// the network you're on. Returns true only on an explicit «حمّل الآن».
Future<bool> askCorpusDownload(BuildContext context, String category, int id, int? bytes) async {
  final (title, author) = await _bookName(category, id);
  if (!context.mounted) return false;
  final choice = await askDownloadSheet(
    context,
    title: title,
    author: author,
    kind: category == 'translations' ? 'translation' : 'tafsir',
    bytes: bytes,
    allowWhenWifi: false, // this path downloads inline, it can't wait
  );
  return choice == DownloadChoice.now;
}

Future<(String, String?)> _bookName(String category, int id) async {
  final table = switch (category) {
    'tafsir' => 'quran_tafsir_book',
    'translations' => 'quran_translation_edition',
    _ => 'quran_riwaya',
  };
  try {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) {
      final r = rows.first;
      final author = (r['author'] ?? r['rawi']) as String?;
      return ((r['name'] as String?) ?? '#$id', author);
    }
  } catch (_) {}
  return ('#$id', null);
}
