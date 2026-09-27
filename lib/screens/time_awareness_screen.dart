import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/time_awareness_content.dart';
import '../l10n/basic_translations.dart';
import '../repositories/time_awareness_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// "محاسبة الوقت" — Ismail's request 2026-08-16, extended 2026-08-16 same
/// day per his follow-up: structured, independent time entries (slept/
/// wasted/studied/worked) that the app computes benefit-vs-loss FROM,
/// instead of one self-rated summary slider. Sleep beyond a full night's
/// rest counts toward wasted time, and unaccounted hours default to
/// wasted too — both his explicit instructions (see
/// `DailyTimeEntry` in the repository for the exact reasoning). The app
/// still never infers or measures anything on its own — every number here
/// is exactly what the student typed in.
class TimeAwarenessScreen extends StatefulWidget {
  const TimeAwarenessScreen({super.key});

  @override
  State<TimeAwarenessScreen> createState() => _TimeAwarenessScreenState();
}

class _TimeAwarenessScreenState extends State<TimeAwarenessScreen> {
  final _repo = TimeAwarenessRepository();
  final _lang = LanguagePreferenceService.currentLanguage;
  final _sleptCtrl = TextEditingController();
  final _wastedCtrl = TextEditingController();
  final _studiedCtrl = TextEditingController();
  final _workedCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = true;
  List<(String, double?)> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
    for (final c in [_sleptCtrl, _wastedCtrl, _studiedCtrl, _workedCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _sleptCtrl.dispose();
    _wastedCtrl.dispose();
    _studiedCtrl.dispose();
    _workedCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  static String _fmt(double? v) => v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1));

  Future<void> _load() async {
    final entry = await _repo.todayEntry();
    final recent = await _repo.recentEntries();
    if (!mounted) return;
    _sleptCtrl.text = _fmt(entry.hoursSlept);
    _wastedCtrl.text = _fmt(entry.hoursWasted);
    _studiedCtrl.text = _fmt(entry.hoursStudied);
    _workedCtrl.text = _fmt(entry.hoursWorked);
    _noteCtrl.text = entry.note ?? '';
    setState(() {
      _recent = recent;
      _loading = false;
    });
  }

  DailyTimeEntry get _currentEntry => DailyTimeEntry(
        hoursSlept: double.tryParse(_sleptCtrl.text),
        hoursWasted: double.tryParse(_wastedCtrl.text),
        hoursStudied: double.tryParse(_studiedCtrl.text),
        hoursWorked: double.tryParse(_workedCtrl.text),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

  Future<void> _save() async {
    await _repo.saveToday(_currentEntry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(basicText('time_saved_confirmation', _lang))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysElapsed = _repo.daysElapsedThisHijriYear();
    final hoursElapsed = daysElapsed * 24;
    final hoursRemaining = TimeAwarenessRepository.hoursPerYear - hoursElapsed;
    final entry = _currentEntry;

    return Scaffold(
      appBar: AppBar(title: Text(basicText('time_accountability', _lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_progress', _lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(basicText('hijri_year_hours_label', _lang), style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${TimeAwarenessRepository.hoursPerYear}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text(
                        '${basicText('elapsed_approx_prefix', _lang)} $hoursElapsed ${basicText('hour_unit_label', _lang)} ${basicText('remaining_and_prefix', _lang)} $hoursRemaining ${basicText('hour_unit_label', _lang)}',
                        style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg), side: const BorderSide(color: AppColors.divider)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeAccountabilityHadith, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.9, color: AppColors.textDark)),
                        const SizedBox(height: 10),
                        Text(timeAccountabilityHadithSource, textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(basicText('today_your_day_label', _lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  basicText('time_honesty_desc', _lang),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _HoursField(label: basicText('how_much_slept', _lang), suffix: basicText('hour_unit_label', _lang), controller: _sleptCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _HoursField(label: basicText('how_much_wasted', _lang), suffix: basicText('hour_unit_label', _lang), controller: _wastedCtrl)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _HoursField(label: basicText('how_much_studied', _lang), suffix: basicText('hour_unit_label', _lang), controller: _studiedCtrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _HoursField(label: basicText('how_much_worked', _lang), suffix: basicText('hour_unit_label', _lang), controller: _workedCtrl)),
                  ],
                ),
                const SizedBox(height: 14),
                if (entry.hasAnyEntry)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${basicText('benefited_label', _lang)}: ${entry.benefitedHours.toStringAsFixed(1)} ${basicText('hour_unit_label', _lang)}  •  ${basicText('wasted_label', _lang)}: ${entry.wastedHours.toStringAsFixed(1)} ${basicText('hour_unit_label', _lang)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                        if (entry.unaccountedHours > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${basicText('of_which_prefix', _lang)} ${entry.unaccountedHours.toStringAsFixed(1)} ${basicText('unaccounted_hours_suffix', _lang)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ),
                        if (entry.excessSleepHours > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${basicText('of_which_prefix', _lang)} ${entry.excessSleepHours.toStringAsFixed(1)} ${basicText('excess_sleep_over_label', _lang)} ${DailyTimeEntry.sleepCapHours.toStringAsFixed(0)} ${basicText('hours_plural_label', _lang)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: basicText('time_note_hint', _lang), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: FilledButton(onPressed: _save, child: Text(basicText('save', _lang)))),
                const SizedBox(height: 24),
                Text(basicText('how_to_benefit_hours_title', _lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ...timeAwarenessTips.map((t) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.titleAr, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(t.bodyAr, style: const TextStyle(fontSize: 12.5, height: 1.6, color: AppColors.textMuted)),
                        ],
                      ),
                    )),
                if (_recent.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(basicText('recent_days_label', _lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._recent.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.$1, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text('${e.$2?.toStringAsFixed(1) ?? '-'} ${basicText('hour_unit_label', _lang)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
    );
  }
}

class _HoursField extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  const _HoursField({required this.label, required this.suffix, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder(), isDense: true),
    );
  }
}
