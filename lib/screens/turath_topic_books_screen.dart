import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_book_screen.dart';
import 'turath_reader_screen.dart';

/// "تصفح القسم" — a category's real book list, plus search *inside* that
/// category, both anchored to the local canonical catalog (Phase 79
/// `79-membership-index` / category-browsing).
///
/// - **Browse** (empty search box): `booksInCategory(catId, limit, offset)` —
///   deterministic DB pagination through `turath_catalog_category_books`, no
///   full-text search. The header count is `categoryBookCount` (808 for
///   العقيدة) and never moves, whatever you scroll or filter.
/// - **Search in category** (non-empty box): `searchInCategory` — the API's
///   `cat_id` filter narrows server-side, then results are intersected with
///   this category's membership so a book from another section can never
///   appear. Global search (whole library) lives on `TurathLibraryScreen`
///   and is intentionally separate.
/// - **PDF only**: a browse-mode filter over `has_pdf`; shows "N / total".
class TurathTopicBooksScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  const TurathTopicBooksScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  State<TurathTopicBooksScreen> createState() => _TurathTopicBooksScreenState();
}

enum _Mode { loading, notReady, browse, browseEmpty, searchLoading, searchSuccess, searchEmpty, searchError }

class _TurathTopicBooksScreenState extends State<TurathTopicBooksScreen> {
  static const _pageSize = 30;

  final _repo = TurathRepository();
  final _searchController = TextEditingController();
  Timer? _debounce;

  _Mode _mode = _Mode.loading;

  // Browse state
  final List<TurathCatalogBook> _books = [];
  int _totalBooks = 0;
  int _pdfCount = 0;
  bool _pdfOnly = false;
  bool _loadingMore = false;
  bool get _hasMore {
    final ceiling = _pdfOnly ? _pdfCount : _totalBooks;
    return _books.length < ceiling;
  }

  // Search state
  String _query = '';
  List<TurathSearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _mode = _Mode.loading);
    if (!await _repo.hasCatalog()) {
      if (!mounted) return;
      setState(() => _mode = _Mode.notReady);
      return;
    }
    final count = await _repo.categoryBookCount(widget.categoryId);
    final pdfCount = await _repo.categoryPdfBookCount(widget.categoryId);
    if (!mounted) return;
    _totalBooks = count;
    _pdfCount = pdfCount;
    await _reloadBrowse();
  }

  Future<void> _reloadBrowse() async {
    final first = await _repo.booksInCategory(widget.categoryId, limit: _pageSize, offset: 0, pdfOnly: _pdfOnly);
    if (!mounted) return;
    setState(() {
      _books
        ..clear()
        ..addAll(first);
      _mode = first.isEmpty ? _Mode.browseEmpty : _Mode.browse;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = await _repo.booksInCategory(widget.categoryId, limit: _pageSize, offset: _books.length, pdfOnly: _pdfOnly);
    if (!mounted) return;
    setState(() {
      _books.addAll(next);
      _loadingMore = false;
    });
  }

  void _onQueryChanged(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results = [];
        _mode = _books.isEmpty ? _Mode.browseEmpty : _Mode.browse;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _query = q;
      _mode = _Mode.searchLoading;
    });
    try {
      final results = await _repo.searchInCategory(q, widget.categoryId);
      if (!mounted || _query != q) return;
      setState(() {
        _results = results;
        _mode = results.isEmpty ? _Mode.searchEmpty : _Mode.searchSuccess;
      });
    } catch (_) {
      if (!mounted || _query != q) return;
      setState(() => _mode = _Mode.searchError);
    }
  }

  void _togglePdfOnly() {
    setState(() => _pdfOnly = !_pdfOnly);
    _reloadBrowse();
  }

  static String _stripHtml(String text) => text.replaceAll(RegExp(r'<[^>]*>'), '');

  bool get _searching => _query.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(widget.categoryName)),
        body: Column(
          children: [
            if (_mode != _Mode.loading && _mode != _Mode.notReady) _searchAndFilter(lang),
            Expanded(child: _buildBody(lang)),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilter(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: basicText('turath_search_in_category_hint', lang),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onQueryChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!_searching)
                FilterChip(
                  label: Text(basicText('turath_pdf_only_filter', lang)),
                  avatar: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  selected: _pdfOnly,
                  onSelected: (_) => _togglePdfOnly(),
                ),
              const Spacer(),
              Text(_countLabel(lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  String _countLabel(String lang) {
    if (_searching) {
      return '${basicText('turath_category_search_results', lang)} — ${widget.categoryName}';
    }
    if (_pdfOnly) {
      return '${basicText('turath_pdf_count_label', lang)} $_pdfCount / $_totalBooks';
    }
    return '${basicText('turath_category_book_count', lang)} $_totalBooks';
  }

  Widget _buildBody(String lang) {
    switch (_mode) {
      case _Mode.loading:
        return const Center(child: CircularProgressIndicator());
      case _Mode.notReady:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(basicText('turath_catalog_preparing', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _init, child: Text(basicText('retry_action', lang))),
            ],
          ),
        );
      case _Mode.browseEmpty:
        return Center(child: Text(basicText('turath_no_results', lang), style: const TextStyle(color: AppColors.textMuted)));
      case _Mode.searchEmpty:
        return Center(child: Text(basicText('turath_no_results', lang), style: const TextStyle(color: AppColors.textMuted)));
      case _Mode.searchLoading:
        return const Center(child: CircularProgressIndicator());
      case _Mode.searchError:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(basicText('turath_network_error', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => _runSearch(_query), child: Text(basicText('retry_action', lang))),
            ],
          ),
        );
      case _Mode.searchSuccess:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _results.length,
          itemBuilder: (context, i) {
            final r = _results[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(r.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w700)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.authorName.isNotEmpty)
                      Text(r.authorName, textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_stripHtml(r.snippet), textDirection: TextDirection.rtl, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.6)),
                    const SizedBox(height: 4),
                    Text('ص ${r.page}', textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: r.bookId, bookName: r.bookName, pageNumber: r.page)),
                ),
              ),
            );
          },
        );
      case _Mode.browse:
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _books.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _books.length) {
              if (!_loadingMore) WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
              return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
            }
            final b = _books[i];
            final subtitle = [
              if (b.authorName.isNotEmpty) b.authorName,
              if (b.pageCount != null) '${b.pageCount} ${basicText('turath_pages_unit', lang)}',
            ].join(' · ');
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.auto_stories_outlined, color: AppColors.primary, size: 20)),
                title: Text(b.name, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w700)),
                subtitle: subtitle.isEmpty
                    ? null
                    : Text(subtitle, textDirection: TextDirection.rtl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                trailing: b.hasPdf ? const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.textMuted) : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathBookScreen(bookId: b.bookId, bookName: b.name))),
              ),
            );
          },
        );
    }
  }
}
