import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_book_screen.dart';
import 'turath_reader_screen.dart';

/// "مكتبتي" — spec items 10-11 (favorites, last-read position) plus 12
/// (notes), all in one place with three real tabs rather than three
/// separate screens the student has to remember. All local, all real
/// (`TurathRepository`'s `turath_favorites`/`turath_last_read`/
/// `turath_notes` tables) -- an original layout choice, not a copy of
/// Turath's own site (Ismail's explicit instruction).
class TurathMyLibraryScreen extends StatefulWidget {
  const TurathMyLibraryScreen({super.key});

  @override
  State<TurathMyLibraryScreen> createState() => _TurathMyLibraryScreenState();
}

class _TurathMyLibraryScreenState extends State<TurathMyLibraryScreen> {
  final _repo = TurathRepository();
  List<TurathFavorite>? _favorites;
  List<TurathLastRead>? _recent;
  List<TurathNote>? _notes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([_repo.favorites(), _repo.recentlyRead(), _repo.allNotes()]);
    if (!mounted) return;
    setState(() {
      _favorites = results[0] as List<TurathFavorite>;
      _recent = results[1] as List<TurathLastRead>;
      _notes = results[2] as List<TurathNote>;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(basicText('turath_library_title', lang)),
            bottom: TabBar(tabs: [
              Tab(text: basicText('turath_favorites_title', lang)),
              Tab(text: basicText('turath_recently_read_title', lang)),
              Tab(text: basicText('turath_notes_title', lang)),
            ]),
          ),
          body: _favorites == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(children: [_buildFavorites(lang), _buildRecent(lang), _buildNotes(lang)]),
        ),
      ),
    );
  }

  Widget _buildFavorites(String lang) {
    if (_favorites!.isEmpty) {
      return Center(child: Text(basicText('turath_no_favorites_empty', lang), style: const TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites!.length,
      itemBuilder: (context, i) {
        final f = _favorites![i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(f.isBook ? Icons.auto_stories_outlined : Icons.bookmark_outline, color: AppColors.primary),
            title: Text(f.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w700)),
            subtitle: f.isBook ? null : Text('ص ${f.pageNumber}', textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onTap: () => f.isBook
                ? Navigator.push(context, MaterialPageRoute(builder: (_) => TurathBookScreen(bookId: f.bookId, bookName: f.bookName)))
                : Navigator.push(context, MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: f.bookId, bookName: f.bookName, pageNumber: f.pageNumber!))),
          ),
        );
      },
    );
  }

  Widget _buildRecent(String lang) {
    if (_recent!.isEmpty) {
      return Center(child: Text(basicText('turath_no_recent_empty', lang), style: const TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recent!.length,
      itemBuilder: (context, i) {
        final r = _recent![i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.history_rounded, color: AppColors.primary),
            title: Text(r.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w700)),
            subtitle: Text('${basicText('turath_last_read_label', lang)} ${r.pageNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: r.bookId, bookName: r.bookName, pageNumber: r.pageNumber))),
          ),
        );
      },
    );
  }

  Widget _buildNotes(String lang) {
    if (_notes!.isEmpty) {
      return Center(child: Text(basicText('turath_no_notes_empty', lang), style: const TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes!.length,
      itemBuilder: (context, i) {
        final n = _notes![i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(n.note, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (n.selectedText != null && n.selectedText!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('"${n.selectedText}"', textDirection: TextDirection.rtl, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11.5)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${n.bookName} — ص ${n.pageNumber}', textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                ),
              ],
            ),
            isThreeLine: n.selectedText != null && n.selectedText!.trim().isNotEmpty,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
              onPressed: () async {
                await _repo.deleteNote(n.id);
                _load();
              },
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: n.bookId, bookName: n.bookName, pageNumber: n.pageNumber))),
          ),
        );
      },
    );
  }
}
