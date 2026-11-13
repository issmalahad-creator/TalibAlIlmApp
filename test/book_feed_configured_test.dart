import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/book_content_service.dart';

/// Every downloadable APK is built from `app_config.example.dart`, whose
/// book-feed address is a `REPLACE_WITH_…` placeholder — the «الكتاب» tab
/// must treat that as "no feed", not try to fetch it.
void main() {
  test('placeholders and empty strings are not a feed; real addresses are', () {
    expect(BookContentService.isFeedUrl(''), isFalse);
    expect(BookContentService.isFeedUrl('REPLACE_WITH_NEW_CONTENT_RELAY_APPS_SCRIPT_EXEC_URL'), isFalse);
    expect(BookContentService.isFeedUrl('https://'), isFalse);
    expect(BookContentService.isFeedUrl('https://script.google.com/macros/s/abc/exec'), isTrue);
  });
}
