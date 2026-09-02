import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_reader_screen.dart';

/// "اقتباساتي" (spec item 10/13) — every saved quote, each carrying its
/// real citation (book/author/volume/page), not just the text.
class TurathQuotesScreen extends StatefulWidget {
  const TurathQuotesScreen({super.key});

  @override
  State<TurathQuotesScreen> createState() => _TurathQuotesScreenState();
}

class _TurathQuotesScreenState extends State<TurathQuotesScreen> {
  final _repo = TurathRepository();
  List<TurathQuote>? _quotes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quotes = await _repo.allQuotes();
    if (!mounted) return;
    setState(() => _quotes = quotes);
  }

  String _citation(TurathQuote q) {
    final parts = <String>[q.bookName];
    if (q.authorName != null && q.authorName!.isNotEmpty) parts.add(q.authorName!);
    if (q.volume != null && q.volume!.isNotEmpty) parts.add('ج${q.volume}');
    parts.add('ص${q.pageNumber}');
    return parts.join(' — ');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('turath_quotes_title', lang))),
        body: _quotes == null
            ? const Center(child: CircularProgressIndicator())
            : _quotes!.isEmpty
                ? Center(child: Text(basicText('turath_no_quotes_empty', lang), style: const TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _quotes!.length,
                    itemBuilder: (context, i) {
                      final q = _quotes![i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: q.bookId, bookName: q.bookName, pageNumber: q.pageNumber)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  '"${q.quotedText}"',
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 15, height: 1.7, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(_citation(q), textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                if (q.note != null && q.note!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(q.note!, textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.share_outlined, size: 20),
                                      onPressed: () => Share.share('"${q.quotedText}"\n\n${_citation(q)}'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                                      onPressed: () async {
                                        await _repo.deleteQuote(q.id);
                                        _load();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
