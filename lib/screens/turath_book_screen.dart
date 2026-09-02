import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_book_search_screen.dart';
import 'turath_index_screen.dart';
import 'turath_reader_screen.dart';
import 'turath_study_notebook_screen.dart';

/// "فتح الكتاب" (spec item 4/10) — real book detail screen: title, real
/// info text and volume count from `getBookInfo` (never fabricated),
/// "بدء القراءة" (resumes the real saved last-read page when one exists,
/// spec item 11), "الفهرس" (real table of contents, item 5/6), "بحث داخل
/// الكتاب" (item 9), and a favorite toggle (item 10). Deliberately its own
/// screen distinct from a search-result tap (which still jumps straight to
/// a page, per the spec's own two documented flows) -- reached from
/// [TurathTopicBooksScreen] or from "قرأت مؤخرًا"/"المفضلة".
class TurathBookScreen extends StatefulWidget {
  final int bookId;
  final String bookName;
  const TurathBookScreen({super.key, required this.bookId, required this.bookName});

  @override
  State<TurathBookScreen> createState() => _TurathBookScreenState();
}

enum _Status { loading, success, error }

class _TurathBookScreenState extends State<TurathBookScreen> {
  final _repo = TurathRepository();
  _Status _status = _Status.loading;
  TurathBook? _book;
  TurathLastRead? _lastRead;
  bool _isFavorite = false;
  int _noteCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    try {
      final results = await Future.wait([
        _repo.getBookInfo(widget.bookId),
        _repo.lastRead(widget.bookId),
        _repo.isFavoriteBook(widget.bookId),
        _repo.annotationCountForBook(widget.bookId),
      ]);
      if (!mounted) return;
      setState(() {
        _book = results[0] as TurathBook;
        _lastRead = results[1] as TurathLastRead?;
        _isFavorite = results[2] as bool;
        _noteCount = results[3] as int;
        _status = _Status.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _Status.error);
    }
  }

  Future<void> _toggleFavorite() async {
    await _repo.toggleFavoriteBook(widget.bookId, widget.bookName);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  void _startReading() {
    final startPage = _lastRead?.pageNumber ?? _book?.indexes.firstOrNull?.page ?? 1;
    Navigator.push(context, MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: widget.bookId, bookName: widget.bookName, pageNumber: startPage)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 16)),
          actions: [
            IconButton(icon: Icon(_isFavorite ? Icons.bookmark : Icons.bookmark_outline), onPressed: _toggleFavorite),
          ],
        ),
        body: _buildBody(lang),
      ),
    );
  }

  Widget _buildBody(String lang) {
    switch (_status) {
      case _Status.loading:
        return const Center(child: CircularProgressIndicator());
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
        final book = _book!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.auto_stories_outlined, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(book.name, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Amiri', fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startReading,
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(basicText('turath_start_reading_action', lang)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            if (_lastRead != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${basicText('turath_last_read_label', lang)} ${_lastRead!.pageNumber}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ),
            const SizedBox(height: 10),
            if (book.indexes.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: Text(basicText('turath_index_action', lang)),
                trailing: const Icon(Icons.chevron_left_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
                tileColor: AppColors.surface,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathIndexScreen(bookId: widget.bookId, bookName: widget.bookName, book: book))),
              ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: Text(basicText('turath_search_in_book_action', lang)),
              trailing: const Icon(Icons.chevron_left_rounded),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
              tileColor: AppColors.surface,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathBookSearchScreen(bookId: widget.bookId, bookName: widget.bookName))),
            ),
            if (_noteCount > 0) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.auto_stories_outlined),
                title: Text('${basicText('turath_my_notes_in_book', lang)} ($_noteCount)'),
                trailing: const Icon(Icons.chevron_left_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
                tileColor: AppColors.surface,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TurathStudyNotebookScreen(bookId: widget.bookId, bookTitle: widget.bookName),
                    ),
                  );
                  _load();
                },
              ),
            ],
            if (book.info != null && book.info!.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(basicText('turath_about_book_label', lang), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(book.info!, textDirection: TextDirection.rtl, style: const TextStyle(height: 1.7, color: AppColors.textDark)),
            ],
            const SizedBox(height: 20),
            Text(basicText('turath_source_attribution', lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        );
    }
  }
}
