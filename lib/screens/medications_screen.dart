import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/medication.dart';
import '../repositories/medication_repository.dart';
import '../services/language_preference_service.dart';
import '../services/medication_schedule.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'medication_edit_screen.dart';

/// «علاجاتي» — medication courses with calculated reminder times: the next
/// dose with one-tap «أخذتها», today's doses across every course, and each
/// course's progress. Everything stays on the device.
class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final _repo = MedicationRepository();
  List<MedCourseWithDoses> _courses = const [];
  bool _loading = true;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    // The countdown and «حان وقتها» move with the clock.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final cs = await _repo.courses();
    if (!mounted) return;
    setState(() {
      _courses = cs;
      _loading = false;
    });
  }

  Future<void> _changed() async {
    await _load();
    await NotificationService().scheduleMedicationReminders();
  }

  Future<void> _add() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const MedicationEditScreen()));
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) {
        final now = DateTime.now();
        final active = _courses.where((c) => !c.finished).toList();
        final finished = _courses.where((c) => c.finished).toList();
        (MedCourse, MedDose)? next;
        for (final c in active) {
          final d = c.nextPending(now);
          if (d != null && (next == null || d.scheduledAt.isBefore(next.$2.scheduledAt))) next = (c.course, d);
        }
        final today = DateTime(now.year, now.month, now.day);
        final todayDoses = <(MedCourseWithDoses, MedDose)>[
          for (final c in _courses)
            for (final d in c.doses)
              if (!d.scheduledAt.isBefore(today) && d.scheduledAt.isBefore(today.add(const Duration(days: 1)))) (c, d),
        ]..sort((a, b) => a.$2.scheduledAt.compareTo(b.$2.scheduledAt));

        return Scaffold(
          appBar: AppBar(title: Text(basicText('med_title', lang))),
          floatingActionButton: _courses.isEmpty
              ? null
              : FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: Text(basicText('med_add', lang))),
          body: _loading
              ? const SizedBox.shrink()
              : _courses.isEmpty
                  ? _Empty(lang: lang, onAdd: _add)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        children: [
                          if (next != null) ...[
                            _NextDoseCard(course: next.$1, dose: next.$2, total: _courses.firstWhere((c) => c.course.id == next!.$1.id).total, lang: lang, onChanged: _changed),
                            const SizedBox(height: 16),
                          ],
                          if (todayDoses.isNotEmpty) ...[
                            _Section(basicText('med_today_doses', lang)),
                            Card(
                              child: Column(children: [
                                for (final (c, d) in todayDoses) _DoseTile(course: c, dose: d, lang: lang, showName: true, onChanged: _changed),
                              ]),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (active.isNotEmpty) _Section(basicText('med_active_courses', lang)),
                          for (final c in active) _CourseCard(c: c, lang: lang, onChanged: _changed),
                          if (finished.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: Text('${basicText('med_finished_courses', lang)} (${finished.length})'),
                              children: [for (final c in finished) _CourseCard(c: c, lang: lang, onChanged: _changed)],
                            ),
                          ],
                        ],
                      ),
                    ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  final String lang;
  final VoidCallback onAdd;
  const _Empty({required this.lang, required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.medication_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(basicText('med_empty_title', lang), style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(basicText('med_empty_body', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(basicText('med_add', lang))),
          ]),
        ),
      );
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// «بعد ساعتين و15 دقيقة» / «حان وقتها».
String medCountdown(DateTime at, String lang) {
  final diff = at.difference(DateTime.now());
  if (diff.inMinutes <= 0) return basicText('med_due_now', lang);
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  return basicText('med_in_hm', lang).replaceAll('{h}', '$h').replaceAll('{m}', '$m');
}

class _NextDoseCard extends StatelessWidget {
  final MedCourse course;
  final MedDose dose;
  final int total;
  final String lang;
  final Future<void> Function() onChanged;
  const _NextDoseCard({required this.course, required this.dose, required this.total, required this.lang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final due = !dose.scheduledAt.isAfter(DateTime.now());
    return Card(
      color: due ? const Color(0xFFFFF1E0) : AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(basicText('med_next_dose', lang), style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.medication_rounded, color: due ? Colors.deepOrange : AppColors.primaryDark, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(course.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                if (course.doseNote.isNotEmpty) Text(course.doseNote, style: const TextStyle(color: AppColors.textMuted)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(medTimeOf(dose.scheduledAt), textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text(medDayLabel(dose.scheduledAt, lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
          ]),
          const SizedBox(height: 8),
          Text(
            '${medCountdown(dose.scheduledAt, lang)} · ${basicText('med_dose_n_of_total', lang).replaceAll('{n}', '${dose.seq}').replaceAll('{total}', '$total')}',
            style: TextStyle(fontWeight: FontWeight.w600, color: due ? Colors.deepOrange : AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () async {
                  await MedicationRepository().setDoseStatus(dose.id!, MedDoseStatus.taken);
                  await onChanged();
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(basicText('med_took_it', lang)),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => showDoseActions(context, course, dose, lang, onChanged),
              child: Text(basicText('med_more', lang)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _DoseTile extends StatelessWidget {
  final MedCourseWithDoses course;
  final MedDose dose;
  final String lang;
  final bool showName;
  final Future<void> Function() onChanged;
  const _DoseTile({required this.course, required this.dose, required this.lang, required this.onChanged, this.showName = false});

  @override
  Widget build(BuildContext context) {
    final late = dose.isPending && dose.scheduledAt.isBefore(DateTime.now());
    final (icon, color) = switch (dose.status) {
      MedDoseStatus.taken => (Icons.check_circle_rounded, AppColors.primary),
      MedDoseStatus.skipped => (Icons.remove_circle_outline_rounded, AppColors.textMuted),
      MedDoseStatus.pending => late ? (Icons.error_outline_rounded, Colors.deepOrange) : (Icons.radio_button_unchecked_rounded, AppColors.textMuted),
    };
    final n = basicText('med_dose_n_of_total', lang).replaceAll('{n}', '${dose.seq}').replaceAll('{total}', '${course.total}');
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(showName ? course.course.name : n, style: TextStyle(fontWeight: FontWeight.w600, decoration: dose.status == MedDoseStatus.skipped ? TextDecoration.lineThrough : null)),
      subtitle: Text(showName ? n : (dose.takenAt != null ? '${basicText('med_taken_at', lang)} ${medTimeOf(dose.takenAt!)}' : (late ? basicText('med_late', lang) : ''))),
      trailing: Text(medTimeOf(dose.scheduledAt), textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      onTap: () => showDoseActions(context, course.course, dose, lang, onChanged),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final MedCourseWithDoses c;
  final String lang;
  final Future<void> Function() onChanged;
  const _CourseCard({required this.c, required this.lang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final schedule = c.course.mode == MedScheduleMode.interval
        ? basicText('med_every_n_hours', lang).replaceAll('{n}', '${c.course.intervalHours}')
        : c.course.timesOfDay.map((t) => medTimeOf(DateTime(2000, 1, 1, t ~/ 60, t % 60))).join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => MedicationCourseScreen(courseId: c.course.id!)));
          await onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.medication_liquid_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(c.course.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              if (!c.course.remindersOn) const Icon(Icons.notifications_off_outlined, size: 18, color: AppColors.textMuted),
            ]),
            const SizedBox(height: 4),
            Text('$schedule · ${c.course.durationDays} ${basicText('med_days_unit', lang)}${c.course.doseNote.isEmpty ? '' : ' · ${c.course.doseNote}'}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: c.total == 0 ? 0 : c.done / c.total, minHeight: 8, backgroundColor: AppColors.divider),
            ),
            const SizedBox(height: 6),
            Text(
              basicText('med_progress', lang)
                  .replaceAll('{taken}', '${c.taken}')
                  .replaceAll('{total}', '${c.total}')
                  .replaceAll('{end}', c.endsAt == null ? '' : '${medDayLabel(c.endsAt!, lang)} ${medTimeOf(c.endsAt!)}'),
              style: const TextStyle(fontSize: 12.5),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Taken / skipped / back to pending / move this dose (optionally every
/// later dose too, keeping the gaps).
Future<void> showDoseActions(BuildContext context, MedCourse course, MedDose dose, String lang, Future<void> Function() onChanged) async {
  final repo = MedicationRepository();
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${medDayLabel(dose.scheduledAt, lang)} ${medTimeOf(dose.scheduledAt)}'),
        ),
        const Divider(height: 1),
        if (dose.status != MedDoseStatus.taken)
          ListTile(leading: const Icon(Icons.check_circle_outline, color: AppColors.primary), title: Text(basicText('med_took_it', lang)), onTap: () => Navigator.pop(ctx, 'taken')),
        if (dose.status != MedDoseStatus.skipped)
          ListTile(leading: const Icon(Icons.remove_circle_outline), title: Text(basicText('med_skip', lang)), onTap: () => Navigator.pop(ctx, 'skip')),
        if (!dose.isPending)
          ListTile(leading: const Icon(Icons.undo_rounded), title: Text(basicText('med_undo', lang)), onTap: () => Navigator.pop(ctx, 'undo')),
        if (dose.isPending) ...[
          ListTile(leading: const Icon(Icons.edit_calendar_outlined), title: Text(basicText('med_move_one', lang)), onTap: () => Navigator.pop(ctx, 'move')),
          ListTile(
            leading: const Icon(Icons.update_rounded),
            title: Text(basicText('med_move_all', lang)),
            subtitle: Text(basicText('med_move_all_hint', lang)),
            onTap: () => Navigator.pop(ctx, 'shift'),
          ),
        ],
      ]),
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case 'taken':
      await repo.setDoseStatus(dose.id!, MedDoseStatus.taken);
    case 'skip':
      await repo.setDoseStatus(dose.id!, MedDoseStatus.skipped);
    case 'undo':
      await repo.setDoseStatus(dose.id!, MedDoseStatus.pending);
    case 'move' || 'shift':
      final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(dose.scheduledAt));
      if (t == null) return;
      final s = dose.scheduledAt;
      var to = DateTime(s.year, s.month, s.day, t.hour, t.minute);
      // Moving 23:00 → 01:00 means the next night, not 22 hours earlier.
      if (to.difference(s).inHours < -12) to = to.add(const Duration(days: 1));
      await repo.moveDose(dose, to, shiftFollowing: action == 'shift');
  }
  await onChanged();
}

/// One course: every dose by day, edit and delete.
class MedicationCourseScreen extends StatefulWidget {
  final int courseId;
  const MedicationCourseScreen({super.key, required this.courseId});

  @override
  State<MedicationCourseScreen> createState() => _MedicationCourseScreenState();
}

class _MedicationCourseScreenState extends State<MedicationCourseScreen> {
  final _repo = MedicationRepository();
  MedCourseWithDoses? _c;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await _repo.course(widget.courseId);
    if (!mounted) return;
    if (c == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _c = c);
  }

  Future<void> _changed() async {
    await _load();
    await NotificationService().scheduleMedicationReminders();
  }

  Future<void> _delete(String lang) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(basicText('med_delete_q', lang)),
        content: Text(_c!.course.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(basicText('cancel', lang))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(basicText('med_delete', lang))),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.deleteCourse(widget.courseId);
    await NotificationService().scheduleMedicationReminders();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final c = _c;
    final byDay = <DateTime, List<MedDose>>{};
    for (final d in c?.doses ?? const <MedDose>[]) {
      (byDay[DateTime(d.scheduledAt.year, d.scheduledAt.month, d.scheduledAt.day)] ??= []).add(d);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.course.name ?? ''),
        actions: c == null
            ? null
            : [
                IconButton(
                  tooltip: basicText('med_edit_title', lang),
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => MedicationEditScreen(course: c.course)));
                    if (saved == true) _load();
                  },
                ),
                IconButton(tooltip: basicText('med_delete', lang), icon: const Icon(Icons.delete_outline), onPressed: () => _delete(lang)),
              ],
      ),
      body: c == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                SwitchListTile(
                  value: c.course.remindersOn,
                  title: Text(basicText('med_reminders_on', lang)),
                  onChanged: (v) async {
                    await _repo.setRemindersOn(c.course.id!, v);
                    await _changed();
                  },
                ),
                for (final e in byDay.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                    child: Text('${medDayLabel(e.key, lang)} — ${e.key.day}/${e.key.month}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Card(child: Column(children: [for (final d in e.value) _DoseTile(course: c, dose: d, lang: lang, onChanged: _changed)])),
                ],
              ],
            ),
    );
  }
}
