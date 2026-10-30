import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/hifz_schedule_repository.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../services/hifz/schedule_generator.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../utils/calendar_days.dart';
import '../utils/date_display.dart';
import '../utils/hijri_date.dart';
import 'page_hifz_session_screen.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// «جدول الحفظ» — ح2/ح3 of `docs/memorization/HIFZ_SCHEDULE_ARCHITECTURE.md`.
///
/// No plan yet: five timeline cards (daily load, end-of-plan time, pace badge,
/// a plain warning on the full-time-only ones) and the direction. With a
/// plan: today's four tracks — new, link, recent review, manzil — and the
/// whole plan as monthly tables like the reference app, generated on the
/// phone from the muṣḥaf's real line counts. Nothing here changes stored
/// memorization progress or review dates.
class HifzScheduleScreen extends StatefulWidget {
  const HifzScheduleScreen({super.key});

  @override
  State<HifzScheduleScreen> createState() => _HifzScheduleScreenState();
}

class _HifzScheduleScreenState extends State<HifzScheduleScreen> {
  final _repo = HifzScheduleRepository();

  bool _loading = true;
  HifzPlanChoice? _choice;
  HifzSchedule? _schedule;

  // ح4: live progress against the plan, and the two re-plans offered when
  // the student is behind (computed only then).
  HifzProgress? _progress;
  (HifzPlanChoice, HifzSchedule)? _catchUp;
  (HifzPlanChoice, HifzSchedule)? _keepPace;

  // chooser state
  HifzDirection _direction = HifzDirection.hybrid;
  HifzTimeline _timeline = HifzTimeline.months24;
  Set<int> _memorized = {};
  bool _skipMemorized = true;
  Map<HifzTimeline, double>? _estimates;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final choice = await _repo.choice();
    final memorized = await _repo.memorizedSurahs();
    HifzSchedule? schedule;
    HifzProgress? progress;
    (HifzPlanChoice, HifzSchedule)? catchUp, keepPace;
    if (choice != null) {
      schedule = await _repo.schedule(choice);
      progress = await _repo.progress(choice, schedule);
      if (progress.lagDays > 0) {
        final a = await _repo.replan(choice, schedule, keepPace: false);
        final b = await _repo.replan(choice, schedule, keepPace: true);
        catchUp = (a, await _repo.schedule(a));
        keepPace = (b, await _repo.schedule(b));
      }
    }
    if (!mounted) return;
    setState(() {
      _choice = choice;
      _schedule = schedule;
      _progress = progress;
      _catchUp = catchUp;
      _keepPace = keepPace;
      _memorized = memorized;
      _loading = false;
    });
    if (choice == null) _refreshEstimates();
  }

  Future<void> _refreshEstimates() async {
    setState(() => _estimates = null);
    final e = await _repo.estimates(_direction, _skipMemorized ? _memorized : const {});
    if (!mounted) return;
    setState(() => _estimates = e);
  }

  Future<void> _startPlan() async {
    final now = DateTime.now();
    final c = HifzPlanChoice(
      direction: _direction,
      timeline: _timeline,
      start: DateTime(now.year, now.month, now.day),
      memorizedSurahs: _skipMemorized ? _memorized : const {},
      memorizedUnits: _skipMemorized ? await _repo.memorizedUnits() : const {},
    );
    if (!mounted) return;
    setState(() => _loading = true);
    await _repo.save(c);
    await _load();
  }

  Future<void> _adopt(HifzPlanChoice c) async {
    setState(() => _loading = true);
    await _repo.save(c);
    await _load();
  }

  /// A calendar date in the student's calendar and language.
  static String _date(DateTime d) => formatDateForDisplay(hijriDateStringForDate(d));

  Future<void> _changePlan() async {
    await _repo.clear();
    if (!mounted) return;
    setState(() {
      _choice = null;
      _schedule = null;
    });
    _refreshEstimates();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, _, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_t('hs_title')),
          actions: [
            if (_choice != null) TextButton(onPressed: _changePlan, child: Text(_t('hs_change'))),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _choice == null
                ? _chooser()
                : _planView(),
      ),
    );
  }

  // ── chooser ─────────────────────────────────────────────────────────

  static String _timelineLabel(HifzTimeline t) => _t('hs_tl_${t.name}');

  static (String, Color) _pace(HifzTimeline t) => switch (t) {
        HifzTimeline.months6 || HifzTimeline.months10 => (_t('hs_pace_max'), const Color(0xFFC0392B)),
        HifzTimeline.months19 => (_t('hs_pace_medium'), const Color(0xFFB5651D)),
        _ => (_t('hs_pace_relaxed'), AppColors.primary),
      };

  /// End-of-plan daily time by §3.4: new lines ×2 min + (7 days of recent
  /// portions + 604/30 manzil pages) ×2.5 min.
  static double _hoursAtEnd(double q) => (q * 2 + (7 * q / HifzScheduleRepository.linesPerPage + 604 / 30) * 2.5) / 60;

  Widget _chooser() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_t('hs_direction'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in [HifzDirection.hybrid, HifzDirection.reverse, HifzDirection.mushaf])
              ChoiceChip(
                label: Text(_t('hs_dir_${d.name}')),
                selected: _direction == d,
                onSelected: (_) {
                  setState(() => _direction = d);
                  _refreshEstimates();
                },
              ),
          ],
        ),
        if (_memorized.isNotEmpty)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _skipMemorized,
            title: Text(_t('hs_skip_memorized').replaceAll('{n}', '${_memorized.length}')),
            onChanged: (v) {
              setState(() => _skipMemorized = v);
              _refreshEstimates();
            },
          ),
        const SizedBox(height: 14),
        Text(_t('hs_choose'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        for (final t in HifzTimeline.values) _timelineCard(t),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _estimates == null ? null : _startPlan,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_t('hs_start')),
        ),
        const SizedBox(height: 12),
        Text(_t('hs_honest_note'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
      ],
    );
  }

  Widget _timelineCard(HifzTimeline t) {
    final selected = _timeline == t;
    final (pace, paceColor) = _pace(t);
    final q = _estimates?[t];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: selected ? 0.10 : 0.04), blurRadius: selected ? 14 : 6, offset: Offset(0, selected ? 6 : 2)),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _timeline = t),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_timelineLabel(t), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: paceColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(pace, style: TextStyle(color: paceColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 6),
                q == null
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        _t('hs_per_day')
                            .replaceAll('{p}', (q / HifzScheduleRepository.linesPerPage).toStringAsFixed(1))
                            .replaceAll('{h}', _hoursAtEnd(q).toStringAsFixed(1)),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                if (t == HifzTimeline.months6 || t == HifzTimeline.months10)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_t('hs_fulltime_warning'), style: TextStyle(color: paceColor, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── the plan ────────────────────────────────────────────────────────

  Widget _planView() {
    final s = _schedule!;
    final c = _choice!;
    final dayNo = c.dayNumber(DateTime.now());
    final today = HifzToday.of(s, dayNo);
    final tables = (s.days.length / 30).ceil();
    final currentTable = ((dayNo - 1) ~/ 30).clamp(0, tables - 1);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_timelineLabel(c.timeline)} · ${_t('hs_dir_${c.direction.name}')}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          _t('hs_day_of').replaceAll('{d}', '${dayNo.clamp(1, s.days.length)}').replaceAll('{t}', '${s.days.length}'),
          style: const TextStyle(color: AppColors.textMuted),
        ),
        Text(
          _t('hs_khatm_on').replaceAll('{date}', _date(addCalendarDays(c.start, s.days.length - 1))),
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        if (_progress != null) _progressCard(_progress!),
        if (today == null)
          Text(_t('hs_plan_over'))
        else
          _todayCard(today),
        const SizedBox(height: 16),
        for (var k = 0; k < tables; k++) _table(s, k, dayNo, k == currentTable),
        if (_progress != null && _progress!.byDay.isNotEmpty)
          Text(_t('hs_status_note'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        const SizedBox(height: 8),
        Text(_t('hs_honest_note'), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
      ],
    );
  }

  static String _ref((int, int) r) => '${HifzScheduleRepository.surahName(r.$1)} ${r.$2}';

  static String _dayLabel(DayPlan d) => switch (d.kind) {
        DayKind.newPortion => '${_ref(d.from!)} ← ${_ref(d.to!)}',
        DayKind.reviewSurah => _t('hs_kind_review_surah').replaceAll('{s}', HifzScheduleRepository.surahName(d.ref!)),
        DayKind.reviewJuz => _t('hs_kind_review_juz').replaceAll('{j}', '${d.ref}'),
        DayKind.weekly => _t('hs_kind_weekly'),
        DayKind.khatmCycle => _t('hs_kind_khatm').replaceAll('{n}', '${d.ref}'),
      };

  Future<void> _memorizeNow(DayPlan d) async {
    final page = await MushafLayoutRepository().pageForAyah(d.from!.$1, d.from!.$2);
    if (!mounted || page == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PageHifzSessionScreen(page: page)));
  }

  Widget _todayCard(HifzToday t) {
    final d = t.plan;
    final sabqiLines = t.sabqi.fold<double>(0, (s, x) => s + x.lines);
    String pages(double lines) => (lines / HifzScheduleRepository.linesPerPage).toStringAsFixed(1);

    Widget track(IconData icon, String title, String body, {Widget? action}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(body, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ?action,
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_t('hs_today'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(_t('hs_minutes').replaceAll('{m}', '${t.minutes}'), style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
          const Divider(),
          if (d.kind == DayKind.newPortion)
            track(
              Icons.auto_stories_rounded,
              _t('hs_track_sabaq'),
              '${_dayLabel(d)} · ${_t('hs_lines').replaceAll('{n}', d.lines.toStringAsFixed(0))}',
              action: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(onPressed: () => _memorizeNow(d), icon: const Icon(Icons.checklist_rounded, size: 18), label: Text(_t('hs_memorize_now'))),
              ),
            )
          else
            track(Icons.event_repeat_rounded, _dayLabel(d), ''),
          if (d.kind == DayKind.newPortion && t.previousNew != null)
            track(Icons.link_rounded, _t('hs_track_rabt'), '${_t('hs_rabt_text')} — ${_ref(t.previousNew!.to!)} ← ${_ref(d.from!)}'),
          if (t.sabqi.isNotEmpty)
            track(
              Icons.replay_rounded,
              _t('hs_track_sabqi'),
              _t('hs_sabqi_text').replaceAll('{n}', '${t.sabqi.length}').replaceAll('{p}', pages(sabqiLines)),
            ),
          if (t.manzilLines / HifzScheduleRepository.linesPerPage >= 0.1)
            track(Icons.all_inclusive_rounded, _t('hs_track_manzil'), _t('hs_manzil_text').replaceAll('{p}', pages(t.manzilLines))),
        ],
      ),
    );
  }

  static Widget _statusMark(DayProgress? p) => switch (p) {
        DayProgress.done => const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
        DayProgress.partial => const Icon(Icons.timelapse_rounded, size: 16, color: Color(0xFFB5651D)),
        DayProgress.missed => const Icon(Icons.radio_button_unchecked_rounded, size: 16, color: Color(0xFFC0392B)),
        null => const SizedBox.shrink(),
      };

  /// Behind → two kind choices with their real numbers; ahead → a word of
  /// encouragement; on track → nothing (ح4). Never a penalty or a streak.
  Widget _progressCard(HifzProgress p) {
    String pages(double lines) => (lines / HifzScheduleRepository.linesPerPage).toStringAsFixed(1);
    if (p.lagDays < 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(_t('hs_ahead').replaceAll('{n}', '${-p.lagDays}'), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
      );
    }
    final a = _catchUp, b = _keepPace;
    if (p.lagDays == 0 || a == null || b == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0D3A8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_t('hs_behind').replaceAll('{n}', '${p.lagDays}'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _adopt(a.$1),
            child: Text(_t('hs_catch_up').replaceAll('{p}', pages(a.$2.linesPerDay)), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () => _adopt(b.$1),
            child: Text(
              _t('hs_keep_pace')
                  .replaceAll('{p}', pages(b.$2.linesPerDay))
                  .replaceAll('{date}', _date(addCalendarDays(b.$1.start, b.$2.days.length - 1))),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(HifzSchedule s, int k, int dayNo, bool current) {
    final days = s.days.sublist(k * 30, ((k + 1) * 30).clamp(0, s.days.length));
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.divider)),
      child: ExpansionTile(
        shape: const Border(),
        initiallyExpanded: current,
        title: Text(_t('hs_table').replaceAll('{n}', '${k + 1}'), style: TextStyle(fontWeight: current ? FontWeight.w800 : FontWeight.w600)),
        subtitle: Text('${days.first.day} – ${days.last.day}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        children: [
          for (final d in days)
            Container(
              color: d.day == dayNo ? AppColors.primary.withValues(alpha: 0.10) : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text('${d.day}', style: TextStyle(fontWeight: FontWeight.w700, color: d.day < dayNo ? AppColors.textMuted : AppColors.textDark)),
                  ),
                  SizedBox(width: 22, child: _statusMark(_progress?.byDay[d.day])),
                  Expanded(
                    child: Text(
                      _dayLabel(d),
                      style: TextStyle(
                        fontSize: 13,
                        color: d.kind == DayKind.newPortion ? (d.day < dayNo ? AppColors.textMuted : AppColors.textDark) : const Color(0xFFB5651D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
