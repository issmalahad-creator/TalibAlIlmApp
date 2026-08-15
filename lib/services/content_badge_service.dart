import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_content.dart';
import 'notification_service.dart';

/// Tracks whether there's Telegram-relayed book content the student hasn't
/// opened the Book tab to see yet — drives the small dot badge on the
/// bottom-nav "الكتاب" item, and (separately, deduped) fires a one-shot
/// local notification the first time each new piece of content is seen.
class ContentBadgeService {
  ContentBadgeService._internal();
  static final ContentBadgeService instance = ContentBadgeService._internal();

  static const _seenKey = 'book_content_last_seen_signature';
  static const _notifiedKey = 'book_content_last_notified_signature';

  final ValueNotifier<bool> hasUnseen = ValueNotifier(false);
  final _notificationService = NotificationService();

  /// Covers every content type the feed can carry — books and the banner
  /// were previously missing here, so a new book or banner never flipped
  /// the badge (or could ever trigger a notification); only announcement
  /// text and generic items did.
  String _signature(BookContentFeed feed) {
    final newestBookId = feed.books.isEmpty ? '' : feed.books.first.id;
    final newestItemDate = feed.items.isEmpty ? '' : feed.items.first.date;
    final bannerSig = feed.banner == null ? '' : '${feed.banner!.url}|${feed.banner!.date}';
    return '${feed.announcement}|${feed.books.length}|$newestBookId|${feed.items.length}|$newestItemDate|$bannerSig';
  }

  bool _hasContent(BookContentFeed feed) =>
      feed.announcement.isNotEmpty || feed.items.isNotEmpty || feed.books.isNotEmpty || feed.banner != null;

  String _describe(BookContentFeed feed) {
    if (feed.books.isNotEmpty) return 'كتاب جديد: ${feed.books.first.title}';
    if (feed.banner != null) return 'بانر جديد من المشرف';
    if (feed.announcement.isNotEmpty) return feed.announcement;
    return 'محتوى جديد من المشرف';
  }

  Future<void> checkForUnseen(BookContentFeed feed) async {
    final prefs = await SharedPreferences.getInstance();
    final signature = _signature(feed);
    final isNew = signature != (prefs.getString(_seenKey) ?? '') && _hasContent(feed);
    hasUnseen.value = isNew;

    if (isNew && signature != (prefs.getString(_notifiedKey) ?? '')) {
      await prefs.setString(_notifiedKey, signature);
      await _notificationService.showNewContentNotification(_describe(feed));
    }
  }

  Future<void> markSeen(BookContentFeed feed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenKey, _signature(feed));
    hasUnseen.value = false;
  }
}
