import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../services/medication_schedule.dart';
import '../services/user_data_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/restart_widget.dart';

/// «النسخة الاحتياطية» — save the person's own data (hifz, review, notes,
/// tasks, life engine, medicines, settings) to one file they keep anywhere
/// (Drive, WhatsApp to themselves, Files), and bring it back on a new phone.
/// The Quran, tafsir and books are not in the file — they come with the app.
/// A restore shows what the file holds and asks before replacing anything.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = UserDataExportService();
  DateTime? _lastExport;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    UserDataExportService.lastExportAt().then((d) {
      if (mounted) setState(() => _lastExport = d);
    });
  }

  String _when(DateTime d, String lang) => '${medDayLabel(d, lang)} ${medTimeOf(d)}${medDayLabel(d, lang).contains('/') ? '' : ' (${d.day}/${d.month}/${d.year})'}';

  Future<void> _export(String lang) async {
    setState(() => _busy = true);
    try {
      final json = await _service.exportToJson();
      final now = DateTime.now();
      final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final file = File('${(await getTemporaryDirectory()).path}/talib-alilm-backup-$stamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')], text: basicText('backup_share_text', lang));
      if (!mounted) return;
      setState(() => _lastExport = now);
    } catch (e) {
      if (mounted) _toast('${basicText('backup_export_failed', lang)} — $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(String lang) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    Map<String, Object?> data;
    String raw;
    try {
      raw = await File(path).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['format'] != UserDataExportService.formatId) throw const FormatException();
      data = decoded.cast<String, Object?>();
    } catch (_) {
      _toast(basicText('backup_err_file', lang));
      return;
    }
    if (!mounted) return;

    final s = UserDataExportService.summarize(data);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(basicText('backup_restore_q', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.exportedAt != null) Text('${basicText('backup_file_date', lang)}: ${_when(s.exportedAt!, lang)}'),
            const SizedBox(height: 8),
            Text(basicText('backup_file_holds', lang)
                .replaceAll('{memorized}', '${s.memorized}')
                .replaceAll('{notes}', '${s.notes}')
                .replaceAll('{tasks}', '${s.tasks}')
                .replaceAll('{meds}', '${s.medicines}')),
            const SizedBox(height: 12),
            Text(basicText('backup_restore_warn', lang), style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(basicText('cancel', lang))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(basicText('backup_restore_do', lang))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await _service.importFromMap(data);
      if (!mounted) return;
      if (!res.ok) {
        _toast(basicText(res.error == ImportError.newerApp ? 'backup_err_newer' : 'backup_err_file', lang));
        return;
      }
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          content: Text(basicText('backup_restore_ok', lang)),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                // A full restart re-reads every screen and re-queues every
                // reminder (prayer, adhkar, life engine, medicines) from the
                // restored data and language.
                RestartWidget.restartApp(context);
              },
              child: Text(basicText('backup_restart', lang)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _toast('${basicText('backup_err_file', lang)} — $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) {
        final stale = _lastExport == null || DateTime.now().difference(_lastExport!).inDays >= 30;
        return Scaffold(
          appBar: AppBar(title: Text(basicText('backup_title', lang))),
          body: AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(basicText('backup_desc', lang), style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: stale ? const Color(0xFFFFF1E0) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(stale ? Icons.warning_amber_rounded : Icons.verified_outlined, color: stale ? Colors.deepOrange : AppColors.primaryDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lastExport == null
                            ? basicText('backup_never', lang)
                            : '${basicText('backup_last', lang)}: ${_when(_lastExport!, lang)}${stale ? '\n${basicText('backup_stale', lang)}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _export(lang),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(basicText('backup_export_btn', lang)),
                ),
                const SizedBox(height: 6),
                Text(basicText('backup_export_hint', lang), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _import(lang),
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: Text(basicText('backup_import_btn', lang)),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(basicText('backup_note_content', lang), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
