import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/hifz_student.dart';
import '../repositories/hifz_student_repository.dart';
import '../services/hifz_export_service.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';
import '../utils/digits.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


/// One student's page — fixed info at the top, then a free-form list of
/// "خانات" (sub-fields) the teacher adds himself, specific to this student
/// only. Export button generates an Excel sheet for just this student.
class HifzStudentDetailScreen extends StatefulWidget {
  final HifzStudent student;
  const HifzStudentDetailScreen({super.key, required this.student});

  @override
  State<HifzStudentDetailScreen> createState() => _HifzStudentDetailScreenState();
}

class _HifzStudentDetailScreenState extends State<HifzStudentDetailScreen> {
  final _repo = HifzStudentRepository();
  final _exportService = HifzExportService();

  late HifzStudent _student;
  List<HifzStudentField> _fields = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _load();
  }

  Future<void> _load() async {
    final fields = await _repo.fieldsFor(_student.id!);
    if (!mounted) return;
    setState(() {
      _fields = fields;
      _loading = false;
    });
  }

  Future<void> _editStudentInfo() async {
    final nameCtrl = TextEditingController(text: _student.name);
    final phoneCtrl = TextEditingController(text: _student.guardianPhone);
    final ageCtrl = TextEditingController(text: _student.age?.toString() ?? '');
    final progressCtrl = TextEditingController(text: _student.progress);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('hz_edit_student')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: _t('hz_student_name'))),
              TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: _t('hz_guardian_phone')),
                  keyboardType: TextInputType.phone),
              TextField(controller: ageCtrl, decoration: InputDecoration(labelText: _t('hz_student_age')),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: progressCtrl,
                  decoration: InputDecoration(labelText: _t('hz_progress_field'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t('cancel_action'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_t('save_action'))),
        ],
      ),
    );
    if (result != true || nameCtrl.text.trim().isEmpty) return;

    final updated = HifzStudent(
      id: _student.id,
      name: nameCtrl.text.trim(),
      guardianPhone: phoneCtrl.text.trim(),
      age: parseAnyDigits(ageCtrl.text),
      progress: progressCtrl.text.trim(),
      dateAdded: _student.dateAdded,
    );
    await _repo.update(updated);
    if (!mounted) return;
    setState(() => _student = updated);
  }

  Future<void> _fieldDialog({HifzStudentField? existing}) async {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final valueCtrl = TextEditingController(text: existing?.value ?? '');
    final isEdit = existing != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? _t('hz_edit_field') : _t('hz_add_field')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: InputDecoration(labelText: _t('hz_field_title'))),
            TextField(controller: valueCtrl, decoration: InputDecoration(labelText: _t('hz_field_note')), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t('cancel_action'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(isEdit ? _t('save_action') : _t('add'))),
        ],
      ),
    );
    if (result != true || labelCtrl.text.trim().isEmpty) return;

    if (isEdit) {
      await _repo.updateField(HifzStudentField(
          id: existing.id, studentId: _student.id!, label: labelCtrl.text.trim(), value: valueCtrl.text.trim()));
    } else {
      await _repo.addField(
          HifzStudentField(studentId: _student.id!, label: labelCtrl.text.trim(), value: valueCtrl.text.trim()));
    }
    _load();
  }

  Future<void> _deleteField(HifzStudentField field) async {
    await _repo.deleteField(field.id!);
    _load();
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await _exportService.exportStudent(_student, _fields);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('hz_export_failed').replaceAll('{e}', '$e'))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_student.name),
        actions: [
          IconButton(
            icon: _exporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_rounded),
            tooltip: _t('hz_export_excel'),
            onPressed: _exporting ? null : _export,
          ),
          IconButton(icon: const Icon(Icons.edit_rounded), tooltip: _t('hz_edit_details'), onPressed: _editStudentInfo),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _fieldDialog(),
        icon: const Icon(Icons.add),
        label: Text(_t('hz_add_field')),
      ),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_quran', LanguagePreferenceService.currentLanguage))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(_t('hz_guardian_phone'), _student.guardianPhone),
                        _infoRow(_t('hz_age'), _student.age?.toString() ?? '—'),
                        _infoRow(_t('hz_progress'), _student.progress.isEmpty ? '—' : _student.progress),
                        _infoRow(_t('date_label'), _student.dateAdded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_t('hz_extra_fields'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_fields.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_t('hz_no_extra_fields').replaceAll('{add}', _t('hz_add_field')),
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                  )
                else
                  ..._fields.map((f) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(f.value),
                          onTap: () => _fieldDialog(existing: f),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                            onPressed: () => _deleteField(f),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
