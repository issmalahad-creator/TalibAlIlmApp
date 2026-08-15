import 'book_of_month.dart';

/// One piece of content pushed by the admin via the Telegram bot (a PDF
/// document or a photo) and relayed into the Sheet by the content Apps
/// Script. See CLAUDE.md "Book content feed (Telegram-controlled)".
class ContentItem {
  final String type; // "document" | "photo"
  final String title;
  final String url; // direct Telegram file URL
  final String date;

  ContentItem({required this.type, required this.title, required this.url, required this.date});

  bool get isPdf => type == 'document' && title.toLowerCase().trim().endsWith('.pdf');

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
        date: json['date']?.toString() ?? '',
      );
}

/// One book the admin has sent via Telegram (`كتاب: <title>`) — books
/// accumulate as a list (they don't replace each other), each keeping its
/// own quiz. `id` is a stable key (the Apps Script's creation timestamp
/// string) used for per-book reading progress/quiz-result storage.
class BookEntry {
  final String id;
  final String title;
  final String url;
  final String date;
  final List<QuizQuestion> quiz;

  BookEntry({required this.id, required this.title, required this.url, required this.date, required this.quiz});

  factory BookEntry.fromJson(Map<String, dynamic> json) => BookEntry(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        url: json['url'] as String? ?? '',
        date: json['date']?.toString() ?? '',
        quiz: ((json['quiz'] as List?) ?? [])
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

/// An eye-catching image banner the admin pushes via Telegram (photo with a
/// `بانر:` caption, or via the bot's "🖼 إرسال بانر" menu option). A single
/// current banner, same overwrite-in-place pattern as [BookContentFeed.announcement]
/// rather than an accumulating list — it's meant to be one active promo/notice
/// at a time, not a gallery.
class BannerInfo {
  final String caption;
  final String url;
  final String date;

  BannerInfo({required this.caption, required this.url, required this.date});

  factory BannerInfo.fromJson(Map<String, dynamic> json) => BannerInfo(
        caption: json['caption'] as String? ?? '',
        url: json['url'] as String? ?? '',
        date: json['date']?.toString() ?? '',
      );
}

/// One past announcement or banner — kept as an append-only log server-side
/// (v6 relay) separate from the single "current" one shown live, so a
/// student can browse what was said before, not just what's live right now.
class ContentHistoryEntry {
  final String type; // 'announcement' | 'banner'
  final String text;
  final String url; // banner image url; empty for announcement entries
  final String date;

  ContentHistoryEntry({required this.type, required this.text, required this.url, required this.date});

  factory ContentHistoryEntry.fromJson(Map<String, dynamic> json) => ContentHistoryEntry(
        type: json['type'] as String? ?? '',
        text: json['text'] as String? ?? '',
        url: json['url'] as String? ?? '',
        date: json['date']?.toString() ?? '',
      );
}

/// One admin-authored FAQ entry ("سؤال شائع: ... / الجواب: ..." via
/// Telegram) — a simple, growing reference list any student can read from
/// the Support screen. Not tied to any specific book.
class FaqEntry {
  final String question;
  final String answer;
  final String date;

  FaqEntry({required this.question, required this.answer, required this.date});

  factory FaqEntry.fromJson(Map<String, dynamic> json) => FaqEntry(
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        date: json['date']?.toString() ?? '',
      );
}

class BookContentFeed {
  final String announcement;
  final BannerInfo? banner;
  final List<BookEntry> books;
  final List<ContentItem> items;
  final List<ContentHistoryEntry> history;
  final List<FaqEntry> faq;

  BookContentFeed(
      {required this.announcement,
      this.banner,
      required this.books,
      required this.items,
      this.history = const [],
      this.faq = const []});

  factory BookContentFeed.fromJson(Map<String, dynamic> json) => BookContentFeed(
        announcement: json['announcement'] as String? ?? '',
        banner: json['banner'] == null ? null : BannerInfo.fromJson(json['banner'] as Map<String, dynamic>),
        books: ((json['books'] as List?) ?? [])
            .map((b) => BookEntry.fromJson(b as Map<String, dynamic>))
            .toList(),
        items: ((json['items'] as List?) ?? [])
            .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: ((json['history'] as List?) ?? [])
            .map((h) => ContentHistoryEntry.fromJson(h as Map<String, dynamic>))
            .toList(),
        faq: ((json['faq'] as List?) ?? []).map((f) => FaqEntry.fromJson(f as Map<String, dynamic>)).toList(),
      );

  static final empty =
      BookContentFeed(announcement: '', banner: null, books: [], items: [], history: [], faq: []);
}
