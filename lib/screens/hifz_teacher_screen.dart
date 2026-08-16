import 'package:flutter/material.dart';

import '../models/hifz_student.dart';
import '../repositories/hifz_student_repository.dart';
import '../services/hifz_export_service.dart';
import '../theme/app_theme.dart';
import '../utils/hijri_date.dart';
import 'hifz_student_detail_screen.dart';
import '../widgets/loading_view.dart';

/// "أستاذ التحفيظ" — a simple roster tool for a Quran-memorization teacher,
/// deliberately built with the exact same interaction pattern as
/// [GoalsScreen] per Ismail's own instruction: a flat list, swipe to
/// delete, a FAB to add, tap a row to open details. No halaqat/multi-teacher
/// management, no attendance/tajweed/grading subsystems — just a roster the
/// teacher can note things against, per-student, freely.
class HifzTeacherScreen extends StatefulWidget {
  const HifzTeacherScreen({super.key});

  @override
  State<HifzTeacherScreen> createState() => _HifzTeacherScreenState();
}

class _HifzTeacherScreenState extends State<HifzTeacherScreen> {
  final _repo = HifzStudentRepository();
  final _exportService = HifzExportService();
  final _searchController = TextEditingController();

  List<HifzStudent> _students = [];
  String _searchQuery = '';
  bool _loading = true;
  bool _exportingAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final students = await _repo.all();
    if (!mounted) return;
    setState(() {
      _students = students;
      _loading = false;
    });
  }

  List<HifzStudent> get _visibleStudents {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _students;
    return _students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _studentDialog({HifzStudent? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.guardianPhone ?? '');
    final ageCtrl = TextEditingController(text: existing?.age?.toString() ?? '');
    final progressCtrl = TextEditingController(text: existing?.progress ?? '');
    final isEdit = existing != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل بيانات الطالب' : 'طالب جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الطالب')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم ولي الأمر'),
                  keyboardType: TextInputType.phone),
              TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'عمر الطالب'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: progressCtrl,
                  decoration: const InputDecoration(labelText: 'التقدم (كم جزء / أين وصل في القاعدة)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(isEdit ? 'حفظ' : 'إضافة')),
        ],
      ),
    );
    if (result != true || nameCtrl.text.trim().isEmpty) return;

    final student = HifzStudent(
      id: existing?.id,
      name: nameCtrl.text.trim(),
      guardianPhone: phoneCtrl.text.trim(),
      age: int.tryParse(ageCtrl.text.trim()),
      progress: progressCtrl.text.trim(),
      dateAdded: existing?.dateAdded ?? hijriDateStringForDate(DateTime.now()),
    );
    if (isEdit) {
      await _repo.update(student);
    } else {
      await _repo.add(student);
    }
    _load();
  }

  Future<void> _deleteStudent(HifzStudent student) async {
    await _repo.delete(student.id!);
    _load();
  }

  Future<void> _exportAll() async {
    setState(() => _exportingAll = true);
    try {
      final fieldsByStudent = <int, List<dynamic>>{};
      for (final s in _students) {
        fieldsByStudent[s.id!] = await _repo.fieldsFor(s.id!);
      }
      await _exportService.exportAll(_students, fieldsByStudent.cast());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر التصدير: $e')));
    } finally {
      if (mounted) setState(() => _exportingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleStudents;
    return Scaffold(
      appBar: AppBar(
        title: const Text('أستاذ التحفيظ'),
        actions: [
          IconButton(
            icon: _exportingAll
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_rounded),
            tooltip: 'تصدير كل الطلاب (Excel)',
            onPressed: (_exportingAll || _students.isEmpty) ? null : _exportAll,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _studentDialog(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : _students.isEmpty
              ? const Center(child: Text('لا يوجد طلاب بعد — اضغط + لإضافة طالب'))
              : ListView(
                  padding: const EdgeInsets.only(top: 8),
                  children: [
                    if (_students.length > 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'ابحث باسم الطالب...',
                            prefixIcon: Icon(Icons.search_rounded, size: 20),
                          ),
                        ),
                      ),
                    ...visible.map((s) => Dismissible(
                          key: ValueKey(s.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration:
                                BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteStudent(s),
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              onTap: () async {
                                await Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => HifzStudentDetailScreen(student: s)));
                                _load();
                              },
                              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                s.progress.isEmpty ? 'لا يوجد تقدم مسجَّل بعد' : s.progress,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                              ),
                              trailing: const Icon(Icons.chevron_left_rounded),
                            ),
                          ),
                        )),
                  ],
                ),
    );
  }
}
