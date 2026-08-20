import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../services/language_preference_service.dart';
import '../utils/month.dart';
import '../widgets/loading_view.dart';
import '../widgets/premium_modal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _repo = GoalRepository();
  final _lang = LanguagePreferenceService.currentLanguage;
  List<Goal> _goals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // 2026-08-17 (Ismail: goals screen not working even in Arabic, no
  // reliable repro found on review) — same defensive pattern already
  // shipped on `quran_browse_screen.dart`'s own "blank screen" bug: a
  // failure here previously left `_loading` stuck `true` forever with no
  // visible cause. Now any real failure surfaces as an actual message.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goals = await _repo.forMonth(currentMonth());
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _goalDialog({Goal? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final targetCtrl = TextEditingController(text: existing != null ? '${existing.target}' : '');
    final currentCtrl = TextEditingController(text: existing != null ? '${existing.current}' : '0');
    final isEdit = existing != null;

    final result = await showPremiumModal<bool>(
      context,
      title: basicText(isEdit ? 'edit_goal_title' : 'new_goal_title', _lang),
      icon: Icons.flag_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleCtrl, decoration: InputDecoration(labelText: basicText('goal_title_label', _lang))),
          TextField(
            controller: targetCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: basicText('goal_target_label', _lang)),
          ),
          if (isEdit)
            TextField(
              controller: currentCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: basicText('goal_current_label', _lang)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('cancel', _lang))),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText(isEdit ? 'save' : 'add', _lang))),
      ],
    );
    if (result != true || titleCtrl.text.trim().isEmpty) return;

    final target = int.tryParse(targetCtrl.text.trim()) ?? 1;
    if (isEdit) {
      final current = int.tryParse(currentCtrl.text.trim()) ?? existing.current;
      await _repo.update(existing.id!, title: titleCtrl.text.trim(), target: target, current: current);
    } else {
      await _repo.add(Goal(title: titleCtrl.text.trim(), target: target, month: currentMonth()));
    }
    _load();
  }

  Future<void> _incrementGoal(Goal goal) async {
    await _repo.updateProgress(goal.id!, (goal.current + 1).clamp(0, goal.target));
    _load();
  }

  Future<void> _deleteGoal(Goal goal) async {
    await _repo.delete(goal.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${basicText('nav_goals', _lang)} ${monthLabel(currentMonth())}')),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', _lang))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 32),
                        const SizedBox(height: 10),
                        Text('${basicText('load_failed_prefix', _lang)}:\n$_error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
                        const SizedBox(height: 14),
                        FilledButton(onPressed: _load, child: Text(basicText('retry_action', _lang))),
                      ],
                    ),
                  ),
                )
              : _goals.isEmpty
              ? Center(child: Text(basicText('no_goals_yet', _lang)))
              : ListView.builder(
                  itemCount: _goals.length,
                  itemBuilder: (context, i) {
                    final g = _goals[i];
                    return Dismissible(
                      key: ValueKey(g.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteGoal(g),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          onTap: () => _goalDialog(existing: g),
                          title: Text(g.title),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(value: g.progress),
                          ),
                          trailing: g.isComplete
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${g.current}/${g.target}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => _incrementGoal(g),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goalDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
