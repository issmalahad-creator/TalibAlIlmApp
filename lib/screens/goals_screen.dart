import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../repositories/goal_repository.dart';
import '../utils/month.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _repo = GoalRepository();
  List<Goal> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final goals = await _repo.forMonth(currentMonth());
    if (!mounted) return;
    setState(() {
      _goals = goals;
      _loading = false;
    });
  }

  Future<void> _goalDialog({Goal? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final targetCtrl = TextEditingController(text: existing != null ? '${existing.target}' : '');
    final currentCtrl = TextEditingController(text: existing != null ? '${existing.current}' : '0');
    final isEdit = existing != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل الهدف' : 'هدف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الهدف')),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'الرقم المستهدف'),
            ),
            if (isEdit)
              TextField(
                controller: currentCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المُنجز حتى الآن'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(isEdit ? 'حفظ' : 'إضافة')),
        ],
      ),
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
      appBar: AppBar(title: Text('أهداف ${monthLabel(currentMonth())}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? const Center(child: Text('لا توجد أهداف بعد — اضغط + لإضافة هدف'))
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
