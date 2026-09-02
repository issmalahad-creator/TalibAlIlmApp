import 'package:flutter/material.dart';

import '../data/turath_categories.dart';
import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_topic_books_screen.dart';

/// "أقسام" — the real 40 subject categories, each with its exact book count
/// (Phase 79 `79-membership-index`). The count comes from the local
/// canonical catalog (`TurathRepository.categories()` → `total_books`),
/// which is seeded from turath.io's own `data-v3.json` manifest — never
/// counted from search results, so العقيدة reads 808 and stays 808.
///
/// A vertical, searchable, fully scrollable list; tapping a category opens
/// [TurathTopicBooksScreen], which pages that category's books straight
/// from the same catalog tables.
class TurathCategoriesScreen extends StatefulWidget {
  const TurathCategoriesScreen({super.key});

  @override
  State<TurathCategoriesScreen> createState() => _TurathCategoriesScreenState();
}

class _TurathCategoriesScreenState extends State<TurathCategoriesScreen> {
  final _repo = TurathRepository();
  final _controller = TextEditingController();
  String _filter = '';
  late Future<List<TurathCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.categories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('turath_categories_title', lang))),
        body: FutureBuilder<List<TurathCategory>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final all = snap.data!;
            final visible = _filter.isEmpty ? all : all.where((c) => c.name.contains(_filter)).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    textDirection: TextDirection.rtl,
                    onChanged: (v) => setState(() => _filter = v.trim()),
                    decoration: InputDecoration(
                      hintText: basicText('turath_categories_search_hint', lang),
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${basicText('turath_categories_snapshot_label', lang)} $turathCategorySnapshotDate',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = visible[i];
                      return ListTile(
                        title: Text(c.name, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text('${c.totalBooks}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TurathTopicBooksScreen(categoryId: c.catId, categoryName: c.name)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
