import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/basic_translations.dart';
import '../models/life_plan.dart';
import '../repositories/life_plan_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// «مُحرّك الحياة» — L5 · the 90-day cycle-rollover ritual
/// (`docs/LIFE_ENGINE.md` §0). A cycle completing is a milestone, never an
/// end: look back at the 90 days, write one reflection, and step into the
/// next cycle with the streak intact. Shown once per cycle, when
/// `LifePlanRepository.pendingCycleReview()` returns its number.
class LifeCycleReviewScreen extends StatefulWidget {
  final int cycle; // the cycle that just completed (1-based)
  const LifeCycleReviewScreen({super.key, required this.cycle});

  @override
  State<LifeCycleReviewScreen> createState() => _LifeCycleReviewScreenState();
}

class _LifeCycleReviewScreenState extends State<LifeCycleReviewScreen> {
  final _repo = LifePlanRepository();
  final _reflect = TextEditingController();

  LifeCycleSummary? _sum;
  List<LifePillar> _pillars = const [];
  bool _loading = true;
  bool _finishing = false;

  static const _gold = Color(0xFFD9A441);
  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reflect.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await _repo.cycleSummary(widget.cycle);
    final ps = await _repo.pillars();
    final prev = await _repo.cycleNote(widget.cycle);
    if (!mounted) return;
    setState(() {
      _sum = s;
      _pillars = ps;
      _reflect.text = prev ?? '';
      _loading = false;
    });
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    if (_reflect.text.trim().isNotEmpty) {
      await _repo.saveCycleNote(widget.cycle, _reflect.text.trim());
    }
    await _repo.markCycleReviewed(widget.cycle);
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _label(String key) {
    final p = _pillars.where((e) => e.key == key);
    if (p.isEmpty) return key;
    return p.first.label;
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final s = _sum;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(basicText('life_cycle_title', lang),
            textDirection: TextDirection.rtl),
      ),
      body: _loading || s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                  18, 18, 18, 28 + MediaQuery.of(context).viewPadding.bottom),
              children: [
                _celebration(s, lang),
                const SizedBox(height: 18),
                _statsRow(s, lang),
                const SizedBox(height: 14),
                if (s.byPillarDone.isNotEmpty) ...[
                  _sectionTitle(basicText('life_cycle_top_pillars', lang)),
                  const SizedBox(height: 8),
                  ..._topPillars(s),
                  const SizedBox(height: 16),
                ],
                _messageCard(lang),
                const SizedBox(height: 16),
                _sectionTitle(basicText('life_cycle_reflect_label', lang)),
                const SizedBox(height: 6),
                TextField(
                  controller: _reflect,
                  maxLines: 4,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                  decoration: InputDecoration(
                    hintText: basicText('life_cycle_reflect_hint', lang),
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: _gold, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _finishing ? null : _finish,
                    style: FilledButton.styleFrom(
                      backgroundColor: _gold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: _finishing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            '${basicText('life_cycle_start_next', lang)} ${widget.cycle + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontSize: 15)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13));

  Widget _celebration(LifeCycleSummary s, String lang) {
    return TweenAnimationBuilder<double>(
      duration: AppMotion.premium,
      curve: AppMotion.entranceCurve,
      tween: Tween(begin: 0.7, end: 1),
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            colors: [Color(0xFFF4E6C4), Color(0xFFE9CE8C)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 8),
            Text(
              '${basicText('life_cycle_done', lang)} ${s.cycle}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF5A431A)),
            ),
            const SizedBox(height: 2),
            Text(
              '${s.lengthDays} ${basicText('life_cycle_days_word', lang)}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF7A5E2C)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(LifeCycleSummary s, String lang) {
    Widget cell(String v, String label) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Text(v,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: _gold)),
                const SizedBox(height: 2),
                Text(label,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        );
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        cell('${(s.avgPercent * 100).round()}%',
            basicText('life_cycle_avg', lang)),
        cell('${s.blocksDone}', basicText('life_cycle_blocks', lang)),
      ],
    );
  }

  List<Widget> _topPillars(LifeCycleSummary s) {
    final entries = s.byPillarDone.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.first.value.toDouble();
    return [
      for (final e in entries.take(3))
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(_label(e.key),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0 : e.value / max,
                    minHeight: 5,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(_gold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${e.value}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted)),
            ],
          ),
        ),
    ];
  }

  Widget _messageCard(String lang) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF5F1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: const Color(0x332F5C46)),
        ),
        child: Text(
          basicText('life_cycle_message', lang),
          textDirection: TextDirection.rtl,
          style: const TextStyle(
              fontSize: 12.5, height: 1.7, color: Color(0xFF2F5C46)),
        ),
      );
}
