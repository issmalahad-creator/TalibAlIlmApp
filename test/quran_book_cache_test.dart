import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/repositories/quran_book_cache.dart';

/// Phase 80 / QC2 — the on-demand per-book loader: bundled tafsīr /
/// translation / riwāya text resolves by `(surah, ayah)`; a Supabase-mirror
/// tafsīr is flagged, not an error.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cache = QuranBookCache.instance;
  setUp(cache.clear);

  test('bundled tafsīr (Muyassar, id 32) resolves an ayah', () async {
    final e = await cache.tafsirEntry(32, 1, 1);
    expect(e, isNotNull);
    expect(e!['text'], isA<String>());
    expect((e['text'] as String).length, greaterThan(20));
  });

  test('a Supabase-mirror tafsīr (روح المعاني, id 301) is flagged mirror',
      () async {
    final e = await cache.tafsirEntry(301, 1, 1);
    expect(e, isNotNull);
    expect(e!['mirror'], true);
    expect(e.containsKey('text'), isFalse);
  });

  test('translation text resolves for an edition', () async {
    final t = await cache.translation(13602, 1, 2);
    expect(t, isA<String>());
    expect(t!.trim(), isNotEmpty);
    expect(t, isNot(contains('<'))); // HTML was stripped at ingest
  });

  test('Hafs riwāya (id 1) gives text + verse marker', () async {
    final r = await cache.riwayaText(1, 114, 1);
    expect(r, isNotNull);
    expect(r!['text'], isA<String>());
    expect(r['marker'], isNotNull);
  });

  test('out-of-range ayah / unknown book → null, never throws', () async {
    expect(await cache.translation(13602, 1, 999), isNull);
    expect(await cache.riwayaText(1, 200, 1), isNull);
  });

  test('LRU keeps at most 4 books resident', () async {
    await cache.tafsirEntry(32, 1, 1);
    await cache.tafsirEntry(3, 1, 1); // Saʿdī (bundled)
    await cache.translation(13602, 1, 1);
    await cache.riwayaText(1, 1, 1);
    await cache.tafsirEntry(272, 1, 1); // Jalālayn (bundled) → 5th, forces evict
    expect(cache.residentCount, lessThanOrEqualTo(4));
  });
}
