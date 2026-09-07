import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/basic_translations.dart';
import '../models/life_plan.dart';
import '../repositories/life_plan_repository.dart';
import '../services/language_preference_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'life_cycle_review_screen.dart';
import 'life_day_note_sheet.dart';
import 'life_plan_edit_screen.dart';
import 'life_progress_screen.dart';
import 'life_weekly_review_screen.dart';

/// «مُحرّك الحياة» — L2 · the «اليوم» surface (`docs/LIFE_ENGINE.md`).
///
/// A continuous daily engine: the current time-block up front (tap to
/// complete, with a haptic + the ring springing), the day's ring, the 7
/// pillars, and the full 23-slot list. No 90-day countdown — the header
/// shows an unbounded «اليوم N».
class LifePlanScreen extends StatefulWidget {
  /// True when opened from the nightly «حاسب نفسك» notification — the
  /// reflection sheet is shown as soon as the screen settles.
  final bool openNote;
  const LifePlanScreen({super.key, this.openNote = false});

  @override
  State<LifePlanScreen> createState() => _LifePlanScreenState();
}

class _LifePlanScreenState extends State<LifePlanScreen>
    with WidgetsBindingObserver {
  final _repo = LifePlanRepository();
  final _notifications = NotificationService();
  Timer? _midnightTimer;
  bool _cyclePrompting = false;

  bool _loading = true;
  List<LifePillar> _pillars = const [];
  List<LifeSlot> _slots = const [];
  LifeDayProgress? _prog;
  LifeSlot? _current;
  int _dayIndex = 0;
  List<LifeMit> _mit = const [];
  LifeDayTasks? _dayTasks;

  String get _lang => LanguagePreferenceService.currentLanguage;
  String get _today => LifePlanRepository.today();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _armMidnight();
    if (widget.openNote) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final saved = await showLifeDayNoteSheet(context);
        if (saved && mounted) _load(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
      _armMidnight();
    }
  }

  /// At the next local midnight (+3s slack): reload so «اليوم N» rolls over
  /// and today's one-shot reminders are rebuilt for the new day. Re-arms
  /// itself; also re-armed on every resume in case the device slept through.
  void _armMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1, seconds: 3));
    _midnightTimer = Timer(next.difference(now), () {
      if (!mounted) return;
      _load(silent: true);
      _armMidnight();
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final pillars = await _repo.pillars();
    final slots = await _repo.slots();
    final prog = await _repo.progress(_today);
    final cur = await _repo.currentSlot();
    final di = await _repo.dayIndex();
    final mit = await _repo.mitFor(_today);
    final dayTasks = await _repo.tasksForDay(_today);
    if (!mounted) return;
    setState(() {
      _pillars = pillars;
      _slots = slots;
      _prog = prog;
      _current = cur;
      _dayIndex = di;
      _mit = mit;
      _dayTasks = dayTasks;
      _loading = false;
    });
    // Keep today's block nudges / nightly review in sync with what's now
    // ticked — a completed block loses its reminder, a resume refreshes copy.
    unawaited(_notifications.scheduleLifePlanReminders());
    unawaited(_maybePromptCycleReview());
  }

  /// A cycle (90 days) has completed and its rollover ritual hasn't been
  /// done — push it once. Re-prompts on a later load if backed out of; it's
  /// a once-per-90-days moment, not a nag.
  Future<void> _maybePromptCycleReview() async {
    if (_cyclePrompting || !mounted) return;
    final cycle = await _repo.pendingCycleReview();
    if (cycle == null || !mounted) return;
    _cyclePrompting = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LifeCycleReviewScreen(cycle: cycle)),
    );
    _cyclePrompting = false;
    if (mounted) _load(silent: true);
  }

  Future<void> _toggle(int slotNo) async {
    await _repo.toggleSlot(_today, slotNo);
    unawaited(HapticFeedback.mediumImpact());
    await _load(silent: true);
  }

  /// Tap-cycle a plain slot: empty → half → full → empty (L6-DYN #4).
  Future<void> _cycleSlot(int slotNo) async {
    await _repo.cycleSlot(_today, slotNo);
    unawaited(HapticFeedback.selectionClick());
    await _load(silent: true);
  }

  Future<void> _setSlotQty(int slotNo, int qty) async {
    await _repo.setSlotQty(_today, slotNo, qty);
    unawaited(HapticFeedback.selectionClick());
    await _load(silent: true);
  }

  Future<void> _cycleTask(int id) async {
    await _repo.cycleTask(_today, id);
    unawaited(HapticFeedback.selectionClick());
    await _load(silent: true);
  }

  Future<void> _setTaskQty(int id, int qty) async {
    await _repo.setTaskQty(_today, id, qty);
    unawaited(HapticFeedback.selectionClick());
    await _load(silent: true);
  }

  LifeSlot? get _nextSlot {
    final now = DateTime.now();
    final m = now.hour * 60 + now.minute;
    for (final s in _slots) {
      if (s.startMin > m) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final prog = _prog;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE),
      appBar: AppBar(
        title: Text(basicText('life_engine_title', lang),
            textDirection: TextDirection.rtl),
        actions: [
          IconButton(
            tooltip: basicText('life_week_title', lang),
            icon: const Icon(Icons.calendar_view_week_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const LifeWeeklyReviewScreen()),
            ),
          ),
          IconButton(
            tooltip: basicText('life_progress_title', lang),
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LifeProgressScreen()),
            ),
          ),
          IconButton(
            tooltip: basicText('life_edit_plan', lang),
            icon: const Icon(Icons.tune_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LifePlanEditScreen()),
              );
              if (mounted) _load(silent: true);
            },
          ),
        ],
      ),
      body: _loading || prog == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _headerLine(lang),
                  const SizedBox(height: 12),
                  _nowCard(lang),
                  const SizedBox(height: 16),
                  _DayRing(
                    done: prog.doneCount,
                    total: prog.totalCount,
                    label: '${prog.doneCount} / ${prog.totalCount}',
                  ),
                  const SizedBox(height: 16),
                  _mitCard(lang),
                  const SizedBox(height: 16),
                  _pillarsStrip(lang),
                  const SizedBox(height: 18),
                  Text(basicText('life_todays_blocks', lang),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 8),
                  for (final s in _slots) _slotRow(s, lang),
                  if (!(_dayTasks?.isEmpty ?? true)) ...[
                    const SizedBox(height: 18),
                    Text(basicText('life_tasks_section', lang),
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 8),
                    _tasksSection(lang),
                  ],
                  const SizedBox(height: 14),
                  _noteRow(lang),
                ],
              ),
            ),
    );
  }

  // ── L6-DYN #3 · MITs + tasks ─────────────────────────────────────────

  Future<void> _saveMitText(int slot, String text) async {
    await _repo.setMitText(_today, slot, text);
    _load(silent: true);
  }

  Future<void> _toggleMit(int slot) async {
    if (_mit.length <= slot || _mit[slot].isEmpty) return;
    unawaited(HapticFeedback.selectionClick());
    await _repo.toggleMit(_today, slot);
    _load(silent: true);
  }

  Future<void> _toggleTask(int id) async {
    unawaited(HapticFeedback.selectionClick());
    await _repo.toggleTask(_today, id);
    _load(silent: true);
  }

  Future<void> _toggleMilestone(int id, bool done) async {
    unawaited(HapticFeedback.selectionClick());
    await _repo.setMilestoneDone(id, done);
    _load(silent: true);
  }

  Widget _mitCard(String lang) {
    final p = _mit.where((e) => !e.isEmpty).toList();
    final done = p.where((e) => e.done).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0x332F5C46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(basicText('life_mit_title', lang),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textDark)),
              const Spacer(),
              if (p.isNotEmpty)
                Text('$done / ${p.length}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          for (var i = 0; i < 3; i++)
            _MitRow(
              key: ValueKey('mit_${_today}_$i'),
              mit: i < _mit.length
                  ? _mit[i]
                  : LifeMit(date: _today, slot: i),
              hint: basicText('life_mit_hint', lang),
              onSubmit: (t) => _saveMitText(i, t),
              onToggle: () => _toggleMit(i),
            ),
        ],
      ),
    );
  }

  Widget _tasksSection(String lang) {
    final dt = _dayTasks!;
    final pillarByKey = {for (final p in _pillars) p.key: p};
    String? pillarLabel(String? k) =>
        k == null ? null : pillarByKey[k]?.label;

    Widget line({
      required String title,
      required bool done,
      required Widget leading,
      VoidCallback? onTap,
      String? trailing,
      String? pillar,
    }) {
      final body = Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      fontSize: 12.5,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color:
                          done ? AppColors.textMuted : AppColors.textDark)),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(trailing,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ),
            if (pillar != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(pillar,
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.primaryDark)),
              ),
          ],
        ),
      );
      return onTap == null
          ? body
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: body);
    }

    return Column(
      children: [
        for (final t in dt.daily)
          if (t.isQuantity)
            line(
              title: t.title,
              done: (dt.dailyQty[t.id] ?? 0) >= t.qtyTarget,
              leading: _QtyStepper(
                value: dt.dailyQty[t.id] ?? 0,
                target: t.qtyTarget,
                unit: t.qtyUnit,
                onChanged: (v) => _setTaskQty(t.id, v),
              ),
              pillar: pillarLabel(t.pillarKey),
            )
          else
            line(
              title: t.title,
              done: dt.dailyProgressOf(t.id) >= 1.0,
              leading: _TriTick(
                progress: dt.dailyProgressOf(t.id),
                onTap: () => _cycleTask(t.id),
              ),
              onTap: () => _cycleTask(t.id),
              pillar: pillarLabel(t.pillarKey),
            ),
        for (final w in dt.weekly)
          line(
            title: w.task.title,
            done: w.doneThisWeek >= w.task.weeklyTarget &&
                w.task.weeklyTarget > 0,
            leading: _TriTick(
                progress: (w.doneThisWeek >= w.task.weeklyTarget &&
                        w.task.weeklyTarget > 0)
                    ? 1.0
                    : 0.0,
                onTap: () => _toggleTask(w.task.id)),
            onTap: () => _toggleTask(w.task.id),
            trailing: w.task.weeklyTarget > 0
                ? '${w.doneThisWeek}/${w.task.weeklyTarget}'
                : '${w.doneThisWeek}',
            pillar: pillarLabel(w.task.pillarKey),
          ),
        for (final m in dt.milestonesOpen)
          line(
            title: '🚩 ${m.title}',
            done: false,
            leading: _TriTick(
                progress: 0.0, onTap: () => _toggleMilestone(m.id, true)),
            onTap: () => _toggleMilestone(m.id, true),
            pillar: pillarLabel(m.pillarKey),
          ),
        for (final m in dt.milestonesDoneToday)
          line(
            title: '🚩 ${m.title}',
            done: true,
            leading: _TriTick(
                progress: 1.0, onTap: () => _toggleMilestone(m.id, false)),
            onTap: () => _toggleMilestone(m.id, false),
            pillar: pillarLabel(m.pillarKey),
          ),
      ],
    );
  }

  Widget _noteRow(String lang) {
    return InkWell(
      onTap: () async {
        final saved = await showLifeDayNoteSheet(context);
        if (saved && mounted) _load(silent: true);
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0x332F5C46)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Text('✍️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(basicText('life_note_title', lang),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark)),
                  Text(basicText('life_note_sub', lang),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _headerLine(String lang) {
    final n = _dayIndex + 1;
    final cycle = (_dayIndex ~/ 90) + 1;
    final dayInCycle = (_dayIndex % 90) + 1;
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text('${basicText('life_day_word', lang)} $n',
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textDark)),
        const SizedBox(width: 8),
        Text(
          '· ${basicText('life_cycle_word', lang)} $cycle '
          '(${basicText('life_day_word', lang)} $dayInCycle/90)',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ── the "now" card ───────────────────────────────────────────────────

  Widget _nowCard(String lang) {
    final cur = _current;
    if (cur != null) {
      final done = _prog!.doneSlotNos.contains(cur.slotNo);
      return _bigCard(
        tint: const Color(0xFFD9A441),
        eyebrow: basicText('life_now', lang),
        eyebrowTime: cur.timeLabel,
        title: cur.activity,
        sub: cur.mihwar ?? '',
        done: done,
        onTap: () => _toggle(cur.slotNo),
      );
    }
    final next = _nextSlot;
    return _bigCard(
      tint: AppColors.primary,
      eyebrow: next == null
          ? basicText('life_day_complete', lang)
          : basicText('life_get_ready', lang),
      eyebrowTime: next?.timeLabel,
      title: next?.activity ?? basicText('life_rest', lang),
      sub: next?.mihwar ?? '',
      done: null,
      onTap: next == null ? null : () => _toggle(next.slotNo),
    );
  }

  Widget _bigCard({
    required Color tint,
    required String eyebrow,
    String? eyebrowTime,
    required String title,
    required String sub,
    required bool? done,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tint.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
              color: tint.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Flexible(
                      child: Text(eyebrow,
                          textDirection: TextDirection.rtl,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tint)),
                    ),
                    if (eyebrowTime != null) ...[
                      const SizedBox(width: 6),
                      Text('· $eyebrowTime',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tint)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(title,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sub,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CompleteButton(tint: tint, done: done, onTap: onTap),
        ],
      ),
    );
  }

  // ── pillars strip ───────────────────────────────────────────────────

  Widget _pillarsStrip(String lang) {
    final by = _prog!.byPillar;
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: _pillars.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = _pillars[i];
          final pct = by[p.key] ?? 0.0;
          return Container(
            width: 96,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.emoji.isEmpty ? '•' : p.emoji,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                  p.label.replaceFirst(RegExp(r'^\S+\s+'), ''),
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFFD9A441)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── slot row ────────────────────────────────────────────────────────

  Widget _slotRow(LifeSlot s, String lang) {
    final p = _prog!.progressOf(s.slotNo);
    final done = p >= 1.0;
    final isNow = _current?.slotNo == s.slotNo;
    final qty = _prog!.slotQty[s.slotNo] ?? 0;
    final row = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isNow
            ? const Color(0xFFD9A441).withValues(alpha: 0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: isNow
                ? const Color(0xFFD9A441).withValues(alpha: 0.4)
                : AppColors.divider),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          if (s.isQuantity)
            _QtyStepper(
              value: qty,
              target: s.qtyTarget,
              unit: s.qtyUnit,
              onChanged: (v) => _setSlotQty(s.slotNo, v),
            )
          else
            _TriTick(progress: p, onTap: () => _cycleSlot(s.slotNo)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.activity,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontSize: 12.5,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color:
                            done ? AppColors.textMuted : AppColors.textDark)),
                Text(s.timeLabel,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (s.isTracked)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(s.mihwar ?? '',
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.primaryDark)),
            ),
        ],
      ),
    );
    // a quantity row has its own +/- taps; only a plain row toggles on body tap
    return s.isQuantity
        ? row
        : InkWell(
            onTap: () => _cycleSlot(s.slotNo),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: row,
          );
  }

}

/// A tap-cycle completion mark: empty ring → left-half filled → full gold
/// (L6-DYN #4). `onTap` null = display-only.
class _TriTick extends StatelessWidget {
  final double progress; // 0 / 0.5 / 1 (anything between rounds visually)
  final VoidCallback? onTap;
  const _TriTick({required this.progress, this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD9A441);
    final full = progress >= 1.0;
    final half = progress >= 0.5 && progress < 1.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: full ? gold : Colors.transparent,
          border: Border.all(
              color: (full || half)
                  ? gold
                  : AppColors.textMuted.withValues(alpha: 0.5),
              width: 1.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: full
            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
            : half
                ? Row(children: [
                    Expanded(
                        child: Container(color: gold.withValues(alpha: 0.9))),
                    const Spacer(),
                  ])
                : null,
      ),
    );
  }
}

/// `−  n / target unit  +` for a quantity slot or task (L6-DYN #4).
class _QtyStepper extends StatelessWidget {
  final int value;
  final int target;
  final String? unit;
  final ValueChanged<int> onChanged;
  const _QtyStepper({
    required this.value,
    required this.target,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final done = target > 0 && value >= target;
    const gold = Color(0xFFD9A441);
    Widget btn(IconData i, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(i, size: 18, color: AppColors.textMuted),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: done ? gold.withValues(alpha: 0.14) : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          btn(Icons.remove, () => onChanged(value - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              target > 0 ? '$value/$target' : '$value',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: done ? gold : AppColors.primaryDark),
            ),
          ),
          btn(Icons.add, () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

// ── the completion button on the "now" card ────────────────────────────

class _CompleteButton extends StatelessWidget {
  final Color tint;
  final bool? done; // null = not a togglable "now" (next-slot / rest)
  final VoidCallback? onTap;
  const _CompleteButton({required this.tint, required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = done ?? false;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.entranceCurve,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: d ? tint : tint.withValues(alpha: 0.12),
          border: Border.all(color: tint, width: 2),
        ),
        child: Icon(
          d ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
          color: d ? Colors.white : tint,
          size: 28,
        ),
      ),
    );
  }
}

// ── the day ring ──────────────────────────────────────────────────────

class _DayRing extends StatelessWidget {
  final int done;
  final int total;
  final String label;
  const _DayRing({required this.done, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    final target = total == 0 ? 0.0 : done / total;
    return Center(
      child: SizedBox(
        width: 132,
        height: 132,
        child: TweenAnimationBuilder<double>(
          duration: AppMotion.premium,
          curve: AppMotion.entranceCurve,
          tween: Tween(begin: 0, end: target),
          builder: (context, v, _) => CustomPaint(
            painter: _RingPainter(v),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(v * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  Text(label,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v; // 0..1
  _RingPainter(this.v);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color(0xFFE5E7EB);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFFE8C877), Color(0xFFD9A441)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        2 * math.pi * v.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v;
}

/// One editable «أهمّ 3» row — a tick + an inline text field that commits
/// on submit or when it loses focus. Empty text retires the row.
class _MitRow extends StatefulWidget {
  final LifeMit mit;
  final String hint;
  final ValueChanged<String> onSubmit;
  final VoidCallback onToggle;
  const _MitRow({
    super.key,
    required this.mit,
    required this.hint,
    required this.onSubmit,
    required this.onToggle,
  });

  @override
  State<_MitRow> createState() => _MitRowState();
}

class _MitRowState extends State<_MitRow> {
  late final TextEditingController _c =
      TextEditingController(text: widget.mit.text);
  late final FocusNode _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(covariant _MitRow old) {
    super.didUpdateWidget(old);
    // keep the field in sync when a reload brings new text and we're idle
    if (!_f.hasFocus && widget.mit.text != _c.text) {
      _c.text = widget.mit.text;
    }
  }

  void _commit() {
    if (_c.text.trim() != widget.mit.text.trim()) {
      widget.onSubmit(_c.text);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.mit.done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: widget.mit.text.trim().isEmpty ? null : widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: done
                    ? const Color(0xFFD9A441)
                    : AppColors.textMuted.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _c,
              focusNode: _f,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _commit(),
              style: TextStyle(
                fontSize: 12.5,
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? AppColors.textMuted : AppColors.textDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: const TextStyle(
                    fontSize: 12.5, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
