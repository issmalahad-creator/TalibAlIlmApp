import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_reader_screen.dart';

/// "بحث داخل الكتاب" (spec item 9) — the same real debounced search as
/// the main library screen, but scoped to one `book_id` (live-verified
/// 2026-08-28: `search(q, book_id: ...)` really filters server-side, not
/// a client-side post-filter of a wider query).
class TurathBookSearchScreen extends StatefulWidget {
  final int bookId;
  final String bookName;
  const TurathBookSearchScreen({super.key, required this.bookId, required this.bookName});

  @override
  State<TurathBookSearchScreen> createState() => _TurathBookSearchScreenState();
}

enum _Status { idle, loading, success, empty, error }

class _TurathBookSearchScreenState extends State<TurathBookSearchScreen> {
  final _repo = TurathRepository();
  final _controller = TextEditingController();
  Timer? _debounce;
  _Status _status = _Status.idle;
  List<TurathSearchResult> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _status = _Status.idle);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _status = _Status.loading);
    try {
      final results = await _repo.search(query, bookId: widget.bookId);
      if (!mounted) return;
      setState(() {
        _results = results.results;
        _status = _results.isEmpty ? _Status.empty : _Status.success;
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
        appBar: AppBar(title: Text(widget.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 15))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textDirection: TextDirection.rtl,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: basicText('turath_search_in_book_action', lang),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(child: _buildBody(lang)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String lang) {
    switch (_status) {
      case _Status.idle:
        return Center(child: Text(basicText('turath_search_prompt', lang), style: const TextStyle(color: AppColors.textMuted)));
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
              OutlinedButton(onPressed: () => _runSearch(_controller.text.trim()), child: Text(basicText('retry_action', lang))),
            ],
          ),
        );
      case _Status.success:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _results.length,
          itemBuilder: (context, i) {
            final r = _results[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(
                  _stripHtml(r.snippet),
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 13.5, height: 1.7),
                ),
                subtitle: Text('ص ${r.page}', textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: widget.bookId, bookName: widget.bookName, pageNumber: r.page))),
              ),
            );
          },
        );
    }
  }
}
