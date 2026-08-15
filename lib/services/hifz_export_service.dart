import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/hifz_student.dart';

/// Builds an .xlsx roster/detail sheet for the Hifz teacher's students and
/// hands it off to the OS share sheet — a phone has no direct printer
/// connection, so "طباعة" here means: generate the file, then let the
/// teacher pick where it goes (a printing app, WhatsApp/Telegram to a
/// parent, Google Drive, etc.) via the native share dialog.
class HifzExportService {
  Future<void> exportStudent(HifzStudent student, List<HifzStudentField> fields) async {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet()!;
    final sheet = excel[sheetName];

    _addRow(sheet, 'الاسم', student.name);
    _addRow(sheet, 'رقم ولي الأمر', student.guardianPhone);
    _addRow(sheet, 'العمر', student.age?.toString() ?? '');
    _addRow(sheet, 'التقدم', student.progress);
    _addRow(sheet, 'التاريخ', student.dateAdded);
    for (final f in fields) {
      _addRow(sheet, f.label, f.value);
    }

    await _saveAndShare(excel, 'طالب_${_safe(student.name)}.xlsx');
  }

  Future<void> exportAll(List<HifzStudent> students, Map<int, List<HifzStudentField>> fieldsByStudent) async {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet()!;
    final sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue('الاسم'),
      TextCellValue('رقم ولي الأمر'),
      TextCellValue('العمر'),
      TextCellValue('التقدم'),
      TextCellValue('التاريخ'),
      TextCellValue('ملاحظات إضافية'),
    ]);

    for (final s in students) {
      final fields = fieldsByStudent[s.id] ?? [];
      final extra = fields.map((f) => '${f.label}: ${f.value}').join('؛ ');
      sheet.appendRow([
        TextCellValue(s.name),
        TextCellValue(s.guardianPhone),
        TextCellValue(s.age?.toString() ?? ''),
        TextCellValue(s.progress),
        TextCellValue(s.dateAdded),
        TextCellValue(extra),
      ]);
    }

    await _saveAndShare(excel, 'قائمة_الطلاب.xlsx');
  }

  void _addRow(Sheet sheet, String label, String value) {
    sheet.appendRow([TextCellValue(label), TextCellValue(value)]);
  }

  String _safe(String s) => s.replaceAll(RegExp(r'[^\w؀-ۿ]'), '_');

  Future<void> _saveAndShare(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: fileName);
  }
}
