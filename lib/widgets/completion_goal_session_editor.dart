import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/completion_goal_session.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// Prayer anchor keys → their existing Arabic labels, kept identical to
/// `NotificationService.schedulePrayerTimeNotifications()`'s own names so a
/// session's anchor never reads differently from the rest of the app.
const Map<String, String> kPrayerAnchorLabels = {
  'fajr': 'الفجر',
  'sunrise': 'الشروق',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
};

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// §2.3 field 7أ — the wizard's "توزيع الورد على الصلوات" editor. Owns its
/// own session list (empty = no pattern chosen yet, meaning the goal keeps
/// the plain single-daily-target behaviour) and reports every change up via
/// [onChanged] so the wizard's own create button can persist it (or not, if
/// still empty) alongside the goal.
class CompletionGoalSessionEditor extends StatefulWidget {
  final int dailyTarget;
  final ValueChanged<List<CompletionGoalSession>> onChanged;
  const CompletionGoalSessionEditor({super.key, required this.dailyTarget, required this.onChanged});

  @override
  State<CompletionGoalSessionEditor> createState() => _CompletionGoalSessionEditorState();
}

class _CompletionGoalSessionEditorState extends State<CompletionGoalSessionEditor> {
  List<CompletionGoalSession> _sessions = const [];

  int get _distributed => _sessions.fold(0, (sum, s) => sum + s.units);

  void _apply(List<CompletionGoalSession> next) {
    setState(() => _sessions = next);
    widget.onChanged(next);
  }

  void _choosePattern(List<CompletionGoalSession> Function(int) pattern) => _apply(pattern(widget.dailyTarget));

  void _resetToDefault() => _apply(const []);

  /// §2.3.7أ — "تعديل أي جلسة يُعيد توزيع الفرق تلقائيًا على آخر جلسة في
  /// القائمة حتى يبقى المجموع مطابقًا لـ`daily_target` دائمًا". Never lets
  /// the absorbing session go negative.
  void _rebalanceAfterEdit(List<CompletionGoalSession> list, int editedIndex, int oldUnits, int newUnits) {
    final diff = newUnits - oldUnits;
    if (diff == 0 || list.length < 2) return;
    final lastIndex = list.length - 1;
    final absorber = editedIndex == lastIndex ? lastIndex - 1 : lastIndex;
    final absorbed = (list[absorber].units - diff).clamp(0, 1 << 30);
    list[absorber] = list[absorber].copyWith(units: absorbed);
  }

  Future<void> _editSession(int index) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final s = _sessions[index];
    final edited = await showModalBottomSheet<CompletionGoalSession>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CompletionGoalSessionEditSheet(session: s, lang: lang),
    );
    if (edited == null) return;
    final next = [..._sessions];
    next[index] = edited.copyWith(sortOrder: index);
    _rebalanceAfterEdit(next, index, s.units, edited.units);
    _apply(next);
  }

  void _deleteSession(int index) {
    if (_sessions.length <= 1) return;
    final removedUnits = _sessions[index].units;
    final next = [..._sessions]..removeAt(index);
    if (next.isNotEmpty) {
      next[next.length - 1] = next.last.copyWith(units: next.last.units + removedUnits);
    }
    _apply([for (var i = 0; i < next.length; i++) next[i].copyWith(sortOrder: i)]);
  }

  void _addSession() {
    final lang = LanguagePreferenceService.currentLanguage;
    final next = [
      ..._sessions,
      CompletionGoalSession(
        goalId: 0,
        sortOrder: _sessions.length,
        label: basicText('khatm_new_session_default_label', lang),
        anchorType: 'fixed',
        fixedHour: 12,
        fixedMinute: 0,
        units: 0,
      ),
    ];
    _apply(next);
  }

  String _anchorSummary(CompletionGoalSession s, String lang) {
    if (s.anchorType == 'prayer') {
      final name = kPrayerAnchorLabels[s.anchorPrayer] ?? s.anchorPrayer ?? '';
      if (s.offsetMinutes == 0) return name;
      final sign = s.offsetMinutes > 0 ? '+' : '';
      return '$name ($sign${s.offsetMinutes} ${basicText('minute_short_label', lang)})';
    }
    return '${_twoDigits(s.fixedHour ?? 0)}:${_twoDigits(s.fixedMinute ?? 0)}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    if (_sessions.isEmpty) {
      final showFocused = focusedPatternApplicable(widget.dailyTarget);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(basicText('khatm_session_pattern_prompt', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PatternCard(
                  title: basicText('khatm_pattern_equal_title', lang),
                  sessions: equalSessionPattern(widget.dailyTarget),
                  onTap: () => _choosePattern(equalSessionPattern),
                ),
              ),
              if (showFocused) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _PatternCard(
                    title: basicText('khatm_pattern_focused_title', lang),
                    sessions: focusedSessionPattern(widget.dailyTarget),
                    onTap: () => _choosePattern(focusedSessionPattern),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    final target = widget.dailyTarget < 1 ? 1 : widget.dailyTarget;
    final balanced = _distributed == target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _sessions.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text('${_sessions[i].label} — ${_anchorSummary(_sessions[i], lang)}',
                      style: const TextStyle(fontSize: 12.5)),
                ),
                Text('${_sessions[i].units}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _editSession(i),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.redAccent),
                  visualDensity: VisualDensity.compact,
                  onPressed: _sessions.length > 1 ? () => _deleteSession(i) : null,
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _addSession,
              icon: const Icon(Icons.add, size: 16),
              label: Text(basicText('khatm_add_session_action', lang), style: const TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: _resetToDefault,
              child: Text(basicText('khatm_reset_sessions_action', lang), style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        Text(
          '${basicText('khatm_distributed_label', lang)}: $_distributed ${basicText('khatm_of_label', lang)} $target',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: balanced ? AppColors.primary : Colors.redAccent),
        ),
      ],
    );
  }
}

class _PatternCard extends StatelessWidget {
  final String title;
  final List<CompletionGoalSession> sessions;
  final VoidCallback onTap;
  const _PatternCard({required this.title, required this.sessions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final s in sessions)
              Text('${s.label}: ${s.units}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

/// The session-list editor's own row-edit sheet (label/anchor/units) — also
/// reused, unmodified in its default look, by [CompletionGoalWerdList]
/// (§2.5) via [showReminderToggle]: a werd's timing is opt-in ("استطيع أن
/// أعطيه توقيت وتنبيه، أو أن يكون بلا توقيت أو تنبيه"), unlike a §2.3.7أ
/// session which always has one, so only the werd list ever passes `true`
/// here.
class CompletionGoalSessionEditSheet extends StatefulWidget {
  final CompletionGoalSession session;
  final String lang;
  final bool showReminderToggle;
  const CompletionGoalSessionEditSheet({super.key, required this.session, required this.lang, this.showReminderToggle = false});

  @override
  State<CompletionGoalSessionEditSheet> createState() => _CompletionGoalSessionEditSheetState();
}

class _CompletionGoalSessionEditSheetState extends State<CompletionGoalSessionEditSheet> {
  late String _anchorType;
  late String _prayer;
  late int _offset;
  late TimeOfDay _fixedTime;
  late int _units;
  late bool _reminderEnabled;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _anchorType = s.anchorType;
    _prayer = s.anchorPrayer ?? 'fajr';
    _offset = s.offsetMinutes;
    _fixedTime = TimeOfDay(hour: s.fixedHour ?? 12, minute: s.fixedMinute ?? 0);
    _units = s.units;
    _reminderEnabled = s.reminderEnabled;
    _labelController = TextEditingController(text: s.label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(basicText(widget.showReminderToggle ? 'khatm_edit_werd_title' : 'khatm_edit_session_title', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
                controller: _labelController,
                decoration: InputDecoration(labelText: basicText(widget.showReminderToggle ? 'khatm_werd_label_field' : 'khatm_session_label_field', lang))),
            const SizedBox(height: 16),
            if (widget.showReminderToggle)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(basicText('khatm_reminder_toggle_label', lang), style: const TextStyle(fontSize: 13)),
                value: _reminderEnabled,
                onChanged: (v) => setState(() => _reminderEnabled = v),
              ),
            if (!widget.showReminderToggle || _reminderEnabled) ...[
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'prayer', label: Text(basicText('khatm_anchor_prayer_option', lang), style: const TextStyle(fontSize: 11))),
                  ButtonSegment(value: 'fixed', label: Text(basicText('khatm_anchor_fixed_option', lang), style: const TextStyle(fontSize: 11))),
                ],
                selected: {_anchorType},
                onSelectionChanged: (v) => setState(() => _anchorType = v.first),
              ),
              const SizedBox(height: 12),
              if (_anchorType == 'prayer') ...[
                DropdownButton<String>(
                  isExpanded: true,
                  value: _prayer,
                  items: kPrayerAnchorLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() => _prayer = v ?? _prayer),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${basicText('khatm_offset_label', lang)}: $_offset ${basicText('minute_short_label', lang)}', style: const TextStyle(fontSize: 12.5)),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => setState(() => _offset -= 5)),
                        IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => setState(() => _offset += 5)),
                      ],
                    ),
                  ],
                ),
              ] else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, size: 20),
                  title: Text(basicText('khatm_reminder_time_label', lang), style: const TextStyle(fontSize: 13)),
                  trailing: Text(_fixedTime.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _fixedTime);
                    if (picked != null) setState(() => _fixedTime = picked);
                  },
                ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${basicText('khatm_session_units_label', lang)}: $_units', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _units = (_units - 1).clamp(0, 1 << 30))),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _units += 1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final result = widget.session.copyWith(
                  label: _labelController.text.trim().isEmpty ? widget.session.label : _labelController.text.trim(),
                  anchorType: _anchorType,
                  anchorPrayer: _anchorType == 'prayer' ? _prayer : null,
                  offsetMinutes: _anchorType == 'prayer' ? _offset : 0,
                  fixedHour: _anchorType == 'fixed' ? _fixedTime.hour : null,
                  fixedMinute: _anchorType == 'fixed' ? _fixedTime.minute : null,
                  units: _units,
                  reminderEnabled: widget.showReminderToggle ? _reminderEnabled : true,
                );
                Navigator.pop(context, result);
              },
              child: Text(basicText('save_action', lang)),
            ),
          ],
        ),
      ),
    );
  }
}
