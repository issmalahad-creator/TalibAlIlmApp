import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/adhkar_repository.dart';
import '../repositories/hadith_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../repositories/memorization_repository.dart';
import '../repositories/wasitiyyah_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';
import 'adhkar_quiz_screen.dart';
import 'hadith_quiz_screen.dart';
import 'review_screen.dart';
import 'wasitiyyah_quiz_screen.dart';
import '../repositories/usul_tree_repository.dart';
import '../services/usul/usul_rebuild.dart';
import 'usul/usul_rebuild_screen.dart';

/// "مراجعتك اليوم" — Ismail's 2026-08-16 "الدماغ الذي يربط" request, Batch 1
/// item 17 ("نظام المراجعة الشاملة"). A single cross-pillar due-list, not a
/// new review engine of its own: Quran's count comes straight from the
/// existing, untouched `MemorizationRepository.dueToday()`; hadith/Wasitiyyah/
/// adhkar counts come from the new `KnowledgeReviewRepository` (Batch 1's
/// generalized station engine, extended to adhkar the same day). Tapping a
/// section opens that pillar's existing review/quiz screen
/// (`ReviewScreen`/`HadithQuizScreen`/`WasitiyyahQuizScreen`/
/// `AdhkarQuizScreen`) — no new per-item review UI, matching the plan's
/// "reuse, don't rebuild" scope.
class KnowledgeReviewScreen extends StatefulWidget {
  const KnowledgeReviewScreen({super.key});

  @override
  State<KnowledgeReviewScreen> createState() => _KnowledgeReviewScreenState();
}

class _KnowledgeReviewScreenState extends State<KnowledgeReviewScreen> {
  bool _loading = true;
  int _quranDue = 0;
  List<String> _hadithDueTexts = [];
  List<String> _wasitiyyahDueTexts = [];
  List<String> _adhkarDueTexts = [];
  List<UsulRebuildGroup> _usulDue = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final quranDue = await MemorizationRepository().dueToday();
    final reviewDue = await KnowledgeReviewRepository().dueTodayAll();

    final hadithIds = (reviewDue['hadith'] ?? []).map((d) => d.itemId).toSet();
    final wasitiyyahIds = (reviewDue['wasitiyyah'] ?? []).map((d) => d.itemId).toSet();
    final adhkarIds = (reviewDue['adhkar'] ?? []).map((d) => d.itemId).toList();
    final allHadiths = hadithIds.isEmpty ? <NawawiHadith>[] : await HadithRepository().all();
    final allSections = wasitiyyahIds.isEmpty ? <WasitiyyahSection> [] : await WasitiyyahRepository().all();
    final adhkarItems = adhkarIds.isEmpty ? <AdhkarItem>[] : await AdhkarRepository().itemsByIds(adhkarIds);
    final usulIds = (reviewDue['usul_tree'] ?? []).map((d) => d.itemId).toSet();
    final usulRoot = usulIds.isEmpty ? null : await UsulTreeRepository().tree();
    final usulDue = usulRoot == null
        ? <UsulRebuildGroup>[]
        : usulRebuildGroups(usulRoot).where((g) => usulIds.contains(g.itemId)).toList();

    if (!mounted) return;
    setState(() {
      _quranDue = quranDue.length;
      _hadithDueTexts = allHadiths.where((h) => hadithIds.contains(h.id)).map((h) => h.text).toList();
      _wasitiyyahDueTexts = allSections.where((s) => wasitiyyahIds.contains(s.id)).map((s) => s.text).toList();
      _adhkarDueTexts = adhkarItems.map((i) => i.text).toList();
      _usulDue = usulDue;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('knowledge_review_title', lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.fact_check_outlined, message: basicText('assembling_review_message', lang))
          : (_quranDue == 0 && _hadithDueTexts.isEmpty && _wasitiyyahDueTexts.isEmpty && _adhkarDueTexts.isEmpty && _usulDue.isEmpty)
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_quranDue > 0)
                        _PillarSection(
                          icon: Icons.menu_book_outlined,
                          title: basicText('consistency_quran_label', lang),
                          count: _quranDue,
                          previewLines: const [],
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
                            _load();
                          },
                        ),
                      if (_hadithDueTexts.isNotEmpty)
                        _PillarSection(
                          icon: Icons.menu_book_rounded,
                          title: basicText('hadith_section_title', lang),
                          count: _hadithDueTexts.length,
                          previewLines: _hadithDueTexts,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithQuizScreen()));
                            _load();
                          },
                        ),
                      if (_wasitiyyahDueTexts.isNotEmpty)
                        _PillarSection(
                          icon: Icons.shield_outlined,
                          title: basicText('aqeedah_section_title', lang),
                          count: _wasitiyyahDueTexts.length,
                          previewLines: _wasitiyyahDueTexts,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const WasitiyyahQuizScreen()));
                            _load();
                          },
                        ),
                      if (_adhkarDueTexts.isNotEmpty)
                        _PillarSection(
                          icon: Icons.spa_outlined,
                          title: basicText('adhkar_section_title', lang),
                          count: _adhkarDueTexts.length,
                          previewLines: _adhkarDueTexts,
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhkarQuizScreen()));
                            _load();
                          },
                        ),
                      if (_usulDue.isNotEmpty)
                        _PillarSection(
                          icon: Icons.account_tree_outlined,
                          title: basicText('usul_tree_title', lang),
                          count: _usulDue.length,
                          previewLines: _usulDue.map((g) => g.prompt).toList(),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UsulRebuildScreen(onlyItemIds: {for (final g in _usulDue) g.itemId}),
                              ),
                            );
                            _load();
                          },
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.self_improvement, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(basicText('nothing_to_review_message', LanguagePreferenceService.currentLanguage), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _PillarSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final List<String> previewLines;
  final VoidCallback onTap;
  const _PillarSection({required this.icon, required this.title, required this.count, required this.previewLines, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(999)),
                    child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.primaryDark)),
                  ),
                ],
              ),
              if (previewLines.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final line in previewLines.take(2))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                if (previewLines.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        '${basicText('and_conjunction_prefix', lang)}${previewLines.length - 2} ${basicText('others_more_suffix', lang)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
