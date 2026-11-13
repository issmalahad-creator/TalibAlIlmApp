import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/models/mushaf_layout.dart';
import 'package:talib_alilm_app/widgets/mushaf/surah_header_frame.dart';
import 'package:talib_alilm_app/widgets/mushaf_page_view.dart';

/// The ornate surah-title frame (Ismail 2026-11-13): one frame per
/// surah-name line, under the art, never on the decorated pages 1–2.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final layout = jsonDecode(utf8.decode(gzip.decode(
          File('assets/mushaf/mushaf_layout.json.gz').readAsBytesSync())))
      as Map<String, dynamic>;
  final pages = {
    for (final p in (layout['pages'] as List).cast<Map<String, dynamic>>()) p['page'] as int: p,
  };

  List<SurahHeaderFrame> framesOn(WidgetTester t) {
    final paints = t.widgetList<CustomPaint>(find.byType(CustomPaint));
    for (final p in paints) {
      if (p.painter is SurahHeaderFramePainter) return (p.painter! as SurahHeaderFramePainter).frames;
    }
    return const [];
  }

  Future<void> pumpPage(WidgetTester t, int page, {bool frames = true}) async {
    await t.binding.setSurfaceSize(const Size(392, 820));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      home: MushafPageView(
        layout: MushafPageLayout.fromJson(pages[page]!),
        spreadLines: true,
        surahFrames: frames,
      ),
    ));
  }

  testWidgets('page 604 (al-Ikhlāṣ, al-Falaq, an-Nās) gets three frames, top to bottom, inside the page',
      (t) async {
    await pumpPage(t, 604);
    final f = framesOn(t);
    expect(f.length, 3);
    for (var i = 1; i < f.length; i++) {
      expect(f[i].band.top, greaterThan(f[i - 1].band.bottom)); // never overlap
    }
    for (final x in f) {
      expect(const Rect.fromLTWH(0, 0, 392, 820).contains(x.band.topLeft), isTrue);
      expect(x.band.width, greaterThan(300)); // the full text width
    }
  });

  testWidgets('a page without a surah start has none; the decorated opening pages have none',
      (t) async {
    await pumpPage(t, 3);
    expect(framesOn(t), isEmpty);
    await pumpPage(t, 2);
    expect(framesOn(t), isEmpty);
  });

  testWidgets('frames can be switched off', (t) async {
    await pumpPage(t, 586, frames: false);
    expect(framesOn(t), isEmpty);
  });

  test('the painter draws every frame size without throwing, day and night', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (final night in [false, true]) {
      SurahHeaderFramePainter(night: night, frames: const [
        SurahHeaderFrame(Rect.fromLTWH(10, 10, 360, 44)),
        SurahHeaderFrame(Rect.fromLTWH(10, 80, 900, 90)), // tablet
        SurahHeaderFrame(Rect.fromLTWH(10, 200, 120, 20)), // tiny
        SurahHeaderFrame(Rect.fromLTWH(10, 240, 30, 5)), // degenerate → skipped
      ]).paint(canvas, const Size(1000, 400));
    }
    recorder.endRecording();
  });
}
