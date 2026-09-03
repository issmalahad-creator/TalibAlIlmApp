import 'dart:convert';
import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/data/quran_surahs.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/mushaf_layout.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_repository.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_sync.dart';

/// Phase 80 / M5 — the 604-page QA gate.
///
/// Iterates every one of the 604 pages and emits a per-page PASS/FAIL over
/// **geometry**, **data** and **visual** integrity, writing
/// `docs/quran/reports/mushaf_qa_report.json` + `MUSHAF_QA_REPORT.md`. The
/// bar (Ismail): **604/604 must pass all three** — anything less fails this
/// test. No `if (page == N)` anywhere: a failure is a data/renderer/geometry
/// bug to fix at the root.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const vbW = kMushafViewBoxWidth, vbH = kMushafViewBoxHeight;
  const eps = 1.0;
  final canon = {for (final s in quranSurahs) s.number: s.ayahCount};
  late MushafLayoutRepository repo;
  late Map<String, dynamic> manifest;

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_mushaf_qa604.db';
    final dbFile = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (dbFile.existsSync()) {
      try {
        dbFile.deleteSync();
      } catch (_) {}
    }
    final gz = File(p.join('assets', 'mushaf', 'mushaf_layout.json.gz'));
    final layout = jsonDecode(utf8.decode(gzip.decode(gz.readAsBytesSync())))
        as Map<String, dynamic>;
    final res = await MushafLayoutSync().ingestFromJson(layout);
    expect(res.outcome, 'seeded', reason: res.toString());
    repo = MushafLayoutRepository();
    manifest = jsonDecode(
            File(p.join('assets', 'mushaf', 'mushaf_manifest.json'))
                .readAsStringSync())
        as Map<String, dynamic>;
  });

  test('all 604 pages pass geometry + data + visual QA', () async {
    final rows = <Map<String, dynamic>>[];
    var gPass = 0, dPass = 0, vPass = 0;

    for (var page = 1; page <= 604; page++) {
      final notes = <String>[];
      final layout = await repo.pageLayout(page);

      // ---------- geometry ----------
      final gN = <String>[];
      if (layout == null) {
        gN.add('no layout row');
      } else {
        final lineNos = layout.lines.map((l) => l.line).toSet();
        if (layout.lines.isEmpty || layout.lines.length > 15) {
          gN.add('line_count=${layout.lines.length}');
        }
        final r = layout.rect;
        if (r == null) {
          gN.add('contentRect missing');
        } else if (!(r.w > 0 &&
            r.h > 0 &&
            r.x >= -eps &&
            r.y >= -eps &&
            r.right <= vbW + eps &&
            r.bottom <= vbH + eps)) {
          gN.add('contentRect out of range $r');
        }
        final orders = <int>[];
        for (final w in layout.words) {
          orders.add(w.wordOrder);
          final b = w.box;
          if (b.w <= 0 ||
              b.h <= 0 ||
              b.x < -eps ||
              b.y < -eps ||
              b.right > vbW + eps ||
              b.bottom > vbH + eps ||
              b.x.isNaN ||
              b.y.isNaN) {
            gN.add('word ${w.wordOrder} bad box $b');
            break;
          }
          if (!lineNos.contains(w.line)) {
            gN.add('word ${w.wordOrder} line ${w.line} not in mushaf_lines');
            break;
          }
          if (r != null &&
              (b.x < r.x - eps ||
                  b.right > r.right + eps ||
                  b.y < r.y - eps ||
                  b.bottom > r.bottom + eps)) {
            gN.add('word ${w.wordOrder} outside contentRect');
            break;
          }
        }
        orders.sort();
        for (var i = 0; i < orders.length; i++) {
          if (orders[i] != i + 1) {
            gN.add('word_order not contiguous at $i (${orders[i]})');
            break;
          }
        }
        for (final m in layout.ayaMarks) {
          final b = m.box;
          if (b == null) continue;
          if (b.x < -eps ||
              b.y < -eps ||
              b.right > vbW + eps ||
              b.bottom > vbH + eps) {
            gN.add('aya-mark ${m.surah}:${m.ayah} box out of range');
            break;
          }
        }
      }

      // ---------- data ----------
      final dN = <String>[];
      if (layout != null && layout.words.isNotEmpty) {
        // word_index contiguous 1..k per (surah,ayah) on this page
        final byAyah = <String, List<int>>{};
        for (final w in layout.words) {
          byAyah.putIfAbsent('${w.surah}:${w.ayah}', () => []).add(w.wordIndex);
        }
        byAyah.forEach((k, idx) {
          idx.sort();
          for (var i = 0; i < idx.length; i++) {
            if (idx[i] != i + 1) {
              dN.add('word_index broken for $k: $idx');
              break;
            }
          }
        });
        // aya-mark (s,a) set == word (s,a) set
        final wSet = layout.words.map((w) => '${w.surah}:${w.ayah}').toSet();
        final mSet = layout.ayaMarks.map((m) => '${m.surah}:${m.ayah}').toSet();
        final missMark = wSet.difference(mSet);
        final extraMark = mSet.difference(wSet);
        if (missMark.isNotEmpty) dN.add('ayat with no aya-mark: $missMark');
        if (extraMark.isNotEmpty) dN.add('aya-marks with no words: $extraMark');
        // text non-empty for real words
        for (final w in layout.words) {
          if (w.type == MushafWordType.text && w.textUthmani.trim().isEmpty) {
            dN.add('empty text_uthmani at word ${w.wordOrder}');
            break;
          }
        }
        // Madani boundary: page starts a new ayah
        if (layout.words.first.wordIndex != 1) {
          dN.add('page does not start on word_index 1 '
              '(${layout.words.first.surah}:${layout.words.first.ayah} '
              'w${layout.words.first.wordIndex})');
        }
        // surah then ayah monotonic non-decreasing in reading order
        final ordered = [...layout.words]
          ..sort((a, b) => a.wordOrder.compareTo(b.wordOrder));
        for (var i = 1; i < ordered.length; i++) {
          final a = ordered[i - 1], b = ordered[i];
          if (b.surah < a.surah ||
              (b.surah == a.surah && b.ayah < a.ayah)) {
            dN.add('non-monotonic at word ${b.wordOrder}');
            break;
          }
        }
        // per-surah sanity: any surah fully on this page must not exceed canon
        for (final w in layout.words) {
          final c = canon[w.surah];
          if (c != null && w.ayah > c) {
            dN.add('${w.surah}:${w.ayah} exceeds canon $c');
            break;
          }
        }
      } else {
        dN.add('no words');
      }

      // ---------- visual ----------
      final vN = <String>[];
      final gzf = File(p.join(
          'assets', 'mushaf', 'pages_svg', '${page.toString().padLeft(3, '0')}.svg.gz'));
      if (!gzf.existsSync()) {
        vN.add('gz missing');
      } else {
        String svg;
        try {
          svg = utf8.decode(gzip.decode(gzf.readAsBytesSync()));
        } catch (e) {
          vN.add('gunzip failed: $e');
          svg = '';
        }
        if (svg.isNotEmpty) {
          if (!svg.contains('<svg')) vN.add('no <svg');
          if (!svg.contains('viewBox="0 0 382.68 547.09"')) {
            vN.add('viewBox differs');
          }
          if (!svg.contains('preserveAspectRatio')) {
            vN.add('no preserveAspectRatio');
          }
          if (!svg.contains('<path')) vN.add('no <path');
          try {
            // the exact parse+compile flutter_svg does at render time
            await SvgStringLoader(svg).loadBytes(null);
          } catch (e) {
            vN.add('flutter_svg parse threw: $e');
          }
        }
      }

      final gOk = gN.isEmpty, dOk = dN.isEmpty, vOk = vN.isEmpty;
      if (gOk) gPass++;
      if (dOk) dPass++;
      if (vOk) vPass++;
      notes.addAll([...gN, ...dN, ...vN]);
      rows.add({
        'page': page,
        'geometry': gOk ? 'PASS' : 'FAIL',
        'data': dOk ? 'PASS' : 'FAIL',
        'visual': vOk ? 'PASS' : 'FAIL',
        'notes': notes,
      });
    }

    // ---------- write the reports ----------
    final reportDir = Directory(p.join('docs', 'quran', 'reports'));
    reportDir.createSync(recursive: true);
    final fails = rows
        .where((r) =>
            r['geometry'] != 'PASS' ||
            r['data'] != 'PASS' ||
            r['visual'] != 'PASS')
        .toList();
    final summary = {
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'art_set_sha256': manifest['art_set_sha256'],
      'layout_version': kMushafLayoutVersion,
      'pages': 604,
      'geometry_pass': gPass,
      'data_pass': dPass,
      'visual_pass': vPass,
      'all_pass': fails.isEmpty,
      'failing_pages': fails.map((r) => r['page']).toList(),
    };
    File(p.join(reportDir.path, 'mushaf_qa_report.json')).writeAsStringSync(
        const JsonEncoder.withIndent('  ')
            .convert({'summary': summary, 'pages': rows}));

    final md = StringBuffer()
      ..writeln('# Mushaf QA — 604-page geometry / data / visual gate')
      ..writeln()
      ..writeln('Generated ${summary['generated_at']} · '
          'layout v${summary['layout_version']} · '
          'art `${summary['art_set_sha256']}`')
      ..writeln()
      ..writeln('| check | pass |')
      ..writeln('|---|---|')
      ..writeln('| geometry | **$gPass / 604** |')
      ..writeln('| data | **$dPass / 604** |')
      ..writeln('| visual | **$vPass / 604** |')
      ..writeln()
      ..writeln(fails.isEmpty
          ? '**ALL 604 PAGES PASS.**'
          : '**${fails.length} FAILING PAGE(S):**')
      ..writeln();
    if (fails.isNotEmpty) {
      md.writeln('| pg | geom | data | visual | notes |');
      md.writeln('|---|---|---|---|---|');
      for (final r in fails) {
        md.writeln('| ${r['page']} | ${r['geometry']} | ${r['data']} | '
            '${r['visual']} | ${(r['notes'] as List).join('; ')} |');
      }
    }
    File(p.join(reportDir.path, 'MUSHAF_QA_REPORT.md'))
        .writeAsStringSync(md.toString());

    // ---------- the gate ----------
    expect(gPass, 604, reason: 'geometry failures: '
        '${fails.where((r) => r['geometry'] != 'PASS').map((r) => "${r['page']}:${r['notes']}").take(10)}');
    expect(dPass, 604, reason: 'data failures: '
        '${fails.where((r) => r['data'] != 'PASS').map((r) => "${r['page']}:${r['notes']}").take(10)}');
    expect(vPass, 604, reason: 'visual failures: '
        '${fails.where((r) => r['visual'] != 'PASS').map((r) => "${r['page']}:${r['notes']}").take(10)}');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('post-QA cross-check: seeded totals still canonical', () async {
    final db = await DatabaseHelper.instance.database;
    expect(await repo.pageCount(), 604);
    expect(
      Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM mushaf_aya_marks')),
      6236,
    );
    expect(
      Sqflite.firstIntValue(await db
          .rawQuery('SELECT COUNT(*) FROM (SELECT DISTINCT surah FROM mushaf_words)')),
      114,
    );
  });
}
