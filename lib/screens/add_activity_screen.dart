import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/activity_entry.dart';
import '../repositories/activity_repository.dart';
import '../services/language_preference_service.dart';
import '../utils/hijri_date.dart';

class AddActivityScreen extends StatefulWidget {
  final ActivityEntry? existing;
  const AddActivityScreen({super.key, this.existing});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _repo = ActivityRepository();
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final _beneficiariesCtrl =
      TextEditingController(text: widget.existing?.beneficiaries?.toString() ?? '');
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  late ActivityCategory _category = widget.existing?.category ?? ActivityCategory.lesson;
  DateTime _pickedDate = DateTime.now();

  bool get _isEdit => widget.existing != null;

  String get _hijriDateLabel =>
      _pickedDateChanged ? hijriDateStringForDate(_pickedDate) : (widget.existing?.date ?? hijriDateStringForDate(_pickedDate));
  bool _pickedDateChanged = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
        _pickedDateChanged = true;
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(basicText('title_desc_required', LanguagePreferenceService.currentLanguage))));
      return;
    }
    final entry = ActivityEntry(
      id: widget.existing?.id,
      category: _category,
      date: _hijriDateLabel,
      title: _titleCtrl.text.trim(),
      beneficiaries: _category.hasBeneficiaries
          ? int.tryParse(_beneficiariesCtrl.text.trim())
          : null,
      notes: _notesCtrl.text.trim(),
    );
    if (_isEdit) {
      await _repo.update(entry);
    } else {
      await _repo.add(entry);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final lang = LanguagePreferenceService.currentLanguage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('delete_activity_title', lang)),
        content: Text(basicText('delete_activity_confirm', lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('cancel', lang))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('delete', lang))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.delete(widget.existing!.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _beneficiariesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        appBar: AppBar(
          title: Text(basicText(_isEdit ? 'edit_activity_title' : 'add_activity_title', lang)),
          actions: [
            if (_isEdit) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<ActivityCategory>(
              initialValue: _category,
              decoration: InputDecoration(labelText: basicText('activity_type_label', lang), border: const OutlineInputBorder()),
              items: ActivityCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${basicText('hijri_date_label_prefix', lang)}: $_hijriDateLabel'),
              subtitle: Text(basicText('date_picker_subtitle', lang), style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: basicText(_category == ActivityCategory.newMuslim ? 'name_details_label' : 'title_desc_label', lang),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            if (_category.hasBeneficiaries) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _beneficiariesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: basicText('beneficiaries_count_label', lang), border: const OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: basicText('notes_optional_label', lang), border: const OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEdit ? Icons.save : Icons.add),
              label: Text(basicText(_isEdit ? 'save_changes_action' : 'add', lang)),
            ),
          ],
        ),
      ),
    );
  }
}
