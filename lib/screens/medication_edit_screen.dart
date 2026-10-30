import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/medication.dart';
import '../repositories/medication_repository.dart';
import '../services/language_preference_service.dart';
import '../services/medication_schedule.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_permission_sheet.dart';

/// Add / edit one «علاجاتي» course: the name and dose from the
/// prescription, how it is spread (every N hours, or fixed clock times), for
/// how many days, from when — and a live preview of the calculated doses
/// before anything is saved. Pops `true` when saved.
class MedicationEditScreen extends StatefulWidget {
  final MedCourse? course;
  const MedicationEditScreen({super.key, this.course});

  @override
  State<MedicationEditScreen> createState() => _MedicationEditScreenState();
}

class _MedicationEditScreenState extends State<MedicationEditScreen> {
  final _repo = MedicationRepository();
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late MedScheduleMode _mode;
  late int _interval;
  late List<int> _times;
  late int _days;
  late DateTime _start;
  late bool _reminders;
  String? _presetId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _name = TextEditingController(text: c?.name ?? '');
    _dose = TextEditingController(text: c?.doseNote ?? '');
    _mode = c?.mode ?? MedScheduleMode.interval;
    _interval = c?.intervalHours ?? 8;
    _times = [...?c?.timesOfDay];
    if (_times.isEmpty) _times = [8 * 60, 20 * 60];
    _days = c?.durationDays ?? 7;
    final now = DateTime.now();
    _start = c?.startAt ?? DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _reminders = c?.remindersOn ?? true;
    if (c == null) _presetId = 'q8';
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  MedCourse get _draft => MedCourse(
        id: widget.course?.id,
        name: _name.text.trim(),
        doseNote: _dose.text.trim(),
        mode: _mode,
        intervalHours: _interval,
        timesOfDay: [..._times]..sort(),
        durationDays: _days,
        startAt: _start,
        remindersOn: _reminders,
      );

  void _applyPreset(MedPreset p) => setState(() {
        _presetId = p.id;
        _mode = p.mode;
        _interval = p.intervalHours;
        if (p.timesOfDay.isNotEmpty) _times = [...p.timesOfDay];
        _days = p.days;
      });

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _start = DateTime(d.year, d.month, d.day, _start.hour, _start.minute));
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t != null) setState(() => _start = DateTime(_start.year, _start.month, _start.day, t.hour, t.minute));
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
    if (t == null) return;
    final m = t.hour * 60 + t.minute;
    if (!_times.contains(m)) setState(() => _times = [..._times, m]..sort());
  }

  Future<void> _editTime(int i) async {
    final cur = _times[i];
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60));
    if (t == null) return;
    setState(() => _times = ([..._times]..[i] = t.hour * 60 + t.minute).toSet().toList()..sort());
  }

  Future<void> _save(String lang) async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(basicText('med_name_required', lang))));
      return;
    }
    if (_mode == MedScheduleMode.fixedTimes && _times.isEmpty) return;
    setState(() => _saving = true);
    await _repo.saveCourse(_draft);
    if (_reminders && mounted) await ensureExactAlarmsForMedication(context);
    await NotificationService().scheduleMedicationReminders();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final preview = buildMedicationDoses(_draft);
    final preset = kMedPresets.where((p) => p.id == _presetId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(basicText(widget.course == null ? 'med_add_title' : 'med_edit_title', lang))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: basicText('med_name_label', lang), hintText: basicText('med_name_hint', lang)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _dose,
            decoration: InputDecoration(labelText: basicText('med_dose_label', lang), hintText: basicText('med_dose_hint', lang)),
          ),
          const SizedBox(height: 20),
          _Label(basicText('med_presets_title', lang)),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final p in kMedPresets)
                ChoiceChip(label: Text(basicText(p.labelKey, lang)), selected: _presetId == p.id, onSelected: (_) => _applyPreset(p)),
            ],
          ),
          if (preset != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${basicText('med_example_word', lang)}: ${basicText(preset.exampleKey, lang)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 20),
          _Label(basicText('med_how_spread', lang)),
          SegmentedButton<MedScheduleMode>(
            segments: [
              ButtonSegment(value: MedScheduleMode.interval, icon: const Icon(Icons.timelapse_rounded), label: Text(basicText('med_mode_interval', lang))),
              ButtonSegment(value: MedScheduleMode.fixedTimes, icon: const Icon(Icons.schedule_rounded), label: Text(basicText('med_mode_times', lang))),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _presetId = null;
            }),
          ),
          const SizedBox(height: 12),
          if (_mode == MedScheduleMode.interval) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final h in const [4, 6, 8, 12, 24])
                  ChoiceChip(
                    label: Text(basicText('med_every_n_hours', lang).replaceAll('{n}', '$h')),
                    selected: _interval == h,
                    onSelected: (_) => setState(() {
                      _interval = h;
                      _presetId = null;
                    }),
                  ),
              ],
            ),
            _Stepper(
              label: basicText('med_interval_custom', lang),
              value: _interval,
              min: 1,
              max: 72,
              suffix: basicText('med_hours_unit', lang),
              onChanged: (v) => setState(() {
                _interval = v;
                _presetId = null;
              }),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (var i = 0; i < _times.length; i++)
                  InputChip(
                    label: Text(medHhmm(_times[i]), textDirection: TextDirection.ltr),
                    onPressed: () => _editTime(i),
                    onDeleted: _times.length > 1 ? () => setState(() => _times = [..._times]..removeAt(i)) : null,
                  ),
                ActionChip(avatar: const Icon(Icons.add, size: 18), label: Text(basicText('med_add_time', lang)), onPressed: _addTime),
              ],
            ),
            _Stepper(
              label: basicText('med_times_per_day', lang),
              value: _times.length,
              min: 1,
              max: 8,
              suffix: '',
              onChanged: (v) => setState(() {
                _times = spreadTimesOfDay(_times.isEmpty ? 8 * 60 : _times.first, v);
                _presetId = null;
              }),
            ),
            Text(basicText('med_times_spread_hint', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 16),
          _Stepper(
            label: basicText('med_days_label', lang),
            value: _days,
            min: 1,
            max: 365,
            suffix: basicText('med_days_unit', lang),
            onChanged: (v) => setState(() => _days = v),
          ),
          Wrap(spacing: 8, children: [
            for (final d in const [3, 5, 7, 10, 14, 30])
              ChoiceChip(label: Text('$d'), selected: _days == d, onSelected: (_) => setState(() => _days = d)),
          ]),
          const SizedBox(height: 16),
          _Label(basicText(_mode == MedScheduleMode.interval ? 'med_first_dose' : 'med_start_from', lang)),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _pickStartDate,
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(medDayLabel(_start, lang)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _pickStartTime,
                icon: const Icon(Icons.access_time_rounded, size: 18),
                label: Text(medHhmm(_start.hour * 60 + _start.minute), textDirection: TextDirection.ltr),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
            title: Text(basicText('med_reminders_on', lang)),
          ),
          const SizedBox(height: 8),
          _PreviewCard(course: _draft, doses: preview, lang: lang),
          const SizedBox(height: 12),
          Text(basicText('med_disclaimer', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving || preview.isEmpty ? null : () => _save(lang),
            icon: const Icon(Icons.alarm_add_rounded),
            label: Text(basicText('med_save', lang)),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final MedCourse course;
  final List<MedDose> doses;
  final String lang;
  const _PreviewCard({required this.course, required this.doses, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (doses.isEmpty) return const SizedBox.shrink();
    final formula = course.mode == MedScheduleMode.interval
        ? basicText('med_formula_interval', lang)
            .replaceAll('{days}', '${course.durationDays}')
            .replaceAll('{h}', '${course.intervalHours}')
            .replaceAll('{n}', '${doses.length}')
        : basicText('med_formula_times', lang)
            .replaceAll('{days}', '${course.durationDays}')
            .replaceAll('{t}', '${course.timesOfDay.length}')
            .replaceAll('{n}', '${doses.length}');
    final byDay = <DateTime, List<MedDose>>{};
    for (final d in doses) {
      (byDay[DateTime(d.scheduledAt.year, d.scheduledAt.month, d.scheduledAt.day)] ??= []).add(d);
    }
    final days = byDay.entries.toList();
    final shown = days.take(4).toList();
    return Card(
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Expanded(child: Text(basicText('med_preview_title', lang), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark))),
            ]),
            const SizedBox(height: 6),
            Text(formula, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              basicText('med_preview_range', lang)
                  .replaceAll('{from}', '${medDayLabel(doses.first.scheduledAt, lang)} ${medTimeOf(doses.first.scheduledAt)}')
                  .replaceAll('{to}', '${medDayLabel(doses.last.scheduledAt, lang)} ${medTimeOf(doses.last.scheduledAt)}'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const Divider(height: 18),
            for (final e in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 64, child: Text(medDayLabel(e.key, lang), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  Expanded(
                    child: Wrap(spacing: 6, runSpacing: 4, children: [
                      for (final d in e.value)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                          child: Text(medTimeOf(d.scheduledAt), textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 13)),
                        ),
                    ]),
                  ),
                ]),
              ),
            if (days.length > shown.length)
              Text(basicText('med_preview_more_days', lang).replaceAll('{n}', '${days.length - shown.length}'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.label, required this.value, required this.min, required this.max, required this.suffix, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label)),
          IconButton(onPressed: value > min ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
          SizedBox(width: 72, child: Text('$value $suffix'.trim(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(onPressed: value < max ? () => onChanged(value + 1) : null, icon: const Icon(Icons.add_circle_outline)),
        ]),
      );
}
