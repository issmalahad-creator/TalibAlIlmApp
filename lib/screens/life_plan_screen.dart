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
    if (!mounted) return;
    setState(() {
      _pillars = pillars;
      _slots = slots;
      _prog = prog;
      _current = cur;
      _dayIndex = di;
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
                  _pillarsStrip(lang),
                  const SizedBox(height: 18),
                  Text(basicText('life_todays_blocks', lang),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 8),
                  for (final s in _slots) _slotRow(s, lang),
                  const SizedBox(height: 14),
                  _noteRow(lang),
                ],
              ),
            ),
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
    final done = _prog!.doneSlotNos.contains(s.slotNo);
    final isNow = _current?.slotNo == s.slotNo;
    return InkWell(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        _toggle(s.slotNo);
      },
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
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
            _tick(done),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.activity,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                          fontSize: 12.5,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          color: done
                              ? AppColors.textMuted
                              : AppColors.textDark)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
      ),
    );
  }

  Widget _tick(bool done) => AnimatedContainer(
        duration: AppMotion.fast,
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? const Color(0xFFD9A441) : Colors.transparent,
          border: Border.all(
              color: done
                  ? const Color(0xFFD9A441)
                  : AppColors.textMuted.withValues(alpha: 0.5),
              width: 1.6),
        ),
        child: done
            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
            : null,
      );
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
