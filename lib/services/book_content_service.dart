import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/book_content.dart';

class BookContentService {
  Future<BookContentFeed> fetch() async {
    if (AppConfig.bookContentApiUrl.isEmpty) return BookContentFeed.empty;
    try {
      final resp = await http.get(Uri.parse(AppConfig.bookContentApiUrl)).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return BookContentFeed.empty;
      return BookContentFeed.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    } catch (_) {
      return BookContentFeed.empty;
    }
  }
}
