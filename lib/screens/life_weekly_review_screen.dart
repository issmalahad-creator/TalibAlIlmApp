import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/life_plan.dart';
import '../repositories/life_plan_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'life_day_note_sheet.dart';

/// «مُحرّك الحياة» — L5 · «ملخص الأسبوع» (`docs/LIFE_ENGINE.md` §3).
///
/// The last 7 days as one calm page: the week's bars, the completion delta
/// vs the previous week, per-pillar standing with a ▲/▼, the strongest and
/// the one that needs attention, the streak, this week's saved notes, and a
/// shortcut into today's reflection. Nothing here ends at day 90.
class LifeWeeklyReviewScreen extends StatefulWidget {
  const LifeWeeklyReviewScreen({super.key});

  @override
  State<LifeWeeklyReviewScreen> createState() => _LifeWeeklyReviewScreenState();
}

class _LifeWeeklyReviewScreenState extends State<LifeWeeklyReviewScreen> {
  final _repo = LifePlanRepository();
  LifeWeekSummary? _sum;
  bool _loading = true;
  bool _failed = false;

  static const _gold = Color(0xFFD9A441);
  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _failed = false);
    try {
      final s = await _repo.weeklyReview();
      if (!mounted) return;
      setState(() {
        _sum = s;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('LifeWeeklyReviewScreen._load failed: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final s = _sum;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE),
      appBar: AppBar(
        title: Text(basicText('life_week_title', lang),
            textDirection: TextDirection.rtl),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_failed || s == null)
              ? _errorState(lang)
              : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  _rangeLine(s, lang),
                  const SizedBox(height: 12),
                  _weekBars(s),
                  const SizedBox(height: 16),
                  _headline(s, lang),
                  const SizedBox(height: 16),
                  _sectionTitle(basicText('life_momentum_title', lang)),
                  const SizedBox(height: 8),
                  for (final p in s.pillars) _pillarRow(p),
                  const SizedBox(height: 16),
                  _callouts(s, lang),
                  const SizedBox(height: 18),
                  _sectionTitle(basicText('life_week_notes', lang)),
                  const SizedBox(height: 8),
                  if (s.notes.isEmpty)
                    _emptyNotes(lang)
                  else
                    for (final n in s.notes) _noteCard(n),
                  const SizedBox(height: 16),
                  _reflectButton(lang),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13));

  // Shown only if `weeklyReview()` itself throws — never in normal use, but
  // better than an endless spinner. Pull down to try again.
  Widget _errorState(String lang) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Text(basicText('life_week_no_notes', lang),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _rangeLine(LifeWeekSummary s, String lang) => Text(
        '${_pretty(s.fromDate)} — ${_pretty(s.toDate)}',
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      );

  String _pretty(String ymd) {
    final p = ymd.split('-');
    return '${p[2]}/${p[1]}';
  }

  // ── the week's 7 bars ───────────────────────────────────────────────

  Widget _weekBars(LifeWeekSummary s) {
    return SizedBox(
      height: 104,
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in s.days.reversed)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${(d.pct * 100).round()}',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted)),
                  const SizedBox(height: 3),
                  TweenAnimationBuilder<double>(
                    duration: AppMotion.premium,
                    curve: AppMotion.entranceCurve,
                    tween: Tween(begin: 0, end: d.pct.clamp(0.0, 1.0)),
                    builder: (_, v, _) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 8 + 62 * v,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                            const Color(0xFFEBDCBB), _gold, v),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_weekday(d.date),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _weekday(DateTime d) {
    const ar = ['اث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];
    return ar[(d.weekday - 1) % 7];
  }

  // ── headline: this week's % + delta vs last week + streak ───────────

  Widget _headline(LifeWeekSummary s, String lang) {
    final up = s.delta >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0x33D9A441)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(s.avgPercent * 100).round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: _gold)),
                Text(basicText('life_week_completion', lang),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 16,
                      color: up
                          ? const Color(0xFF2F7D5D)
                          : const Color(0xFFB5443F)),
                  const SizedBox(width: 4),
                  Text(
                    '${up ? '+' : ''}${(s.delta * 100).round()}%',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: up
                            ? const Color(0xFF2F7D5D)
                            : const Color(0xFFB5443F)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(basicText('life_week_vs_prev', lang),
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 9.5, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Text(
                '🔥 ${s.streak} · ✅ ${s.daysHitThreshold}/7',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── per-pillar row with a ▲/▼ vs the previous week ──────────────────

  Widget _pillarRow(LifePillarWeek p) {
    final up = p.delta >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: p.slipping ? const Color(0x55D9534F) : AppColors.divider),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(p.emoji.isEmpty ? '•' : p.emoji,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.label.replaceFirst(RegExp(r'^\S+\s+'), ''),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: p.now.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                        p.slipping ? const Color(0xFFB5443F) : _gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              size: 20,
              color: up
                  ? const Color(0xFF2F7D5D)
                  : const Color(0xFFB5443F)),
          Text('${(p.now * 100).round()}%',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted)),
        ],
      ),
    );
  }

  // ── strongest / needs-attention callouts ───────────────────────────

  Widget _callouts(LifeWeekSummary s, String lang) {
    final best = s.strongest;
    final weak = s.weakest;
    if (best == null || weak == null || best.key == weak.key) {
      return const SizedBox.shrink();
    }
    Widget cell(String head, LifePillarWeek p, Color tint) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: tint.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(head,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: tint)),
                const SizedBox(height: 4),
                Text('${p.emoji} ${p.label.replaceFirst(RegExp(r'^\S+\s+'), '')}',
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ],
            ),
          ),
        );
    // IntrinsicHeight so `stretch` has a bounded cross-axis to work against
    // (a bare stretch Row inside a ListView is given unbounded height).
    return IntrinsicHeight(
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cell(basicText('life_week_strongest', lang), best,
              const Color(0xFF2F7D5D)),
          cell(basicText('life_week_attention', lang), weak,
              const Color(0xFFB5443F)),
        ],
      ),
    );
  }

  Widget _emptyNotes(String lang) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(basicText('life_week_no_notes', lang),
            textDirection: TextDirection.rtl,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      );

  Widget _noteCard(LifeDayNote n) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(_pretty(n.date),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
                if (n.mood != null && n.mood! >= 1 && n.mood! <= 5) ...[
                  const SizedBox(width: 6),
                  Text(const ['😔', '😐', '🙂', '😊', '🤩'][n.mood! - 1]),
                ],
              ],
            ),
            if (n.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(n.note,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textDark, height: 1.5)),
            ],
            if (n.tomorrowGoal.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('→ ${n.tomorrowGoal}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF2F7D5D),
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );

  Widget _reflectButton(String lang) => SizedBox(
        height: 46,
        child: OutlinedButton.icon(
          onPressed: () async {
            final saved = await showLifeDayNoteSheet(context);
            if (saved && mounted) _load();
          },
          icon: const Icon(Icons.edit_note_rounded, size: 20),
          label: Text(basicText('life_note_open', lang),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2F5C46),
            side: const BorderSide(color: Color(0x552F5C46)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
      );
}
