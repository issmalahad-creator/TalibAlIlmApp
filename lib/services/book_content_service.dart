import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/book_content.dart';

class BookContentService {
  /// Whether this build has a real book-feed address. Builds made from
  /// `app_config.example.dart` (CI, every downloadable APK) carry a
  /// `REPLACE_WITH_…` placeholder, which is not a feed.
  static bool get configured => isFeedUrl(AppConfig.bookContentApiUrl);

  static bool isFeedUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
  }

  Future<BookContentFeed> fetch() async {
    if (!configured) return BookContentFeed.empty;
    try {
      final resp = await http.get(Uri.parse(AppConfig.bookContentApiUrl)).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return BookContentFeed.empty;
      return BookContentFeed.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } catch (_) {
      return BookContentFeed.empty;
    }
  }
}
