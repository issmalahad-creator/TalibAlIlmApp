import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/life_plan.dart';
import '../repositories/life_plan_repository.dart';
import '../services/language_preference_service.dart';

/// «مُحرّك الحياة» — L6-DYN #1 · in-app authoring of the plan
/// (`docs/LIFE_ENGINE.md` §7).
///
/// Two tabs — **المحاور** (pillars) and **الفترات** (time-blocks) — each a
/// drag-to-reorder list with add / edit / archive. Deletes are soft
/// (`archived`) so past progress keeps its meaning; a custom row that was
/// never used can be removed outright. An overflow menu reveals archived
/// rows and can restore Ismail's original seed.
///
/// Nothing here is bounded or sheet-dependent: it writes straight to the
/// local `life_pillars` / `life_slots` tables via [LifePlanRepository].
/// Open the slot editor sheet (add when [slot] is null) and return the
/// edited [LifeSlot], or null if dismissed. Shared by the full editor and
/// the inline "edit this block" on «اليوم» — so a quick tweak reacts with
/// the whole day, not a detour to a separate screen.
Future<LifeSlot?> showLifeSlotSheet(
  BuildContext context, {
  LifeSlot? slot,
  required List<LifePillar> pillars,
  required String lang,
}) {
  return showModalBottomSheet<LifeSlot>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SlotForm(
      slot: slot ??
          const LifeSlot(
              slotNo: 0, startMin: 8 * 60, endMin: 9 * 60, activity: ''),
      pillars: pillars,
      lang: lang,
    ),
  );
}

class LifePlanEditScreen extends StatefulWidget {
  const LifePlanEditScreen({super.key});

  @override
  State<LifePlanEditScreen> createState() => _LifePlanEditScreenState();
}

/// Muted accents for pillars — chosen to sit calmly on the cream surface,
/// value-separated so they read apart in a list. `null` = no accent.
const List<String> kLifePillarColors = [
  '#A63D2E', // clay red
  '#B5761F', // amber
  '#1F7A6B', // teal
  '#2E6F4E', // green
  '#25506E', // slate blue
  '#5B4E8C', // muted violet
  '#8A5A2B', // brown
  '#5B6570', // grey
];

class _LifePlanEditScreenState extends State<LifePlanEditScreen> {
  final _repo = LifePlanRepository();

  bool _loading = true;
  bool _showArchived = false;
  List<LifePillar> _pillars = const [];
  List<LifeSlot> _slots = const [];
  List<LifeTask> _tasks = const [];

  String get _lang => LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pillars = await _repo.pillars(includeArchived: true);
    final slots = await _repo.slots(includeArchived: true);
    final tasks = await _repo.tasks(includeArchived: true);
    if (!mounted) return;
    setState(() {
      _pillars = pillars;
      _slots = slots;
      _tasks = tasks;
      _loading = false;
    });
  }

  List<LifePillar> get _visiblePillars =>
      _pillars.where((p) => _showArchived || !p.archived).toList();
  List<LifeSlot> get _visibleSlots =>
      _slots.where((s) => _showArchived || !s.archived).toList();
  List<LifeTask> get _visibleTasks =>
      _tasks.where((t) => _showArchived || !t.archived).toList();
  List<LifePillar> get _activePillars =>
      _pillars.where((p) => !p.archived).toList();

  // ── pillars ──────────────────────────────────────────────────────────

  Future<void> _editPillar([LifePillar? existing]) async {
    final created = existing ??
        LifePillar(
          key: await _repo.newPillarKey(),
          label: '',
          sort: _pillars.length,
        );
    if (!mounted) return;
    final saved = await showModalBottomSheet<LifePillar>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PillarForm(pillar: created, lang: _lang),
    );
    if (saved == null) return;
    await _repo.upsertPillar(saved);
    await _load();
  }

  Future<void> _archivePillar(LifePillar p, bool archived) async {
    if (!archived && !p.archived) {
      // archiving: if it's a never-used custom pillar, offer a hard delete
      if (await _repo.canHardDeletePillar(p.key)) {
        await _repo.hardDeletePillar(p.key);
      } else {
        await _repo.setPillarArchived(p.key, true);
      }
    } else {
      await _repo.setPillarArchived(p.key, archived);
    }
    await _load();
  }

  Future<void> _reorderPillars(int oldIndex, int newIndex) async {
    final list = _visiblePillars;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() {}); // optimistic
    await _repo.reorderPillars(list.map((p) => p.key).toList());
    await _load();
  }

  // ── slots ────────────────────────────────────────────────────────────

  Future<void> _editSlot([LifeSlot? existing]) async {
    final saved = await showLifeSlotSheet(context,
        slot: existing, pillars: _activePillars, lang: _lang);
    if (saved == null) return;
    await _repo.upsertSlot(saved);
    await _load();
  }

  Future<void> _archiveSlot(LifeSlot s, bool archived) async {
    if (!archived && !s.archived) {
      if (await _repo.canHardDeleteSlot(s.slotNo)) {
        await _repo.hardDeleteSlot(s.slotNo);
      } else {
        await _repo.setSlotArchived(s.slotNo, true);
      }
    } else {
      await _repo.setSlotArchived(s.slotNo, archived);
    }
    await _load();
  }

  Future<void> _reorderSlots(int oldIndex, int newIndex) async {
    final list = _visibleSlots;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() {});
    await _repo.reorderSlots(list.map((s) => s.slotNo).toList());
    await _load();
  }

  // ── tasks (L6-DYN #3) ────────────────────────────────────────────────

  Future<void> _editTask([LifeTask? existing]) async {
    final base = existing ?? LifeTask(title: '', sort: _tasks.length);
    final saved = await showModalBottomSheet<LifeTask>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TaskForm(task: base, pillars: _activePillars, lang: _lang),
    );
    if (saved == null) return;
    await _repo.upsertTask(saved);
    await _load();
  }

  Future<void> _archiveTask(LifeTask t, bool archived) async {
    if (!archived && !t.archived) {
      if (await _repo.canHardDeleteTask(t.id)) {
        await _repo.hardDeleteTask(t.id);
      } else {
        await _repo.setTaskArchived(t.id, true);
      }
    } else {
      await _repo.setTaskArchived(t.id, archived);
    }
    await _load();
  }

  Future<void> _reorderTasks(int oldIndex, int newIndex) async {
    final list = _visibleTasks;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() {});
    await _repo.reorderTasks(list.map((t) => t.id).toList());
    await _load();
  }

  // ── seed reset ───────────────────────────────────────────────────────

  Future<void> _resetToSeed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(basicText('life_reset_plan', _lang)),
          content: Text(basicText('life_reset_plan_confirm', _lang)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(basicText('cancel', _lang)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(basicText('life_reset_plan_do', _lang)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _repo.resetStructureToSeed();
    await _load();
  }

  // ── build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFFBF6EE),
          appBar: AppBar(
            title: Text(basicText('life_edit_plan', lang)),
            bottom: TabBar(
              tabs: [
                Tab(text: basicText('life_tab_pillars', lang)),
                Tab(text: basicText('life_tab_slots', lang)),
                Tab(text: basicText('life_tab_tasks', lang)),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'archived') {
                    setState(() => _showArchived = !_showArchived);
                  } else if (v == 'reset') {
                    _resetToSeed();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'archived',
                    child: Text(_showArchived
                        ? basicText('life_hide_archived', lang)
                        : basicText('life_show_archived', lang)),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: Text(basicText('life_reset_plan', lang)),
                  ),
                ],
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _pillarsTab(lang),
                    _slotsTab(lang),
                    _tasksTab(lang),
                  ],
                ),
          floatingActionButton: Builder(
            builder: (ctx) => FloatingActionButton.extended(
              onPressed: () {
                switch (DefaultTabController.of(ctx).index) {
                  case 0:
                    _editPillar();
                  case 1:
                    _editSlot();
                  default:
                    _editTask();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(basicText('life_add', lang)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillarsTab(String lang) {
    final list = _visiblePillars;
    if (list.isEmpty) {
      return _empty(basicText('life_no_pillars', lang));
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: list.length,
      onReorderItem: _reorderPillars,
      itemBuilder: (_, i) {
        final p = list[i];
        return _EditRow(
          key: ValueKey('pillar_${p.key}'),
          leading: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _parseColor(p.color)?.withValues(alpha: 0.16) ??
                  const Color(0x11000000),
              shape: BoxShape.circle,
            ),
            child: Text(p.emoji.isEmpty ? '•' : p.emoji,
                style: const TextStyle(fontSize: 15)),
          ),
          title: p.label.isEmpty ? basicText('life_untitled', lang) : p.label,
          subtitle: [
            p.targetText,
            p.cadence == LifeCadence.weekly
                ? '${basicText('life_cadence_weekly', lang)} · ${p.weeklyTarget}'
                : basicText('life_cadence_daily', lang),
          ].where((s) => s.isNotEmpty).join('  ·  '),
          archived: p.archived,
          accent: _parseColor(p.color),
          onTap: () => _editPillar(p),
          onArchiveToggle: () => _archivePillar(p, !p.archived),
          restoreLabel: basicText('life_restore', lang),
          archiveLabel: basicText('life_archive', lang),
        );
      },
    );
  }

  Widget _slotsTab(String lang) {
    final list = _visibleSlots;
    if (list.isEmpty) {
      return _empty(basicText('life_no_slots', lang));
    }
    final pillarByKey = {for (final p in _pillars) p.key: p};
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: list.length,
      onReorderItem: _reorderSlots,
      itemBuilder: (_, i) {
        final s = list[i];
        final pillar = s.pillarKey == null ? null : pillarByKey[s.pillarKey];
        return _EditRow(
          key: ValueKey('slot_${s.slotNo}'),
          leading: SizedBox(
            width: 46,
            child: Text(
              s.timeLabel,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, height: 1.25),
            ),
          ),
          title:
              s.activity.isEmpty ? basicText('life_untitled', lang) : s.activity,
          subtitle: pillar != null
              ? '${pillar.emoji} ${pillar.label}'.trim()
              : (s.mihwar ?? basicText('life_no_pillar', lang)),
          archived: s.archived,
          accent: _parseColor(pillar?.color),
          onTap: () => _editSlot(s),
          onArchiveToggle: () => _archiveSlot(s, !s.archived),
          restoreLabel: basicText('life_restore', lang),
          archiveLabel: basicText('life_archive', lang),
        );
      },
    );
  }

  Widget _tasksTab(String lang) {
    final list = _visibleTasks;
    if (list.isEmpty) {
      return _empty(basicText('life_no_tasks', lang));
    }
    final pillarByKey = {for (final p in _pillars) p.key: p};
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: list.length,
      onReorderItem: _reorderTasks,
      itemBuilder: (_, i) {
        final t = list[i];
        final pillar = t.pillarKey == null ? null : pillarByKey[t.pillarKey];
        final kindLabel = t.isMilestone
            ? basicText('life_task_milestone', lang)
            : (t.isWeekly
                ? '${basicText('life_cadence_weekly', lang)} · ${t.weeklyTarget}'
                : basicText('life_cadence_daily', lang));
        return _EditRow(
          key: ValueKey('task_${t.id}'),
          leading: Icon(
            t.isMilestone ? Icons.flag_outlined : Icons.repeat_rounded,
            size: 20,
            color: Colors.black45,
          ),
          title: t.title.isEmpty ? basicText('life_untitled', lang) : t.title,
          subtitle: [
            kindLabel,
            if (pillar != null) '${pillar.emoji} ${pillar.label}'.trim(),
            if (t.milestoneDone) '✓',
          ].where((s) => s.isNotEmpty).join('  ·  '),
          archived: t.archived,
          accent: _parseColor(pillar?.color),
          onTap: () => _editTask(t),
          onArchiveToggle: () => _archiveTask(t, !t.archived),
          restoreLabel: basicText('life_restore', lang),
          archiveLabel: basicText('life_archive', lang),
        );
      },
    );
  }

  Widget _empty(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
        ),
      );
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  return Color(h.length <= 6 ? 0xFF000000 | v : v);
}

// ── a shared list row ──────────────────────────────────────────────────

class _EditRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool archived;
  final Color? accent;
  final VoidCallback onTap;
  final VoidCallback onArchiveToggle;
  final String restoreLabel;
  final String archiveLabel;

  const _EditRow({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.archived,
    required this.accent,
    required this.onTap,
    required this.onArchiveToggle,
    required this.restoreLabel,
    required this.archiveLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: archived ? 0.5 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: accent?.withValues(alpha: 0.35) ?? const Color(0x14000000),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: leading,
          title: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: archived ? TextDecoration.lineThrough : null,
              )),
          subtitle: subtitle.isEmpty
              ? null
              : Text(subtitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: archived ? restoreLabel : archiveLabel,
                icon: Icon(
                  archived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 20,
                ),
                onPressed: onArchiveToggle,
              ),
              const Icon(Icons.drag_indicator_rounded,
                  size: 20, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

// ── pillar form ───────────────────────────────────────────────────────

class _PillarForm extends StatefulWidget {
  final LifePillar pillar;
  final String lang;
  const _PillarForm({required this.pillar, required this.lang});

  @override
  State<_PillarForm> createState() => _PillarFormState();
}

class _PillarFormState extends State<_PillarForm> {
  late final TextEditingController _label =
      TextEditingController(text: widget.pillar.label);
  late final TextEditingController _emoji =
      TextEditingController(text: widget.pillar.emoji);
  late final TextEditingController _target =
      TextEditingController(text: widget.pillar.targetText);
  late LifeCadence _cadence = widget.pillar.cadence;
  late int _weeklyTarget = widget.pillar.weeklyTarget;
  late String? _color = widget.pillar.color;

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    _target.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      widget.pillar.copyWith(
        label: _label.text.trim(),
        emoji: _emoji.text.trim(),
        targetText: _target.text.trim(),
        cadence: _cadence,
        weeklyTarget: _cadence == LifeCadence.weekly
            ? (_weeklyTarget < 1 ? 1 : _weeklyTarget)
            : 0,
        color: _color,
        clearColor: _color == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return _SheetShell(
      title: widget.pillar.label.isEmpty
          ? basicText('life_add_pillar', lang)
          : basicText('life_edit_pillar', lang),
      onSave: _label.text.trim().isEmpty ? null : _save,
      saveLabel: basicText('save', lang),
      children: [
        TextField(
          controller: _label,
          autofocus: true,
          decoration: InputDecoration(
            labelText: basicText('life_field_name', lang),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emoji,
          maxLength: 2,
          decoration: InputDecoration(
            labelText: basicText('life_field_emoji', lang),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _target,
          decoration: InputDecoration(
            labelText: basicText('life_field_target', lang),
            hintText: basicText('life_field_target_hint', lang),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(basicText('life_field_cadence', lang),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        SegmentedButton<LifeCadence>(
          segments: [
            ButtonSegment(
              value: LifeCadence.daily,
              label: Text(basicText('life_cadence_daily', lang)),
            ),
            ButtonSegment(
              value: LifeCadence.weekly,
              label: Text(basicText('life_cadence_weekly', lang)),
            ),
          ],
          selected: {_cadence},
          onSelectionChanged: (s) => setState(() => _cadence = s.first),
        ),
        if (_cadence == LifeCadence.weekly) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(basicText('life_field_weekly_target', lang)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(
                    () => _weeklyTarget = (_weeklyTarget - 1).clamp(1, 99)),
              ),
              Text('${_weeklyTarget < 1 ? 1 : _weeklyTarget}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(
                    () => _weeklyTarget = (_weeklyTarget + 1).clamp(1, 99)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(basicText('life_field_color', lang),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ColorDot(
              color: null,
              selected: _color == null,
              onTap: () => setState(() => _color = null),
            ),
            for (final c in kLifePillarColors)
              _ColorDot(
                color: _parseColor(c),
                selected: _color == c,
                onTap: () => setState(() => _color = c),
              ),
          ],
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black87 : Colors.black26,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: color == null
            ? const Icon(Icons.block, size: 16, color: Colors.black38)
            : (selected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null),
      ),
    );
  }
}

// ── slot form ─────────────────────────────────────────────────────────

class _SlotForm extends StatefulWidget {
  final LifeSlot slot;
  final List<LifePillar> pillars;
  final String lang;
  const _SlotForm(
      {required this.slot, required this.pillars, required this.lang});

  @override
  State<_SlotForm> createState() => _SlotFormState();
}

class _SlotFormState extends State<_SlotForm> {
  late final TextEditingController _activity =
      TextEditingController(text: widget.slot.activity);
  late final TextEditingController _mihwar =
      TextEditingController(text: widget.slot.mihwar ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.slot.qtyUnit ?? '');
  late int _startMin = widget.slot.startMin;
  late int _endMin = widget.slot.endMin;
  late String? _pillarKey = widget.slot.pillarKey;
  late int _qtyTarget = widget.slot.qtyTarget;

  @override
  void dispose() {
    _activity.dispose();
    _mihwar.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final cur = start ? _startMin : _endMin;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: cur ~/ 60, minute: cur % 60),
    );
    if (t == null || !mounted) return;
    setState(() {
      final m = t.hour * 60 + t.minute;
      if (start) {
        _startMin = m;
        if (_endMin <= _startMin) _endMin = (_startMin + 30).clamp(0, 24 * 60);
      } else {
        _endMin = m;
        if (_endMin <= _startMin) _startMin = (_endMin - 30).clamp(0, 24 * 60);
      }
    });
  }

  String _hhmm(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  void _save() {
    final unit = _unit.text.trim();
    Navigator.pop(
      context,
      widget.slot.copyWith(
        startMin: _startMin,
        endMin: _endMin,
        activity: _activity.text.trim(),
        mihwar: _mihwar.text.trim().isEmpty ? null : _mihwar.text.trim(),
        pillarKey: _pillarKey,
        clearPillar: _pillarKey == null,
        qtyTarget: _qtyTarget,
        qtyUnit: _qtyTarget > 0 && unit.isNotEmpty ? unit : null,
        clearUnit: _qtyTarget == 0 || unit.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return _SheetShell(
      title: widget.slot.slotNo <= 0
          ? basicText('life_add_slot', lang)
          : basicText('life_edit_slot', lang),
      onSave: _activity.text.trim().isEmpty ? null : _save,
      saveLabel: basicText('save', lang),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(
                    '${basicText('life_field_start', lang)}  ${_hhmm(_startMin)}',
                    textDirection: TextDirection.ltr),
                onPressed: () => _pickTime(true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(
                    '${basicText('life_field_end', lang)}  ${_hhmm(_endMin)}',
                    textDirection: TextDirection.ltr),
                onPressed: () => _pickTime(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _activity,
          autofocus: true,
          decoration: InputDecoration(
            labelText: basicText('life_field_activity', lang),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: widget.pillars.any((p) => p.key == _pillarKey)
              ? _pillarKey
              : null,
          decoration: InputDecoration(
            labelText: basicText('life_field_pillar', lang),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(basicText('life_no_pillar', lang)),
            ),
            for (final p in widget.pillars)
              DropdownMenuItem<String?>(
                value: p.key,
                child: Text('${p.emoji} ${p.label}'.trim(),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _pillarKey = v),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _mihwar,
          decoration: InputDecoration(
            labelText: basicText('life_field_category', lang),
            hintText: basicText('life_field_category_hint', lang),
          ),
        ),
        const SizedBox(height: 16),
        _QtyTargetField(
          lang: lang,
          target: _qtyTarget,
          unitController: _unit,
          onTarget: (v) => setState(() => _qtyTarget = v),
        ),
      ],
    );
  }
}

/// The "هدف رقمي" control shared by the slot & task forms: a target
/// stepper (0 = off, tri-state tick) + a unit field once a target is set.
class _QtyTargetField extends StatelessWidget {
  final String lang;
  final int target;
  final TextEditingController unitController;
  final ValueChanged<int> onTarget;
  const _QtyTargetField({
    required this.lang,
    required this.target,
    required this.unitController,
    required this.onTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(basicText('life_field_qty_target', lang),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed:
                  target <= 0 ? null : () => onTarget((target - 1).clamp(0, 999)),
            ),
            Text(target == 0 ? basicText('life_qty_off', lang) : '$target',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onTarget((target + 1).clamp(0, 999)),
            ),
          ],
        ),
        if (target > 0)
          TextField(
            controller: unitController,
            decoration: InputDecoration(
              labelText: basicText('life_field_qty_unit', lang),
              hintText: basicText('life_field_qty_unit_hint', lang),
            ),
          ),
      ],
    );
  }
}

// ── task form ─────────────────────────────────────────────────────────

/// A recurring habit or a one-time milestone. `_kind` is one of three UI
/// choices — daily / weekly / milestone — mapped to `kind` + `recurrence`.
enum _TaskKindChoice { daily, weekly, milestone }

class _TaskForm extends StatefulWidget {
  final LifeTask task;
  final List<LifePillar> pillars;
  final String lang;
  const _TaskForm(
      {required this.task, required this.pillars, required this.lang});

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final TextEditingController _title =
      TextEditingController(text: widget.task.title);
  late final TextEditingController _unit =
      TextEditingController(text: widget.task.qtyUnit ?? '');
  late _TaskKindChoice _kind = widget.task.isMilestone
      ? _TaskKindChoice.milestone
      : (widget.task.isWeekly
          ? _TaskKindChoice.weekly
          : _TaskKindChoice.daily);
  late int _weeklyTarget =
      widget.task.weeklyTarget < 1 ? 3 : widget.task.weeklyTarget;
  late int _qtyTarget = widget.task.qtyTarget;
  late String? _pillarKey = widget.task.pillarKey;

  @override
  void dispose() {
    _title.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _save() {
    final kind = _kind == _TaskKindChoice.milestone
        ? LifeTaskKind.milestone
        : LifeTaskKind.recurring;
    final rec = _kind == _TaskKindChoice.weekly
        ? LifeCadence.weekly
        : LifeCadence.daily;
    final daily = _kind == _TaskKindChoice.daily;
    final unit = _unit.text.trim();
    Navigator.pop(
      context,
      widget.task.copyWith(
        title: _title.text.trim(),
        kind: kind,
        recurrence: rec,
        weeklyTarget: _kind == _TaskKindChoice.weekly
            ? (_weeklyTarget < 1 ? 1 : _weeklyTarget)
            : 0,
        qtyTarget: daily ? _qtyTarget : 0,
        qtyUnit: daily && _qtyTarget > 0 && unit.isNotEmpty ? unit : null,
        clearUnit: !daily || _qtyTarget == 0 || unit.isEmpty,
        pillarKey: _pillarKey,
        clearPillar: _pillarKey == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return _SheetShell(
      title: widget.task.id == 0
          ? basicText('life_add_task', lang)
          : basicText('life_edit_task', lang),
      onSave: _title.text.trim().isEmpty ? null : _save,
      saveLabel: basicText('save', lang),
      children: [
        TextField(
          controller: _title,
          autofocus: true,
          decoration: InputDecoration(
            labelText: basicText('life_field_task_title', lang),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(basicText('life_field_task_kind', lang),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        SegmentedButton<_TaskKindChoice>(
          segments: [
            ButtonSegment(
              value: _TaskKindChoice.daily,
              label: Text(basicText('life_cadence_daily', lang)),
            ),
            ButtonSegment(
              value: _TaskKindChoice.weekly,
              label: Text(basicText('life_cadence_weekly', lang)),
            ),
            ButtonSegment(
              value: _TaskKindChoice.milestone,
              label: Text(basicText('life_task_milestone', lang)),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() => _kind = s.first),
        ),
        if (_kind == _TaskKindChoice.weekly) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(basicText('life_field_weekly_target', lang)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(
                    () => _weeklyTarget = (_weeklyTarget - 1).clamp(1, 99)),
              ),
              Text('$_weeklyTarget',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(
                    () => _weeklyTarget = (_weeklyTarget + 1).clamp(1, 99)),
              ),
            ],
          ),
        ],
        if (_kind == _TaskKindChoice.daily) ...[
          const SizedBox(height: 16),
          _QtyTargetField(
            lang: lang,
            target: _qtyTarget,
            unitController: _unit,
            onTarget: (v) => setState(() => _qtyTarget = v),
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: widget.pillars.any((p) => p.key == _pillarKey)
              ? _pillarKey
              : null,
          decoration: InputDecoration(
            labelText: basicText('life_field_pillar', lang),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(basicText('life_no_pillar', lang)),
            ),
            for (final p in widget.pillars)
              DropdownMenuItem<String?>(
                value: p.key,
                child: Text('${p.emoji} ${p.label}'.trim(),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _pillarKey = v),
        ),
      ],
    );
  }
}

// ── shared bottom-sheet shell ─────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final String title;
  final VoidCallback? onSave;
  final String saveLabel;
  final List<Widget> children;
  const _SheetShell({
    required this.title,
    required this.onSave,
    required this.saveLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final safe = MediaQuery.of(context).viewPadding.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF6EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + insets + safe),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ...children,
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onSave,
                child: Text(saveLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
