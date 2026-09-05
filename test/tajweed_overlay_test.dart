import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:talib_alilm_app/db/database_helper.dart';
import 'package:talib_alilm_app/models/mushaf_layout.dart';
import 'package:talib_alilm_app/models/tajweed_span.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_repository.dart';
import 'package:talib_alilm_app/repositories/mushaf_layout_sync.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_repository.dart';
import 'package:talib_alilm_app/repositories/quran_corpus_sync.dart';
import 'package:talib_alilm_app/widgets/mushaf/tajweed_overlay.dart';

/// Phase G-t3 — the opt-in tajwīd page layer. The precompute
/// ([buildTajweedPaintSpans]) turns real rule spans × real glyph geometry
/// into boxes that sit inside their words; the overlay draws nothing when
/// off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final corpus = QuranCorpusRepository();
  final layoutRepo = MushafLayoutRepository();

  setUpAll(() async {
    DatabaseHelper.databaseName = 'talib_tajweed_overlay_test.db';
    final f = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases',
        DatabaseHelper.databaseName));
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    await QuranCorpusSync().sync();
    await MushafLayoutSync().sync();
  });

  test('empty inputs → no paint spans', () {
    final spans = buildTajweedPaintSpans(
      words: const [],
      tajweedByAyah: const {},
      glyphsByWordOrder: const {},
    );
    expect(spans, isEmpty);
  });

  test('page 1 (al-Fātiḥa) → spans, each inside its word box', () async {
    final layout = await layoutRepo.pageLayout(1);
    expect(layout, isNotNull);
    final glyphs = await layoutRepo.glyphsForPage(1);
    expect(glyphs, isNotEmpty);

    final byAyah = <String, AyahTajweed>{};
    for (final w in layout!.words) {
      if (w.type != MushafWordType.text) continue;
      byAyah['${w.surah}:${w.ayah}'] =
          await corpus.tajweedForAyah(w.surah, w.ayah);
    }

    final spans = buildTajweedPaintSpans(
      words: layout.words,
      tajweedByAyah: byAyah,
      glyphsByWordOrder: glyphs,
    );
    expect(spans.length, greaterThan(5)); // al-Fātiḥa is rule-dense

    // every span's bounds sit inside some word box on the page
    final wordBoxes = [
      for (final w in layout.words)
        if (w.type == MushafWordType.text) w.box
    ];
    for (final s in spans) {
      expect(s.boxes, isNotEmpty);
      final b = s.bounds;
      final inAWord = wordBoxes.any((wb) =>
          b.x >= wb.x - 1.0 &&
          b.y >= wb.y - 1.0 &&
          b.x + b.w <= wb.x + wb.w + 1.0 &&
          b.y + b.h <= wb.y + wb.h + 1.0);
      expect(inAWord, isTrue, reason: 'span bounds $b not inside any word');
    }
    // hamzat al-waṣl on page 1 is an underline rule
    expect(spans.any((s) => s.underline), isTrue);
    // and there is at least one wash (madd)
    expect(spans.any((s) => !s.underline), isTrue);
  });

  testWidgets('overlay with no spans draws nothing; with spans it paints',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: TajweedPageOverlay(
            spans: [],
            scale: 1,
            offset: Offset.zero,
            night: false,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: TajweedPageOverlay(
            spans: const [
              TajweedPaintSpan(
                boxes: [MushafBox(10, 10, 20, 12)],
                color: Color(0xFFE11D48),
                underline: false,
              ),
              TajweedPaintSpan(
                boxes: [MushafBox(40, 10, 8, 12)],
                color: Color(0xFF9333EA),
                underline: true,
              ),
            ],
            scale: 2,
            offset: const Offset(5, 5),
            night: true,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
