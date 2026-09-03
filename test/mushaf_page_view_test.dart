import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/models/mushaf_layout.dart';
import 'package:talib_alilm_app/widgets/mushaf_page_view.dart';

/// Phase 79 `79-mushaf` / خطة القارئ الموحّد — the Rendering + Interaction
/// Layer in isolation: the single page-level hit-test resolves a tap to a
/// word body or a verse-end medallion (never proximity), with a plain
/// [MushafPageLayout] and no database.
MushafPageLayout _layout() => MushafPageLayout(
      page: 3,
      rect: const MushafBox(0, 0, kMushafViewBoxWidth, kMushafViewBoxHeight),
      viewBoxWidth: kMushafViewBoxWidth,
      viewBoxHeight: kMushafViewBoxHeight,
      lines: const [MushafLineInfo(1, 'text'), MushafLineInfo(2, 'text')],
      words: const [
        MushafWord(
          page: 3, line: 1, wordOrder: 1, surah: 2, ayah: 6, wordIndex: 1,
          type: MushafWordType.text, textUthmani: 'إِنَّ', textImlaey: 'إن',
          box: MushafBox(300, 40, 40, 20),
        ),
        MushafWord(
          page: 3, line: 1, wordOrder: 2, surah: 2, ayah: 6, wordIndex: 2,
          type: MushafWordType.text, textUthmani: 'ٱلَّذِينَ', textImlaey: 'الذين',
          box: MushafBox(240, 40, 50, 20),
        ),
        MushafWord(
          page: 3, line: 2, wordOrder: 3, surah: 2, ayah: 7, wordIndex: 1,
          type: MushafWordType.text, textUthmani: 'خَتَمَ', textImlaey: 'ختم',
          box: MushafBox(300, 80, 40, 20),
        ),
      ],
      ayaMarks: const [
        MushafAyaMark(
          page: 3, line: 1, surah: 2, ayah: 6,
          box: MushafBox(220, 42, 14, 16),
        ),
      ],
      markers: const [],
    );

/// Mirror of [MushafPageView]'s content-fit transform (see `_contentBox`):
/// symmetric-X box around the words with headroom for a header line, then
/// centred in the viewport. Maps a point in source viewBox units to the
/// widget's local coordinates for a viewport of [size].
Offset _toWidget(MushafPageLayout l, Size size, Offset vb) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  final lineNos = <int>{};
  for (final w in l.words) {
    minX = w.box.x < minX ? w.box.x : minX;
    minY = w.box.y < minY ? w.box.y : minY;
    maxX = w.box.right > maxX ? w.box.right : maxX;
    maxY = w.box.bottom > maxY ? w.box.bottom : maxY;
    lineNos.add(w.line);
  }
  final cxc = l.viewBoxWidth / 2;
  final halfW = (cxc - minX).abs() > (maxX - cxc).abs()
      ? (cxc - minX).abs()
      : (maxX - cxc).abs();
  final lineH =
      lineNos.length > 1 ? (maxY - minY) / (lineNos.length - 1) : (maxY - minY);
  final top = minY - lineH * 0.5;
  final bottom = maxY + lineH * 0.5;

  final cx0 = cxc - halfW, cy0 = top, cw0 = halfW * 2, ch0 = bottom - top;
  final pad = 0.045 * (cw0 > ch0 ? cw0 : ch0);
  final cx = cx0 - pad, cy = cy0 - pad;
  final cw = cw0 + 2 * pad, ch = ch0 + 2 * pad;
  final scale =
      (size.width / cw) < (size.height / ch) ? size.width / cw : size.height / ch;
  final dx = (size.width - cw * scale) / 2 - cx * scale;
  final dy = (size.height - ch * scale) / 2 - cy * scale;
  return Offset(dx + vb.dx * scale, dy + vb.dy * scale);
}

/// Mirror of the M3 `MushafFitSource.contentRect` transform: fit the page's
/// own `rect` (md-page-inner data-rect) + a 9%-of-width margin (covers the
/// juz/surah headers + page number), centred in the viewport.
Offset _toWidgetContentRect(MushafPageLayout l, Size size, Offset vb) {
  final r = l.rect!;
  final pad = 0.09 * r.w;
  final cx = r.x - pad, cy = r.y - pad, cw = r.w + 2 * pad, ch = r.h + 2 * pad;
  final scale =
      (size.width / cw) < (size.height / ch) ? size.width / cw : size.height / ch;
  final dx = (size.width - cw * scale) / 2 - cx * scale;
  final dy = (size.height - ch * scale) / 2 - cy * scale;
  return Offset(dx + vb.dx * scale, dy + vb.dy * scale);
}

const _size = Size(kMushafViewBoxWidth, kMushafViewBoxHeight);

void main() {
  testWidgets('tap on a word body fires onWordTap with its identity',
      (tester) async {
    MushafWord? tappedWord;
    MushafAyaMark? tappedMark;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: kMushafViewBoxWidth,
            height: kMushafViewBoxHeight,
            child: MushafPageView(
              layout: _layout(),
              onWordTap: (w) => tappedWord = w,
              onAyaMarkTap: (m) => tappedMark = m,
            ),
          ),
        ),
      ),
    ));

    // centre of word 3 (surah 2 ayah 7): box (300,80,40,20) -> viewBox (320, 90)
    final topLeft = tester.getTopLeft(find.byType(MushafPageView));
    await tester.tapAt(topLeft + _toWidget(_layout(), _size, const Offset(320, 90)));
    await tester.pump();

    expect(tappedWord, isNotNull);
    expect(tappedWord!.wordOrder, 3);
    expect(tappedWord!.surah, 2);
    expect(tappedWord!.ayah, 7);
    expect(tappedMark, isNull); // a word tap is never an ayah tap
  });

  testWidgets('tap on a verse-end medallion fires onAyaMarkTap, not onWordTap',
      (tester) async {
    MushafWord? tappedWord;
    MushafAyaMark? tappedMark;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: kMushafViewBoxWidth,
          height: kMushafViewBoxHeight,
          child: MushafPageView(
            layout: _layout(),
            onWordTap: (w) => tappedWord = w,
            onAyaMarkTap: (m) => tappedMark = m,
          ),
        ),
      ),
    ));

    final topLeft = tester.getTopLeft(find.byType(MushafPageView));
    // centre of the mark box (220,42,14,16) -> viewBox (227, 50)
    await tester.tapAt(topLeft + _toWidget(_layout(), _size, const Offset(227, 50)));
    await tester.pump();

    expect(tappedMark, isNotNull);
    expect(tappedMark!.surah, 2);
    expect(tappedMark!.ayah, 6);
    expect(tappedWord, isNull);
  });

  testWidgets('long-press on a word fires onWordLongPress', (tester) async {
    MushafWord? longPressed;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: kMushafViewBoxWidth,
          height: kMushafViewBoxHeight,
          child: MushafPageView(
            layout: _layout(),
            onWordLongPress: (w) => longPressed = w,
          ),
        ),
      ),
    ));

    final topLeft = tester.getTopLeft(find.byType(MushafPageView));
    // centre of word 1 (surah 2 ayah 6): box (300,40,40,20) -> viewBox (320, 50)
    await tester.longPressAt(topLeft + _toWidget(_layout(), _size, const Offset(320, 50)));
    await tester.pump();

    expect(longPressed, isNotNull);
    expect(longPressed!.surah, 2);
    expect(longPressed!.ayah, 6);
    expect(longPressed!.wordIndex, 1);
  });

  testWidgets('a tap in empty space resolves to nothing', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: kMushafViewBoxWidth,
          height: kMushafViewBoxHeight,
          child: MushafPageView(
            layout: _layout(),
            onWordTap: (_) => tapped = true,
          ),
        ),
      ),
    ));
    final topLeft = tester.getTopLeft(find.byType(MushafPageView));
    // viewBox (250, 15) — above every word box (y >= 40), still on-screen
    await tester.tapAt(topLeft + _toWidget(_layout(), _size, const Offset(250, 15)));
    await tester.pump();
    expect(tapped, isFalse);
  });

  testWidgets('fitSource: contentRect — hit-test still resolves to the right word',
      (tester) async {
    MushafWord? tappedWord;
    MushafAyaMark? tappedMark;
    final l = _layout(); // rect = full viewBox
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: kMushafViewBoxWidth,
          height: kMushafViewBoxHeight,
          child: MushafPageView(
            layout: l,
            fitSource: MushafFitSource.contentRect,
            onWordTap: (w) => tappedWord = w,
            onAyaMarkTap: (m) => tappedMark = m,
          ),
        ),
      ),
    ));
    final topLeft = tester.getTopLeft(find.byType(MushafPageView));
    // word 3 centre: box (300,80,40,20) -> viewBox (320, 90)
    await tester
        .tapAt(topLeft + _toWidgetContentRect(l, _size, const Offset(320, 90)));
    await tester.pump();
    expect(tappedWord, isNotNull);
    expect(tappedWord!.wordOrder, 3);
    expect(tappedWord!.surah, 2);
    expect(tappedWord!.ayah, 7);
    // and the medallion still wins where it should: mark box (220,42,14,16)
    await tester
        .tapAt(topLeft + _toWidgetContentRect(l, _size, const Offset(227, 50)));
    await tester.pump();
    expect(tappedMark, isNotNull);
    expect(tappedMark!.surah, 2);
    expect(tappedMark!.ayah, 6);
  });

  testWidgets('selectedAyah / selectedWord paint the Selection Layer',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: kMushafViewBoxWidth,
          height: kMushafViewBoxHeight,
          child: MushafPageView(
            layout: _layout(),
            selectedAyah: (surah: 2, ayah: 6),
            selectedWord: _layout().words.first,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CustomPaint), findsWidgets);
    // ayah 2:6 is all on line 1 -> ayahBoxes returns 1 box
    expect(_layout().ayahBoxes(2, 6).length, 1);
  });
}
