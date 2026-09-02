import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_reader_screen.dart';

/// "الفهرس" (spec item 5/6) — the book's real table of contents, from
/// `TurathBook.indexes` (real `getBookInfo(..., include: indexes)` data,
/// never invented). Each entry's `level` indents it, matching how the
/// real API structures nested headings (e.g. "كتاب" then "باب" under it).
/// Tapping any entry jumps straight to its real page. A small coloured dot
/// marks entries whose page already carries a highlight or a page note.
class TurathIndexScreen extends StatefulWidget {
  final int bookId;
  final String bookName;
  final TurathBook book;
  const TurathIndexScreen(
      {super.key,
      required this.bookId,
      required this.bookName,
      required this.book});

  @override
  State<TurathIndexScreen> createState() => _TurathIndexScreenState();
}

class _TurathIndexScreenState extends State<TurathIndexScreen> {
  Map<int, String> _annotated = const {};

  @override
  void initState() {
    super.initState();
    TurathRepository().annotatedPagesForBook(widget.bookId).then((m) {
      if (mounted) setState(() => _annotated = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('turath_index_action', lang))),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: book.indexes.length,
          itemBuilder: (context, i) {
            final entry = book.indexes[i];
            final colorKey = _annotated[entry.page];
            return ListTile(
              contentPadding: EdgeInsets.only(
                  right: 16.0 + (entry.level - 1).clamp(0, 4) * 16, left: 16),
              title: Text(
                entry.title,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: entry.level <= 1 ? 16 : 14,
                    fontWeight:
                        entry.level <= 1 ? FontWeight.w700 : FontWeight.w400),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (colorKey != null)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: AppColors.studyAnnotation(colorKey).$3,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text('${entry.page}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TurathReaderScreen(
                          bookId: widget.bookId,
                          bookName: widget.bookName,
                          pageNumber: entry.page))),
            );
          },
        ),
      ),
    );
  }
}
