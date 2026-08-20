import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../models/reading_record.dart';
import '../repositories/book_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import '../widgets/loading_view.dart';

const _reflectionPrompts = [
  'ما الفكرة التي لفتت انتباهك في هذه الصفحات؟',
  'كيف يمكن أن تطبّق هذا في حياتك اليوم؟',
  'ما سؤال بقي عندك تريد البحث عنه لاحقًا؟',
  'ما عبارة أو موقف أثّر فيك؟',
];

const _applicationPrompts = [
  'ما الخُلق الذي طبّقته اليوم من هذا الكتاب؟',
  'موقف حصل لك اليوم وتذكّرت فيه شيئًا من الكتاب',
  'خُلق تريد أن تبدأ بتطبيقه غدًا',
];

class BookViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  /// Stable identifier for this book's reading progress — pass the book's
  /// content URL (or asset path for the legacy monthly book) so the
  /// bookmark survives across sessions per-book, not just per-app.
  final String bookKey;

  const BookViewerScreen({super.key, required this.filePath, required this.title, required this.bookKey});

  @override
  State<BookViewerScreen> createState() => _BookViewerScreenState();
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  final _bookRepo = BookRepository();
  final _notificationService = NotificationService();
  final _noteCtrl = TextEditingController();
  final _applicationCtrl = TextEditingController();
  int _defaultPage = 0;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
    // Any book counts as "still reading" — pushes the inactivity reminder
    // forward regardless of which book/library it came from.
    _notificationService.scheduleReadingReminder();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _applicationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookmark() async {
    final bookmark = await _bookRepo.getBookmark(widget.bookKey);
    if (!mounted) return;
    setState(() {
      _defaultPage = bookmark?.lastPage ?? 0;
      _currentPage = _defaultPage;
      _totalPages = bookmark?.totalPages ?? 0;
      _ready = true;
    });
  }

  Future<void> _saveBookmark(int page, int total) async {
    await _bookRepo.saveBookmark(
      BookBookmark(bookKey: widget.bookKey, lastPage: page, totalPages: total, lastUpdatedDate: todayDate()),
    );
  }

  /// "دفتر الفوائد" + "سجل التطبيق" for this book — Ismail's 2026-08-16
  /// request, explicitly "نفس المكتبة الصوتية" (same as the audio
  /// library's existing reflection log). Presented as a bottom sheet rather
  /// than inline below the reader (unlike the audio screen) since `PDFView`
  /// needs the full screen for actual reading.
  Future<void> _openNotebook() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _BookNotebookSheet(
        bookRepo: _bookRepo,
        bookKey: widget.bookKey,
        currentPage: _currentPage + 1,
        noteCtrl: _noteCtrl,
        applicationCtrl: _applicationCtrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'دفتر الفوائد وسجل التطبيق',
            onPressed: _openNotebook,
          ),
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('${_currentPage + 1} / $_totalPages')),
            ),
        ],
      ),
      body: !_ready
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : PDFView(
              filePath: widget.filePath,
              defaultPage: _defaultPage,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) {
                if (pages == null) return;
                setState(() => _totalPages = pages);
                _saveBookmark(_currentPage, pages);
              },
              onPageChanged: (page, total) {
                if (page == null) return;
                setState(() {
                  _currentPage = page;
                  if (total != null) _totalPages = total;
                });
                _saveBookmark(page, _totalPages);
              },
            ),
    );
  }
}

class _BookNotebookSheet extends StatefulWidget {
  final BookRepository bookRepo;
  final String bookKey;
  final int currentPage;
  final TextEditingController noteCtrl;
  final TextEditingController applicationCtrl;

  const _BookNotebookSheet({
    required this.bookRepo,
    required this.bookKey,
    required this.currentPage,
    required this.noteCtrl,
    required this.applicationCtrl,
  });

  @override
  State<_BookNotebookSheet> createState() => _BookNotebookSheetState();
}

class _BookNotebookSheetState extends State<_BookNotebookSheet> {
  List<BookReflection> _reflections = [];
  List<BookApplicationEntry> _applications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reflections = await widget.bookRepo.reflectionsFor(widget.bookKey);
    final applications = await widget.bookRepo.applicationsFor(widget.bookKey);
    if (!mounted) return;
    setState(() {
      _reflections = reflections;
      _applications = applications;
      _loading = false;
    });
  }

  Future<void> _saveReflection() async {
    final text = widget.noteCtrl.text.trim();
    if (text.isEmpty) return;
    await widget.bookRepo.addReflection(widget.bookKey, text, page: widget.currentPage);
    widget.noteCtrl.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ ملاحظتك')));
  }

  Future<void> _editReflection(BookReflection r) async {
    final textCtrl = TextEditingController(text: r.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملاحظة'),
        content: TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (saved != true) return;
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;
    await widget.bookRepo.updateReflection(r.id, text);
    await _load();
  }

  Future<void> _deleteReflection(BookReflection r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الملاحظة؟'),
        content: const Text('لا يمكن التراجع عن هذا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('مسح')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.bookRepo.deleteReflection(r.id);
    await _load();
  }

  Future<void> _saveApplication() async {
    final text = widget.applicationCtrl.text.trim();
    if (text.isEmpty) return;
    await widget.bookRepo.addApplication(widget.bookKey, text);
    widget.applicationCtrl.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ سجل التطبيق')));
  }

  Future<void> _editApplication(BookApplicationEntry a) async {
    final textCtrl = TextEditingController(text: a.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل التطبيق'),
        content: TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (saved != true) return;
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;
    await widget.bookRepo.updateApplication(a.id, text);
    await _load();
  }

  Future<void> _deleteApplication(BookApplicationEntry a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح السجل؟'),
        content: const Text('لا يمكن التراجع عن هذا.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('مسح')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.bookRepo.deleteApplication(a.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) => _loading
          ? const Padding(padding: EdgeInsets.all(40), child: AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...'))
          : ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                ),
                const Text('دفتر الفوائد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('اكتب فائدة استفدتها من هذا الكتاب — لنفسك، لا أحد غيرك سيراها', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _reflectionPrompts
                      .map((p) => ActionChip(
                            label: Text(p, style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              widget.noteCtrl.text = widget.noteCtrl.text.isEmpty ? '$p\n' : '${widget.noteCtrl.text}\n$p\n';
                              widget.noteCtrl.selection = TextSelection.collapsed(offset: widget.noteCtrl.text.length);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: widget.noteCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: 'اكتب ما استفدته هنا... (صفحة ${widget.currentPage})', border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(onPressed: _saveReflection, icon: const Icon(Icons.save_outlined, size: 18), label: const Text('حفظ الملاحظة')),
                ),
                if (_reflections.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('ملاحظاتك', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._reflections.map((r) => _EntryCard(
                        text: r.text,
                        date: r.createdDate,
                        tag: r.page != null ? 'صفحة ${r.page}' : null,
                        onEdit: () => _editReflection(r),
                        onDelete: () => _deleteReflection(r),
                      )),
                ],
                const Divider(height: 32),
                const Text('سجل التطبيق', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('ما الخُلق الذي طبّقته اليوم من هذا الكتاب؟', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _applicationPrompts
                      .map((p) => ActionChip(
                            label: Text(p, style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              widget.applicationCtrl.text = widget.applicationCtrl.text.isEmpty ? '$p\n' : '${widget.applicationCtrl.text}\n$p\n';
                              widget.applicationCtrl.selection = TextSelection.collapsed(offset: widget.applicationCtrl.text.length);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: widget.applicationCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'اكتب ما طبّقته هنا...', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(onPressed: _saveApplication, icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('حفظ التطبيق')),
                ),
                if (_applications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('سجلّك', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ..._applications.map((a) => _EntryCard(
                        text: a.text,
                        date: a.createdDate,
                        onEdit: () => _editApplication(a),
                        onDelete: () => _deleteApplication(a),
                      )),
                ],
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final String text;
  final String date;
  final String? tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EntryCard({required this.text, required this.date, this.tag, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(fontSize: 13, height: 1.6)),
          if (tag != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.bookmark_outline, size: 13, color: AppColors.primaryDark),
                const SizedBox(width: 4),
                Text(tag!, style: const TextStyle(fontSize: 11.5, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(date, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
              const Spacer(),
              InkWell(onTap: onEdit, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 15, color: AppColors.textMuted))),
              InkWell(onTap: onDelete, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 15, color: Colors.redAccent))),
            ],
          ),
        ],
      ),
    );
  }
}
