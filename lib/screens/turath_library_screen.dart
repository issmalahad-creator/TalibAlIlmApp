import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_reader_screen.dart';

/// "📚 المكتبة التراثية" — Phase 79.7's search entry point (chosen as the
/// *first* screen rather than a categories browser: turath.io's real API
/// has no "list all categories" endpoint in either reference SDK, verified
/// live 2026-08-27 — TODO.md 79.3 tracks adding category browsing once
/// that's real, not guessed). Search itself is fully live-verified.
class TurathLibraryScreen extends StatefulWidget {
  const TurathLibraryScreen({super.key});

  @override
  State<TurathLibraryScreen> createState() => _TurathLibraryScreenState();
}

enum _SearchStatus { idle, loading, success, empty, error }

class _TurathLibraryScreenState extends State<TurathLibraryScreen> {
  final _repo = TurathRepository();
  final _controller = TextEditingController();
  Timer? _debounce;
  _SearchStatus _status = _SearchStatus.idle;
  TurathSearchResults? _results;

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
      setState(() => _status = _SearchStatus.idle);
      return;
    }
    // Real debounce (Ismail's spec item 14) -- never one request per
    // keystroke.
    _debounce = Timer(const Duration(milliseconds: 500), () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _status = _SearchStatus.loading);
    try {
      final results = await _repo.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _status = results.results.isEmpty ? _SearchStatus.empty : _SearchStatus.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _SearchStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('turath_library_title', lang))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: basicText('turath_search_hint', lang),
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
      case _SearchStatus.idle:
        return Center(child: Text(basicText('turath_search_prompt', lang), style: const TextStyle(color: AppColors.textMuted)));
      case _SearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case _SearchStatus.empty:
        return Center(child: Text(basicText('turath_no_results', lang), style: const TextStyle(color: AppColors.textMuted)));
      case _SearchStatus.error:
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
      case _SearchStatus.success:
        final results = _results!.results;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          itemBuilder: (context, i) => _ResultCard(result: results[i]),
        );
    }
  }
}

class _ResultCard extends StatelessWidget {
  final TurathSearchResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(result.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.authorName.isNotEmpty)
              Text(result.authorName, textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _stripHtml(result.snippet),
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, height: 1.6),
            ),
            const SizedBox(height: 4),
            Text('ص ${result.page}', textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: result.bookId, bookName: result.bookName, pageNumber: result.page)),
        ),
      ),
    );
  }

  // The API's snippet field embeds real HTML tags (e.g. `<em>`/`<span>`
  // for highlighting) -- strip them for the plain-text list preview
  // rather than rendering raw markup.
  static String _stripHtml(String text) => text.replaceAll(RegExp(r'<[^>]*>'), '');
}
