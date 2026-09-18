import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../models/completion_goal_session.dart';
import '../repositories/completion_goal_repository.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'completion_goal_session_editor.dart' show CompletionGoalSessionEditSheet;

String _surahName(int surahNumber) => quranSurahs[surahNumber - 1].name;

/// KHATM_SYSTEM_AND_STYLE_REFERENCE.md §2.5, merged into the §2.3.7أ session
/// engine 2026-09-18 — the live plan card's "قائمة الأوراد": one row per
/// actual plan day (not a fixed 7), editable (pages, and an optional
/// per-werd reminder), backed by [CompletionGoalRepository.ensureWerds] /
/// [CompletionGoalRepository.werdsFor] / [CompletionGoalRepository.replaceWerds].
///
/// Every edit persists immediately (unlike [CompletionGoalSessionEditor],
/// which builds a list in memory for the *creation* wizard to save once) —
/// this list belongs to an already-existing goal, so there is no "إنشاء
/// الخطة" moment to defer to.
class CompletionGoalWerdList extends StatefulWidget {
  final CompletionGoal goal;
  const CompletionGoalWerdList({super.key, required this.goal});

  @override
  State<CompletionGoalWerdList> createState() => _CompletionGoalWerdListState();
}

typedef _AyahBounds = ({int firstSurah, int firstAyah, int lastSurah, int lastAyah});

class _CompletionGoalWerdListState extends State<CompletionGoalWerdList> {
  final _repo = CompletionGoalRepository();
  final _layoutRepo = MushafLayoutRepository();
  List<CompletionGoalSession>? _werds;
  List<_AyahBounds?> _bounds = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final werds = await _repo.ensureWerds(widget.goal);
    await _recomputeBounds(werds);
  }

  /// Each werd's page range is derived, never stored — `units` (page
  /// count) plus the goal's own `startUnit` and the PRIOR werds' units is
  /// always enough, so an edit/add/delete never needs to touch a separate
  /// "start page" column that could drift out of sync.
  Future<void> _recomputeBounds(List<CompletionGoalSession> werds) async {
    final bounds = <_AyahBounds?>[];
    var page = widget.goal.startUnit ?? 1;
    for (final w in werds) {
      final startPage = page.clamp(1, 604);
      final endPage = (page + w.units - 1).clamp(1, 604);
      final first = await _layoutRepo.ayahBoundsForPage(startPage);
      final last = await _layoutRepo.ayahBoundsForPage(endPage);
      bounds.add(first == null || last == null
          ? null
          : (firstSurah: first.firstSurah, firstAyah: first.firstAyah, lastSurah: last.lastSurah, lastAyah: last.lastAyah));
      page += w.units;
    }
    if (!mounted) return;
    setState(() {
      _werds = werds;
      _bounds = bounds;
    });
  }

  Future<void> _persist(List<CompletionGoalSession> next) async {
    await _repo.replaceWerds(widget.goal.id, next);
    await _recomputeBounds(next);
  }

  /// Same rebalance rule as §2.3.7أ's session editor — the last werd
  /// absorbs the difference so the total always stays exactly the goal's
  /// `total_units`, never silently drifting.
  void _rebalanceAfterEdit(List<CompletionGoalSession> list, int editedIndex, int oldUnits, int newUnits) {
    final diff = newUnits - oldUnits;
    if (diff == 0 || list.length < 2) return;
    final lastIndex = list.length - 1;
    final absorber = editedIndex == lastIndex ? lastIndex - 1 : lastIndex;
    final absorbed = (list[absorber].units - diff).clamp(0, 1 << 30);
    list[absorber] = list[absorber].copyWith(units: absorbed);
  }

  Future<void> _editWerd(int index) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final w = _werds![index];
    final edited = await showModalBottomSheet<CompletionGoalSession>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CompletionGoalSessionEditSheet(session: w, lang: lang, showReminderToggle: true),
    );
    if (edited == null) return;
    final next = [..._werds!];
    next[index] = edited.copyWith(sortOrder: index);
    _rebalanceAfterEdit(next, index, w.units, edited.units);
    await _persist(next);
  }

  Future<void> _deleteWerd(int index) async {
    if (_werds!.length <= 1) return;
    final removedUnits = _werds![index].units;
    final next = [..._werds!]..removeAt(index);
    next[next.length - 1] = next.last.copyWith(units: next.last.units + removedUnits);
    await _persist([for (var i = 0; i < next.length; i++) next[i].copyWith(sortOrder: i)]);
  }

  Future<void> _addWerd() async {
    final next = [
      ..._werds!,
      CompletionGoalSession(
        goalId: widget.goal.id,
        sortOrder: _werds!.length,
        label: 'الورد ${_werds!.length + 1}',
        anchorType: 'fixed',
        fixedHour: 20,
        fixedMinute: 0,
        units: 0,
        listKind: 'werd',
        reminderEnabled: false,
      ),
    ];
    await _persist(next);
  }

  /// "إعادة الضبط الافتراضي" — discards every custom edit and regenerates
  /// the default split (classical تحزيب الصحابة when it applies, else the
  /// general even day-split), same as §2.3.7أ's own reset.
  Future<void> _resetToDefault() async {
    await _repo.replaceWerds(widget.goal.id, const []);
    final regenerated = await _repo.ensureWerds(widget.goal);
    await _recomputeBounds(regenerated);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final werds = _werds;
    // A full, independent page (own Scaffold + AppBar + virtualized
    // ListView.builder) rather than an inline Column expanded in place
    // inside the goal card — that card already lives inside a scrollable
    // list, inside a DraggableScrollableSheet, over the always-on mushaf
    // reader, and has broken once before from an unrelated widget leaving
    // that stack's layout unresolved. A khatm plan can have 30+ werd rows;
    // rendering them unvirtualized in that nested context risked jank/hangs
    // on longer plans. A pushed page keeps the heavy reader off-screen
    // entirely and gives the list normal, full-height ListView.builder
    // virtualization.
    return Scaffold(
      appBar: AppBar(title: Text(basicText('khatm_werd_list_title', lang))),
      body: werds == null
          ? const Center(child: CircularProgressIndicator())
          : _WerdListBody(
              werds: werds,
              bounds: _bounds,
              goal: widget.goal,
              onEdit: _editWerd,
              onDelete: _deleteWerd,
            ),
      bottomNavigationBar: werds == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (werds.fold<int>(0, (sum, w) => sum + w.units) != widget.goal.totalUnits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${basicText('khatm_distributed_label', lang)}: '
                          '${werds.fold<int>(0, (sum, w) => sum + w.units)} '
                          '${basicText('khatm_of_label', lang)} ${widget.goal.totalUnits}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.redAccent),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _addWerd,
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(basicText('khatm_add_werd_action', lang)),
                        ),
                        TextButton(
                          onPressed: _resetToDefault,
                          child: Text(basicText('khatm_reset_sessions_action', lang)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _WerdListBody extends StatelessWidget {
  final List<CompletionGoalSession> werds;
  final List<_AyahBounds?> bounds;
  final CompletionGoal goal;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  const _WerdListBody({
    required this.werds,
    required this.bounds,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: werds.length,
      itemBuilder: (context, i) {
        final b = bounds.length > i ? bounds[i] : null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  b != null
                      ? '${basicText('khatm_werd_label', lang)} ${i + 1}: ${_surahName(b.firstSurah)} ${b.firstAyah} '
                          '${basicText('khatm_werd_range_to_label', lang)} ${_surahName(b.lastSurah)} ${b.lastAyah}'
                      : '${basicText('khatm_werd_label', lang)} ${i + 1}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
              Text('${werds[i].units}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 17),
                visualDensity: VisualDensity.compact,
                onPressed: () => onEdit(i),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 17, color: Colors.redAccent),
                visualDensity: VisualDensity.compact,
                onPressed: werds.length > 1 ? () => onDelete(i) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
