import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/turath_api_client.dart';

/// Real integration tests against the live turath.io API (Phase 79) --
/// deliberately not mocked. Same discipline as this project's other work:
/// verify against the real thing, not an assumed shape. These need
/// network access; if turath.io is ever unreachable in a CI environment,
/// that's a real signal worth seeing, not something to hide behind a mock.
void main() {
  final client = TurathApiClient();

  group('TurathApiClient (live)', () {
    test('search returns real results for a common Arabic word', () async {
      final results = await client.search('الصلاة');
      expect(results.count, greaterThan(0));
      expect(results.results, isNotEmpty);
      final first = results.results.first;
      expect(first.bookName, isNotEmpty);
      expect(first.snippet, isNotEmpty);
    });

    test('getBookInfo returns real data for Fath al-Bari by Ibn Rajab (book 137)', () async {
      final book = await client.getBookInfo(137);
      expect(book.id, 137);
      expect(book.name, contains('فتح الباري'));
      expect(book.indexes, isNotEmpty);
      expect(book.indexes.first.title, isNotEmpty);
    });

    test('getPage returns the real first page of book 137', () async {
      final page = await client.getPage(137, 1);
      expect(page.bookId, 137);
      expect(page.text, isNotEmpty);
    });

    test('getBookInfo throws a clean 404 exception for a non-existent book', () async {
      expect(
        () => client.getBookInfo(999999999),
        throwsA(isA<TurathApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
