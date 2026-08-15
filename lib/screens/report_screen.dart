import 'dart:async';

import 'package:flutter/material.dart';

import '../models/book_of_month.dart';
import '../models/report_draft.dart';
import '../repositories/report_draft_repository.dart';
import '../services/book_content_service.dart';
import '../services/notification_service.dart';
import '../services/report_builder.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _draftRepo = ReportDraftRepository();
  final _reportBuilder = ReportBuilder();
  final _bookContentService = BookContentService();
  final _syncService = SyncService();
  final _notificationService = NotificationService();

  final _booksReadCtrl = TextEditingController();
  final _currentLevelCtrl = TextEditingController();
  final _testsAndScoresCtrl = TextEditingController();
  final _topicsToReviewCtrl = TextEditingController();
  final _studyNotesCtrl = TextEditingController();

  Timer? _saveTimer;
  bool _loading = true;
  bool _submitting = false;
  bool _alreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final draft = await _draftRepo.get(currentMonth());
    final already = await _syncService.hasSubmittedForMonth(currentMonth());
    _booksReadCtrl.text = draft.booksRead;
    _currentLevelCtrl.text = draft.currentLevel;
    _testsAndScoresCtrl.text = draft.testsAndScores;
    _topicsToReviewCtrl.text = draft.topicsToReview;
    _studyNotesCtrl.text = draft.studyNotes;
    if (!mounted) return;
    setState(() {
      _alreadySubmitted = already;
      _loading = false;
    });
  }

  void _scheduleAutosave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _autosave);
  }

  Future<void> _autosave() async {
    await _draftRepo.save(ReportDraft(
      month: currentMonth(),
      booksRead: _booksReadCtrl.text,
      currentLevel: _currentLevelCtrl.text,
      testsAndScores: _testsAndScoresCtrl.text,
      topicsToReview: _topicsToReviewCtrl.text,
      studyNotes: _studyNotesCtrl.text,
    ));
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await _autosave();
    final feed = await _bookContentService.fetch();
    // Books accumulate now — the report references whichever is newest
    // (feed.books is newest-first) since that's "the current book".
    final latest = feed.books.isNotEmpty ? feed.books.first : null;
    final book = latest == null
        ? null
        : BookOfMonth(month: latest.id, title: latest.title, author: '', file: latest.url, quiz: latest.quiz);
    final report = await _reportBuilder.build(currentMonth(), book: book);
    await _syncService.submit(currentMonth(), report.payload, report.telegramText);
    if (!mounted) return;
    final sent = await _syncService.hasSubmittedForMonth(currentMonth());
    if (!mounted) return;
    if (sent) await _notificationService.cancelCurrentMonthReminder();
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _alreadySubmitted = sent;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(sent
          ? 'تم إرسال التقرير بنجاح ✅'
          : 'تم حفظ التقرير محلياً — سيُرسل تلقائياً عند توفر الإنترنت'),
    ));
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _booksReadCtrl.dispose();
    _currentLevelCtrl.dispose();
    _testsAndScoresCtrl.dispose();
    _topicsToReviewCtrl.dispose();
    _studyNotesCtrl.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController controller, {int minLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines + 4,
        onChanged: (_) => _scheduleAutosave(),
        decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تقرير ${monthLabel(currentMonth())}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                if (_alreadySubmitted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(child: Text('تم إرسال تقرير هذا الشهر بالفعل. يمكنك تعديل البيانات وإعادة الإرسال.')),
                    ]),
                  ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'هذا التقرير خاص بك — يُرسل فقط إلى حسابك أنت على تلغرام، ولا يُشارك مع أحد آخر.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                _field('الكتب التي قرأتها أو بدأت قراءتها هذا الشهر', _booksReadCtrl, minLines: 3),
                _field('المستوى أو المرحلة الدراسية الحالية', _currentLevelCtrl, minLines: 1),
                _field('الاختبارات التي خضعت لها ونتائجها هذا الشهر', _testsAndScoresCtrl, minLines: 2),
                _field('مواضيع أحتاج إلى مراجعتها', _topicsToReviewCtrl, minLines: 2),
                _field('ملاحظات عامة عن الدراسة هذا الشهر', _studyNotesCtrl, minLines: 3),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'جارٍ الإرسال...' : 'إرسال التقرير الشهري'),
                ),
                const SizedBox(height: 8),
                const Text('يُحفظ ما تكتبه تلقائياً أثناء الشهر — يمكنك العودة وإكماله لاحقاً.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted), textAlign: TextAlign.center),
              ],
            ),
    );
  }
}
