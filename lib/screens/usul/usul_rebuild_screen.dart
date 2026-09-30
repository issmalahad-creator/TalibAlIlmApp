import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../repositories/knowledge_review_repository.dart';
import '../../repositories/usul_tree_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/spaced_repetition_engine.dart';
import '../../services/usul/usul_rebuild.dart';
import '../../theme/app_theme.dart';
import '../../theme/depth.dart';
import '../../theme/motion.dart';
import '../../widgets/loading_view.dart';

// The usul tree's paper palette (usul_tree_screen.dart).
const _page = Color(0xFFFBF6EE);
const _ink = Color(0xFF1F3B44);
const _leafFill = Color(0xFFF1EEE8);
const _gold = Color(0xFFD9A441);

/// «أعد بناء الشجرة» (USUL_TAFSIR_TREE.md U6): one parent at a time, its
/// children hidden; the student recalls them, uncovers them, and rates
/// their own recall. The card then follows the shared station engine and
/// comes back in «مراجعتك اليوم». No score, no choices to pick from.
class UsulRebuildScreen extends StatefulWidget {
  const UsulRebuildScreen({super.key, this.onlyItemIds});

  /// The cards due today (from «مراجعتك اليوم»); null = the whole tree.
  final Set<int>? onlyItemIds;

  @override
  State<UsulRebuildScreen> createState() => _UsulRebuildScreenState();
}

class _UsulRebuildScreenState extends State<UsulRebuildScreen> {
  final _review = KnowledgeReviewRepository();
  List<UsulRebuildGroup> _groups = const [];
  int _i = 0;
  final _revealed = <String>{};
  bool _loading = true;
  bool _saving = false;

  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final root = await UsulTreeRepository().tree();
    final all = root == null ? const <UsulRebuildGroup>[] : usulRebuildGroups(root);
    final only = widget.onlyItemIds;
    if (!mounted) return;
    setState(() {
      _groups = only == null ? all : all.where((g) => only.contains(g.itemId)).toList();
      _loading = false;
    });
  }

  bool get _done => _i >= _groups.length;
  UsulRebuildGroup get _group => _groups[_i];
  bool get _allRevealed => _group.children.every((c) => _revealed.contains(c.id));

  Future<void> _rate(ReviewQuality q) async {
    setState(() => _saving = true);
    final id = _group.itemId;
    // First time: enrol at station 1 (back tomorrow). Afterwards the rating
    // moves it along the stations like every other reviewed item.
    if (await _review.isUnderReview(usulReviewType, id)) {
      await _review.recordReview(usulReviewType, id, q);
    } else {
      await _review.startReviewing(usulReviewType, id);
    }
    if (!mounted) return;
    setState(() {
      _i++;
      _revealed.clear();
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        title: Column(
          children: [
            Text(
              basicText('usul_rebuild_title', _lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (!_loading && !_done)
              Text(
                '\u2066${_i + 1} / ${_groups.length}\u2069',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
      body: _loading
          ? AppLoadingView(icon: Icons.account_tree_outlined, message: basicText('loading_quran', _lang))
          : _done
          ? _doneView()
          : _cardView(),
    );
  }

  Widget _cardView() {
    final g = _group;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Text(
                basicText('usul_rebuild_recall', _lang),
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              _Hex(text: g.prompt, fill: _ink, textColor: Colors.white, shadows: DepthShadows.floating(_ink)),
              const SizedBox(height: 16),
              for (final (k, c) in g.children.indexed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 28, bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _revealed.add(c.id)),
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      switchInCurve: AppMotion.entranceCurve,
                      child: _revealed.contains(c.id)
                          ? _Hex(
                              key: ValueKey('r${c.id}'),
                              text: c.title,
                              fill: _leafFill,
                              textColor: _ink,
                              edge: _gold,
                              shadows: DepthShadows.soft(_ink),
                            )
                          : _Hex(
                              key: ValueKey('h${c.id}'),
                              text: '${k + 1}  ·  ؟',
                              fill: _leafFill.withValues(alpha: 0.6),
                              textColor: AppColors.textMuted,
                              shadows: const [],
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _allRevealed ? _ratingRow() : _revealAll(g),
          ),
        ),
      ],
    );
  }

  Widget _revealAll(UsulRebuildGroup g) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: () => setState(() => _revealed.addAll(g.children.map((c) => c.id))),
      icon: const Icon(Icons.visibility_outlined),
      label: Text(basicText('usul_rebuild_reveal_all', _lang)),
    ),
  );

  Widget _ratingRow() {
    Widget b(String key, Color color, ReviewQuality q) => Expanded(
      child: FilledButton(
        // In a Row: the theme's full-width minimumSize would blank the row.
        style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size(0, 44)),
        onPressed: _saving ? null : () => _rate(q),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(basicText(key, _lang), maxLines: 1)),
      ),
    );
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          b('rating_needs_review', AppColors.textMuted, ReviewQuality.needsReview),
          const SizedBox(width: 8),
          b('rating_good', AppColors.primary, ReviewQuality.good),
          const SizedBox(width: 8),
          b('rating_excellent', AppColors.primaryDark, ReviewQuality.excellent),
        ],
      ),
    );
  }

  Widget _doneView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_tree_rounded, size: 56, color: _gold),
          const SizedBox(height: 14),
          Text(
            basicText(_groups.isEmpty ? 'nothing_to_review_message' : 'usul_rebuild_done', _lang),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5, height: 1.6, color: _ink),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(basicText('feedback_done', _lang))),
        ],
      ),
    ),
  );
}

/// The tree's hexagon: a bevelled rectangle, the paper map's node shape.
class _Hex extends StatelessWidget {
  const _Hex({
    super.key,
    required this.text,
    required this.fill,
    required this.textColor,
    required this.shadows,
    this.edge,
  });
  final String text;
  final Color fill;
  final Color textColor;
  final Color? edge;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 56),
    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
    alignment: Alignment.center,
    decoration: ShapeDecoration(
      color: fill,
      shadows: shadows,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: edge == null ? BorderSide.none : BorderSide(color: edge!, width: 1.6),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 15, height: 1.4),
    ),
  );
}
