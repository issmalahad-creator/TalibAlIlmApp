import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/basic_translations.dart';
import '../models/book_content.dart';
import '../models/book_of_month.dart';
import '../models/personal_book.dart';
import '../repositories/book_repository.dart';
import '../services/book_content_service.dart';
import '../services/content_badge_service.dart';
import '../services/downloaded_file_service.dart';
import '../services/hidden_books_service.dart';
import '../services/language_preference_service.dart';
import '../services/personal_library_service.dart';
import '../theme/app_theme.dart';
import 'book_viewer_screen.dart';
import 'content_history_screen.dart';
import 'personal_library_screen.dart';
import 'quiz_screen.dart';
import 'reading_stats_screen.dart';
import '../widgets/loading_view.dart';

/// Books, their quizzes, and any extra materials — all fetched live from
/// the Telegram-controlled content feed. Books accumulate (each `كتاب:`
/// message adds one, none are overwritten) — shown as a collapsible list so
/// the screen stays usable as the list grows; tapping a book selects it,
/// and every action below (open PDF, reading %, quiz) applies to whichever
/// book is currently selected, not just the newest one.
/// See CLAUDE.md "Book content feed (Telegram-controlled)".
class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _bookRepo = BookRepository();
  final _contentService = BookContentService();
  final _hiddenBooksService = HiddenBooksService();
  final _downloadService = DownloadedFileService();
  final _libraryService = PersonalLibraryService();
  final _lang = LanguagePreferenceService.currentLanguage;

  BookContentFeed _feed = BookContentFeed.empty;
  Set<String> _hiddenIds = {};
  bool _showHidden = false;
  bool _loading = true;
  bool _listExpanded = true;
  String? _selectedBookId;
  String? _downloadingUrl;
  List<PersonalBook> _personalBooks = [];
  final _bookSearchController = TextEditingController();
  String _bookSearchQuery = '';

  int _progress = 0;
  int? _quizScore;

  List<BookEntry> get _visibleBooks {
    final base = _feed.books.where((b) => !_hiddenIds.contains(b.id));
    final q = _bookSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return base.toList();
    return base.where((b) => b.title.toLowerCase().contains(q)).toList();
  }
  List<BookEntry> get _hiddenBooks => _feed.books.where((b) => _hiddenIds.contains(b.id)).toList();

  BookEntry? get _selectedBook {
    final visible = _visibleBooks;
    if (visible.isEmpty) return null;
    return visible.firstWhere((b) => b.id == _selectedBookId, orElse: () => visible.first);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bookSearchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final feed = await _contentService.fetch();
    final hiddenIds = await _hiddenBooksService.getHiddenIds();
    final personalBooks = await _libraryService.all();
    if (!mounted) return;
    final visible = feed.books.where((b) => !hiddenIds.contains(b.id)).toList();
    // Default selection: newest *visible* book, unless the previously-
    // selected one still exists (keep the user's choice on pull-to-refresh
    // instead of silently jumping back to the newest).
    final stillExists = visible.any((b) => b.id == _selectedBookId);
    final selectedId = stillExists ? _selectedBookId : (visible.isNotEmpty ? visible.first.id : null);
    setState(() {
      _feed = feed;
      _hiddenIds = hiddenIds;
      _selectedBookId = selectedId;
      _personalBooks = personalBooks;
      _loading = false;
    });
    await _loadProgressFor(selectedId);
    await ContentBadgeService.instance.markSeen(feed);
    // Best-effort background prefetch so the selected book is already on the
    // device (fully readable offline) without the student having to tap
    // "open" first — never blocks the UI, and a failure here is silent since
    // the on-demand download in _downloadAndOpenPdf still works as a fallback.
    final selected = _selectedBook;
    if (selected != null) {
      () async {
        try {
          await _downloadService.ensureDownloaded(key: selected.id, url: selected.url);
        } catch (_) {}
      }();
    }
  }

  Future<void> _hideBook(BookEntry book) async {
    await _hiddenBooksService.hide(book.id);
    setState(() => _hiddenIds = {..._hiddenIds, book.id});
    if (_selectedBookId == book.id) {
      final visible = _visibleBooks;
      final newSelection = visible.isNotEmpty ? visible.first.id : null;
      setState(() => _selectedBookId = newSelection);
      await _loadProgressFor(newSelection);
    }
  }

  Future<void> _unhideBook(BookEntry book) async {
    await _hiddenBooksService.unhide(book.id);
    setState(() => _hiddenIds = {..._hiddenIds}..remove(book.id));
  }

  Future<void> _loadProgressFor(String? bookId) async {
    if (bookId == null) {
      setState(() {
        _progress = 0;
        _quizScore = null;
      });
      return;
    }
    final progress = await _bookRepo.getProgress(bookId);
    final quizResult = await _bookRepo.getQuizResult(bookId);
    if (!mounted) return;
    setState(() {
      _progress = progress.percent;
      _quizScore = quizResult?.scorePercent;
    });
  }

  Future<void> _selectBook(BookEntry book) async {
    setState(() => _selectedBookId = book.id);
    await _loadProgressFor(book.id);
  }

  Future<void> _setProgress(int value) async {
    final book = _selectedBook;
    if (book == null) return;
    setState(() => _progress = value);
    await _bookRepo.setProgress(book.id, value);
  }

  /// Downloads (or reuses an already-cached copy of) the PDF and opens it.
  /// [cacheKey] is a stable identifier for local storage — a book's id, or a
  /// generic content item's URL — distinct from [url] so re-opening the same
  /// book never re-downloads it, matching the app's offline-first design.
  Future<void> _downloadAndOpenPdf({required String url, required String title, required String cacheKey}) async {
    setState(() => _downloadingUrl = url);
    try {
      final file = await _downloadService.ensureDownloaded(key: cacheKey, url: url);
      if (!mounted) return;
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => BookViewerScreen(filePath: file.path, title: title, bookKey: url)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${basicText('cannot_download_file', _lang)}: $e')));
    } finally {
      if (mounted) setState(() => _downloadingUrl = null);
    }
  }

  Future<void> _openMyLibrary() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalLibraryScreen()));
    // The library screen manages its own data; just refresh our summary count.
    final personalBooks = await _libraryService.all();
    if (mounted) setState(() => _personalBooks = personalBooks);
  }

  Widget _myLibrarySection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.collections_bookmark_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${basicText('my_library', _lang)} (${_personalBooks.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(basicText('my_library_desc', _lang),
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMyLibrary,
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: Text(basicText('open_my_library', _lang)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openContentItem(ContentItem item) async {
    if (!item.isPdf) {
      final uri = Uri.parse(item.url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(basicText('cannot_open_file', _lang))));
      }
      return;
    }
    await _downloadAndOpenPdf(url: item.url, title: item.title, cacheKey: item.url);
  }

  Widget _announcementBanner() {
    if (_feed.announcement.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3D583)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_rounded, color: Color(0xFFB5851D)),
          const SizedBox(width: 10),
          Expanded(child: Text(_feed.announcement, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _bookListSection() {
    final visible = _visibleBooks;
    final hidden = _hiddenBooks;
    if (visible.isEmpty && hidden.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(basicText('no_books_yet', _lang),
            textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _listExpanded = !_listExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${basicText('books_label', _lang)} (${visible.length})',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ),
                  Icon(_listExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (_listExpanded) ...[
            if (_feed.books.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: TextField(
                  controller: _bookSearchController,
                  onChanged: (v) => setState(() => _bookSearchQuery = v),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: basicText('search_book_hint', _lang),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _bookSearchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _bookSearchController.clear();
                              setState(() => _bookSearchQuery = '');
                            },
                          ),
                  ),
                ),
              ),
            if (visible.isEmpty && _bookSearchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(basicText('no_results', _lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              ),
            ...visible.map((book) => _bookRow(book, hidden: false)),
            if (hidden.isNotEmpty)
              InkWell(
                onTap: () => setState(() => _showHidden = !_showHidden),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
                  child: Row(
                    children: [
                      Icon(_showHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('${hidden.length} ${basicText('hidden_books_count', _lang)} — ${_showHidden ? basicText('hide_action', _lang) : basicText('show_action', _lang)}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            if (_showHidden) ...hidden.map((book) => _bookRow(book, hidden: true)),
          ],
        ],
      ),
    );
  }

  Widget _bookRow(BookEntry book, {required bool hidden}) {
    final selected = !hidden && book.id == _selectedBookId;
    return InkWell(
      onTap: hidden ? null : () => _selectBook(book),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : null,
          border: const Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(
              hidden
                  ? Icons.visibility_off_outlined
                  : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: hidden ? AppColors.textMuted : AppColors.textDark)),
            ),
            if (book.quiz.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.quiz_outlined, size: 16, color: AppColors.textMuted),
              ),
            IconButton(
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: Icon(hidden ? Icons.replay_rounded : Icons.close_rounded, color: AppColors.textMuted),
              tooltip: hidden ? basicText('show_action', _lang) : basicText('hide_from_my_list', _lang),
              onPressed: () => hidden ? _unhideBook(book) : _hideBook(book),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentList() {
    if (_feed.items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(basicText('more_content_from_admin', _lang), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._feed.items.map((item) {
            if (item.type == 'voice') {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.mic_rounded, color: AppColors.primary),
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.date, style: const TextStyle(fontSize: 11)),
                  trailing: _VoicePlayButton(url: item.url),
                ),
              );
            }
            final downloading = _downloadingUrl == item.url;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(item.type == 'photo' ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                    color: AppColors.primary),
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.date, style: const TextStyle(fontSize: 11)),
                trailing: downloading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded),
                onTap: downloading ? null : () => _openContentItem(item),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _selectedBookDetail(BookEntry book) {
    final downloadingBook = _downloadingUrl == book.url;
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(basicText('selected_book_label', _lang),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(book.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: downloadingBook
                      ? null
                      : () => _downloadAndOpenPdf(url: book.url, title: book.title, cacheKey: book.id),
                  icon: downloadingBook
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.menu_book),
                  label: Text(downloadingBook ? basicText('downloading_ellipsis', _lang) : basicText('open_this_book', _lang)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${basicText('reading_percent_label', _lang)}: $_progress%', style: Theme.of(context).textTheme.titleMedium),
                Text(basicText('reading_percent_desc', _lang),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                Slider(
                  value: _progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_progress%',
                  onChanged: (v) => _setProgress(v.round()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(basicText('book_quiz_label', _lang), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_quizScore != null ? '${basicText('your_score_label', _lang)}: $_quizScore%' : basicText('quiz_not_taken_yet', _lang)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: book.quiz.isEmpty
                      ? null
                      : () async {
                          final result = await Navigator.push<bool>(
                              context, MaterialPageRoute(builder: (_) => QuizScreen(book: _asBookOfMonth(book))));
                          if (result == true) _loadProgressFor(book.id);
                        },
                  icon: const Icon(Icons.quiz),
                  label: Text(book.quiz.isEmpty ? basicText('no_quiz_yet', _lang) : basicText('start_quiz', _lang)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BookOfMonth _asBookOfMonth(BookEntry book) =>
      BookOfMonth(month: book.id, title: book.title, author: '', file: book.url, quiz: book.quiz);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: Text(basicText('nav_book', _lang))),
          body: AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_book', _lang)));
    }
    final book = _selectedBook;

    return Scaffold(
      appBar: AppBar(
        title: Text(basicText('nav_book', _lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: basicText('announcements_history', _lang),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => ContentHistoryScreen(history: _feed.history))),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: basicText('my_stats', _lang),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReadingStatsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _announcementBanner(),
            _bookListSection(),
            if (book != null) _selectedBookDetail(book),
            const SizedBox(height: 16),
            _contentList(),
            _myLibrarySection(),
          ],
        ),
      ),
    );
  }
}

/// Inline play/pause for a voice-note content item — streams directly from
/// the Telegram file URL via `audioplayers`, no local caching (voice notes
/// are short; unlike PDFs there's no offline-reading need to justify it).
class _VoicePlayButton extends StatefulWidget {
  final String url;
  const _VoicePlayButton({required this.url});

  @override
  State<_VoicePlayButton> createState() => _VoicePlayButtonState();
}

class _VoicePlayButtonState extends State<_VoicePlayButton> {
  final _player = AudioPlayer();
  bool _playing = false;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(UrlSource(widget.url));
      setState(() => _playing = true);
    }
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
          color: AppColors.primary, size: 32),
      onPressed: _toggle,
    );
  }
}
