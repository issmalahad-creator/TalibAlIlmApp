import 'package:flutter/material.dart';

import '../models/activity_entry.dart';
import '../repositories/activity_repository.dart';
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('يرجى إدخال العنوان/الوصف')));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النشاط'),
        content: const Text('هل تريد حذف هذا النشاط؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل نشاط' : 'إضافة نشاط'),
        actions: [
          if (_isEdit) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<ActivityCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'نوع النشاط', border: OutlineInputBorder()),
            items: ActivityCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('التاريخ الهجري: $_hijriDateLabel'),
            subtitle: const Text('اضغط لاختيار تاريخ آخر (يظهر التقويم الميلادي للاختيار فقط)',
                style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: _category == ActivityCategory.newMuslim ? 'اسم/تفاصيل' : 'العنوان / الوصف',
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          if (_category.hasBeneficiaries) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _beneficiariesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد المستفيدين (تقريبي)', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: Icon(_isEdit ? Icons.save : Icons.add),
            label: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة'),
          ),
        ],
      ),
    );
  }
}
