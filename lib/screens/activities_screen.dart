import 'package:flutter/material.dart';

import '../models/activity_entry.dart';
import '../repositories/activity_repository.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import '../widgets/category_pill.dart';
import 'add_activity_screen.dart';
import '../widgets/loading_view.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _repo = ActivityRepository();
  List<ActivityEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await _repo.forMonth(currentMonth());
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _delete(ActivityEntry entry) async {
    await _repo.delete(entry.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('أنشطة ${monthLabel(currentMonth())}')),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : _entries.isEmpty
              ? const Center(child: Text('لا توجد أنشطة مسجلة هذا الشهر بعد', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) {
                    final e = _entries[i];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(18)),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(e),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(context,
                                MaterialPageRoute(builder: (_) => AddActivityScreen(existing: e)));
                            if (changed == true) _load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${e.date}${e.beneficiaries != null ? ' · مستفيدون: ${e.beneficiaries}' : ''}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CategoryPill(category: e.category),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => const AddActivityScreen()));
          if (added == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة نشاط'),
      ),
    );
  }
}
