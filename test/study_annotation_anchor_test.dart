import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/utils/study_annotation_anchor.dart';

/// Phase 79 «علامات الدراسة» — the pure re-anchoring unit. No Flutter, no DB.
/// The one rule under test: a stored anchor resolves to the **full** range
/// the user selected, across lines, even after the page text drifts.

StoredAnchor _anchorFor(String pageText, int start, int end, {int? forceNormVersion}) {
  final cap = captureAnchor(pageText, start, end);
  return StoredAnchor(
    selectedText: pageText.substring(start, end),
    charStart: start,
    charEnd: end,
    normVersion: forceNormVersion ?? cap.normVersion,
    textChecksum: cap.textChecksum,
    textLength: cap.textLength,
    prefixContext: cap.prefixContext,
    suffixContext: cap.suffixContext,
    headAnchor: cap.headAnchor,
    tailAnchor: cap.tailAnchor,
    occurrenceIndex: cap.occurrenceIndex,
  );
}

void main() {
  group('normalizePageText', () {
    test('strips HTML, collapses spaces, caps blank runs, is idempotent', () {
      const raw = '<p>الحمد   لله</p>\r\n\r\n\r\n\r\nرب <b>العالمين</b>  ';
      final once = normalizePageText(raw);
      expect(once, 'الحمد لله\n\nرب العالمين');
      expect(normalizePageText(once), once, reason: 'must be idempotent');
    });

    test('stays fast on pathological whitespace / markup (no O(n^2) regex)', () {
      // A `<[^>]*>` strip and a ` *\n *` collapse both backtrack O(n^2) on
      // these; the reader ran this synchronously and froze for seconds.
      final pathological = [
        ' ' * 60000, // a huge run of spaces, no newline
        ('كلمة    ' * 4000), // repeated short space runs
        ('سطر\n' * 3000).replaceAll('\n', '   \n   '), // spaces hugging newlines
        '<' * 40000, // many unclosed angle brackets
        '<span>x</span>\n\n\n  ' * 8000, // realistic-ish but large
      ];
      for (final input in pathological) {
        final sw = Stopwatch()..start();
        final out = normalizePageText(input);
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(500),
            reason: 'input length ${input.length} took ${sw.elapsedMilliseconds}ms');
        expect(out.contains('  '), isFalse);
        expect(out.contains('\n\n\n'), isFalse);
      }
    });

    test('checksum changes iff the normalized text changes', () {
      final a = normalizePageText('الحمد لله رب العالمين');
      final b = normalizePageText('الحمد   لله رب العالمين'); // same after normalize
      final c = normalizePageText('الحمد لله رب العالمين الرحمن');
      expect(pageChecksum(a), pageChecksum(b));
      expect(pageChecksum(a), isNot(pageChecksum(c)));
    });
  });

  group('resolveAnchor', () {
    const page = 'بسم الله الرحمن الرحيم\n'
        'الحمد لله رب العالمين الرحمن الرحيم\n'
        'مالك يوم الدين إياك نعبد وإياك نستعين\n'
        'اهدنا الصراط المستقيم';

    test('exact: unchanged page → same full range', () {
      final norm = normalizePageText(page);
      final start = norm.indexOf('الحمد');
      final end = norm.indexOf('الدين') + 'الدين'.length; // spans two newlines
      final a = _anchorFor(norm, start, end);

      final r = resolveAnchor(norm, a);
      expect(r.status, AnchorStatus.exact);
      expect(norm.substring(r.start!, r.end!), a.selectedText);
      expect(r.end! - r.start!, a.selectedText!.length);
      expect(a.selectedText, contains('\n'), reason: 'this selection really does cross lines');
    });

    test('shifted: text prepended → offsets move, full selection preserved', () {
      final norm = normalizePageText(page);
      final start = norm.indexOf('مالك يوم الدين');
      final end = norm.indexOf('نستعين') + 'نستعين'.length;
      final a = _anchorFor(norm, start, end);

      final moved = normalizePageText(page).replaceFirst('بسم الله الرحمن الرحيم\n', 'مقدمة الناسخ هنا\n\nبسم الله الرحمن الرحيم\n');
      final r = resolveAnchor(moved, a);
      expect(r.status, AnchorStatus.shifted);
      expect(moved.substring(r.start!, r.end!), a.selectedText);
    });

    test('shifted + duplicate: context disambiguates the right occurrence', () {
      const dup = 'قال المؤلف رحمه الله ثم قال المؤلف رحمه الله مرة أخرى';
      final norm = normalizePageText(dup);
      final second = norm.indexOf('قال المؤلف', norm.indexOf('قال المؤلف') + 1);
      final a = _anchorFor(norm, second, second + 'قال المؤلف رحمه الله'.length);

      // page unchanged except a leading char so the fast path is skipped
      final shifted = 'ــ$norm';
      final r = resolveAnchor(shifted, a);
      expect(r.status, AnchorStatus.shifted);
      expect(r.start, second + 2, reason: 'must land on the SECOND occurrence, not the first');
      expect(shifted.substring(r.start!, r.end!), a.selectedText);
    });

    test('fuzzy head/tail: interior word changed → span still covers head..tail', () {
      final norm = normalizePageText(page);
      final start = norm.indexOf('الحمد لله رب العالمين');
      final end = norm.indexOf('نعبد') + 'نعبد'.length;
      final a = _anchorFor(norm, start, end);

      final edited = norm.replaceFirst('إياك نعبد', 'إيّاكَ نعبد'); // interior changed
      final r = resolveAnchor(edited, a);
      expect(r.status, AnchorStatus.fuzzy);
      expect(r.start, isNotNull);
      expect(edited.substring(r.start!, r.end!), startsWith('الحمد'));
      expect(edited.substring(r.start!, r.end!), endsWith('نعبد'));
    });

    test('orphan: selection gone entirely → kept but not drawable', () {
      final norm = normalizePageText(page);
      final start = norm.indexOf('اهدنا الصراط المستقيم');
      final a = _anchorFor(norm, start, start + 'اهدنا الصراط المستقيم'.length);

      final r = resolveAnchor('نص مختلف تمامًا لا صلة له بالأصل إطلاقًا', a);
      expect(r.status, AnchorStatus.orphan);
      expect(r.drawable, isFalse);
      expect(a.selectedText, 'اهدنا الصراط المستقيم', reason: 'the annotation still keeps its full text');
    });

    test('stale norm_version alone does not orphan an otherwise-present selection', () {
      final norm = normalizePageText(page);
      final start = norm.indexOf('مالك يوم الدين');
      final a = _anchorFor(norm, start, start + 'مالك يوم الدين'.length, forceNormVersion: 0);

      final r = resolveAnchor(norm, a);
      expect(r.status, AnchorStatus.shifted); // fast path skipped, but found verbatim
      expect(norm.substring(r.start!, r.end!), a.selectedText);
    });
  });

  group('captureAnchor', () {
    test('head/tail are locators, never a truncation of the stored selection', () {
      final norm = normalizePageText('أ' * 200); // 200-char selection, longer than the 64 window
      final a = _anchorFor(norm, 0, 200);
      expect(a.selectedText!.length, 200, reason: 'selection stored in FULL');
      expect(a.headAnchor!.length, 64);
      expect(a.tailAnchor!.length, 64);

      final r = resolveAnchor(norm, a);
      expect(r.end! - r.start!, 200);
    });
  });

  // Ismail's explicit Phase-A shape list: every kind of selection round-trips
  // with its FULL text preserved and char_end - char_start == its length.
  group('selection shapes — full text preserved, not the first word', () {
    const page = 'قال الشيخ رحمه الله: «العِلمُ ثلاثةٌ، ثمّ سائرُ ذلك فَضلٌ».\n'
        'وهذا أصلٌ عظيمٌ في بابِ طلبِ العلم، تكلّم عليه العلماءُ قديمًا وحديثًا.\n'
        'فمن أخذ العلمَ من أهله، وصبر على ذلك، بلغ ما يريد بإذن الله تعالى.';

    void roundTrips(String label, String Function(String norm) pick) {
      test(label, () {
        final norm = normalizePageText(page);
        final target = pick(norm);
        final start = norm.indexOf(target);
        expect(start, isNot(-1), reason: 'test fixture: "$target" must be in the page');
        final end = start + target.length;
        final a = _anchorFor(norm, start, end);

        // stored selection == the whole thing, verbatim
        expect(a.selectedText, target);
        expect(a.selectedText!.length, target.length);
        expect(a.charEnd! - a.charStart!, a.selectedText!.length);

        final r = resolveAnchor(norm, a);
        expect(r.status, AnchorStatus.exact);
        expect(norm.substring(r.start!, r.end!), target,
            reason: 'the highlight must cover the ENTIRE selection, not its first word');
        expect(r.end! - r.start!, target.length);
      });
    }

    roundTrips('a single word', (n) => 'العلماءُ');
    roundTrips('a full sentence', (n) => 'وهذا أصلٌ عظيمٌ في بابِ طلبِ العلم، تكلّم عليه العلماءُ قديمًا وحديثًا.');
    roundTrips('several sentences', (n) {
      final s = n.indexOf('وهذا أصلٌ');
      return n.substring(s, n.indexOf('تعالى.') + 'تعالى.'.length);
    });
    roundTrips('several lines (crosses newlines)', (n) {
      final s = n.indexOf('«العِلمُ');
      final e = n.indexOf('وحديثًا.') + 'وحديثًا.'.length;
      final t = n.substring(s, e);
      expect(t, contains('\n'));
      return t;
    });
    roundTrips('Arabic with full tashkeel', (n) => '«العِلمُ ثلاثةٌ، ثمّ سائرُ ذلك فَضلٌ»');
    roundTrips('selection containing punctuation', (n) => 'رحمه الله: «العِلمُ ثلاثةٌ، ثمّ سائرُ ذلك فَضلٌ».');
    roundTrips('selection at the very start of the page', (n) => n.substring(0, n.indexOf('الله:') + 'الله:'.length));
    roundTrips('selection at the very end of the page', (n) => n.substring(n.indexOf('فمن أخذ')));

    test('a whole-page selection stores every character', () {
      final norm = normalizePageText(page);
      final a = _anchorFor(norm, 0, norm.length);
      expect(a.selectedText, norm);
      expect(a.selectedText!.length, norm.length);
      expect(a.charEnd! - a.charStart!, norm.length);
      final r = resolveAnchor(norm, a);
      expect(r.end! - r.start!, norm.length);
    });
  });
}
