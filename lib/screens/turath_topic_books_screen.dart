import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_book_screen.dart';

/// "تصفح التصنيفات" (spec item 1) — real, but honestly scoped: turath.io's
/// public API has **no category-listing endpoint** (verified 2026-08-28 by
/// reading the real `turath-sdk` source directly -- `search` accepts an
/// optional `cat_id` filter, but there is no way to enumerate categories
/// or list a category's books from the API itself; a curated ID→name
/// table would mean guessing numeric IDs, which this project's discipline
/// forbids). Instead of faking a categories browser, each "topic" here is
/// a real subject-term search whose results are grouped by book -- a
/// genuine, live "browse books about X" experience built from real data,
/// not a static list wearing an API's clothes.
class TurathTopicBooksScreen extends StatefulWidget {
  final String topicQuery;
  final String topicLabel;
  const TurathTopicBooksScreen({super.key, required this.topicQuery, required this.topicLabel});

  @override
  State<TurathTopicBooksScreen> createState() => _TurathTopicBooksScreenState();
}

enum _Status { loading, success, empty, error }

class _BookGroup {
  final int bookId;
  final String bookName;
  final String authorName;
  final String snippet;
  const _BookGroup({required this.bookId, required this.bookName, required this.authorName, required this.snippet});
}

class _TurathTopicBooksScreenState extends State<TurathTopicBooksScreen> {
  final _repo = TurathRepository();
  _Status _status = _Status.loading;
  List<_BookGroup> _books = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    try {
      final results = await _repo.search(widget.topicQuery);
      if (!mounted) return;
      final seen = <int>{};
      final books = <_BookGroup>[];
      for (final r in results.results) {
        if (seen.add(r.bookId)) {
          books.add(_BookGroup(bookId: r.bookId, bookName: r.bookName, authorName: r.authorName, snippet: r.snippet));
        }
      }
      setState(() {
        _books = books;
        _status = books.isEmpty ? _Status.empty : _Status.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _Status.error);
    }
  }

  static String _stripHtml(String text) => text.replaceAll(RegExp(r'<[^>]*>'), '');

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(widget.topicLabel)),
        body: _buildBody(lang),
      ),
    );
  }

  Widget _buildBody(String lang) {
    switch (_status) {
      case _Status.loading:
        return const Center(child: CircularProgressIndicator());
      case _Status.empty:
        return Center(child: Text(basicText('turath_no_results', lang), style: const TextStyle(color: AppColors.textMuted)));
      case _Status.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(basicText('turath_network_error', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: Text(basicText('retry_action', lang))),
            ],
          ),
        );
      case _Status.success:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _books.length,
          itemBuilder: (context, i) {
            final b = _books[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.auto_stories_outlined, color: AppColors.primary, size: 20)),
                title: Text(b.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w700)),
                subtitle: Text(
                  b.authorName.isNotEmpty ? b.authorName : _stripHtml(b.snippet),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathBookScreen(bookId: b.bookId, bookName: b.bookName))),
              ),
            );
          },
        );
    }
  }
}
