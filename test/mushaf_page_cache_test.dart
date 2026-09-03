import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/widgets/mushaf/mushaf_page_cache.dart';

/// Phase 80 / M4 — the decoded‑page cache: decodes real bundled art off the
/// UI isolate, preloads neighbours, and stays bounded (LRU).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cache = MushafPageCache.instance;

  setUp(cache.clear);

  test('load() decodes a real bundled page to an <svg> string', () async {
    final svg = await cache.load(3);
    expect(svg, isNotNull);
    expect(svg, contains('<svg'));
    expect(svg, contains('viewBox="0 0 382.68 547.09"'));
    expect(cache.has(3), isTrue);
  });

  test('out-of-range pages resolve to null, not a throw', () async {
    expect(await cache.load(0), isNull);
    expect(await cache.load(605), isNull);
  });

  test('peek() returns a resident page and does not load a missing one', () async {
    expect(cache.peek(50), isNull);
    await cache.load(50);
    expect(cache.peek(50), isNotNull);
    expect(cache.residentCount, 1);
  });

  test('concurrent load() of the same page shares one decode', () async {
    final a = cache.load(7);
    final b = cache.load(7);
    final r = await Future.wait([a, b]);
    expect(r[0], same(r[1]));
    expect(cache.residentCount, 1);
  });

  test('LRU cap holds at most 7 decoded pages, evicting least-recent', () async {
    for (var p = 1; p <= 12; p++) {
      await cache.load(p);
    }
    expect(cache.residentCount, lessThanOrEqualTo(7));
    // the last 7 loaded survive; the first ones are gone
    expect(cache.has(12), isTrue);
    expect(cache.has(11), isTrue);
    expect(cache.has(1), isFalse);
    expect(cache.has(5), isFalse);
  });

  test('peek() marks a page most-recently-used so it survives eviction', () async {
    for (var p = 1; p <= 7; p++) {
      await cache.load(p);
    }
    cache.peek(1); // touch the oldest
    await cache.load(8); // forces one eviction
    expect(cache.has(1), isTrue, reason: 'touched page 1 must survive');
    expect(cache.has(2), isFalse, reason: 'page 2 is now the least-recent');
  });

  test('preloadAround() decodes the neighbours', () async {
    await cache.load(300);
    cache.preloadAround(300); // fire-and-forget 299 & 301
    // give the background decodes a moment
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(cache.has(299), isTrue);
    expect(cache.has(301), isTrue);
  });

  test('preloadAround() clamps at the ends (no page 0 / 605)', () async {
    await cache.load(1);
    cache.preloadAround(1);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(cache.residentPages, isNot(contains(0)));
    expect(cache.has(2), isTrue);
  });
}
