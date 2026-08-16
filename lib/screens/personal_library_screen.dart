import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/personal_book.dart';
import '../services/personal_library_service.dart';
import '../theme/app_theme.dart';
import 'book_viewer_screen.dart';
import '../widgets/loading_view.dart';

/// "مكتبتي" — a student-organized personal library. Top level shows
/// sections/folders the student created themselves (plus a fixed
/// "بدون قسم" bucket for anything not filed yet); opening a section shows
/// only the books filed there, with an "add book" action that files the
/// newly-picked PDF straight into that section. Every book here is a PDF the
/// student already had on their own device — this screen only organizes and
/// displays them, it never fetches or hosts any book content itself.
class PersonalLibraryScreen extends StatefulWidget {
  const PersonalLibraryScreen({super.key});

  @override
  State<PersonalLibraryScreen> createState() => _PersonalLibraryScreenState();
}

class _PersonalLibraryScreenState extends State<PersonalLibraryScreen> {
  final _service = PersonalLibraryService();

  List<PersonalBookCategory> _categories = [];
  List<PersonalBook> _books = [];
  bool _loading = true;
  bool _busy = false;

  /// null = top-level folder list. -1 = the fixed "بدون قسم" bucket. Any
  /// other value = a real category id.
  int? _openCategoryId;

  final _searchController = TextEditingController();
  String _searchQuery = '';

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
    final categories = await _service.categories();
    final books = await _service.all();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _books = books;
      _loading = false;
    });
  }

  List<PersonalBook> _booksIn(int? categoryId) {
    if (categoryId == -1) return _books.where((b) => b.categoryId == null).toList();
    return _books.where((b) => b.categoryId == categoryId).toList();
  }

  Future<void> _createCategory() async {
    final name = await _promptForName(title: 'قسم جديد', hint: 'مثال: الفقه');
    if (name == null || name.trim().isEmpty) return;
    await _service.createCategory(name.trim());
    await _load();
  }

  Future<void> _renameCategory(PersonalBookCategory cat) async {
    final name = await _promptForName(title: 'إعادة تسمية القسم', hint: cat.name, initial: cat.name);
    if (name == null || name.trim().isEmpty || cat.id == null) return;
    await _service.renameCategory(cat.id!, name.trim());
    await _load();
  }

  Future<void> _deleteCategory(PersonalBookCategory cat) async {
    if (cat.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف القسم'),
        content: Text('سيتم حذف قسم "${cat.name}" فقط — الكتب بداخله ستبقى محفوظة ضمن "بدون قسم".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    await _service.deleteCategory(cat.id!);
    await _load();
  }

  Future<String?> _promptForName({required String title, String? hint, String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('حفظ')),
        ],
      ),
    );
  }

  Future<void> _pickBookInto(int? categoryId) async {
    setState(() => _busy = true);
    try {
      final effectiveCategoryId = categoryId == -1 ? null : categoryId;
      final book = await _service.pickAndAdd(categoryId: effectiveCategoryId);
      if (book != null) await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إضافة الكتاب: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openBook(PersonalBook pb) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BookViewerScreen(filePath: pb.filePath, title: pb.title, bookKey: 'personal_${pb.id}')));
  }

  Future<void> _deleteBook(PersonalBook pb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الكتاب'),
        content: Text('هل تريد حذف "${pb.title}" من مكتبتك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    await _service.remove(pb);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('مكتبتي')), body: const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...'));
    }
    return _openCategoryId == null ? _buildFolderList() : _buildCategoryBooks();
  }

  List<PersonalBook> get _searchResults {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _books.where((b) => b.title.toLowerCase().contains(q)).toList();
  }

  String _categoryNameFor(int? categoryId) {
    if (categoryId == null) return 'بدون قسم';
    return _categories.firstWhere((c) => c.id == categoryId, orElse: () => PersonalBookCategory(name: 'قسم')).name;
  }

  /// A plain-text backup of titles/sections (not the files themselves — a
  /// student who loses/changes their phone would still need to re-add the
  /// actual PDFs, this is just a reminder list of what was in the library).
  Future<void> _exportList() async {
    final buffer = StringBuffer('مكتبتي\n');
    for (final cat in _categories) {
      final books = _booksIn(cat.id);
      if (books.isEmpty) continue;
      buffer.writeln('\n${cat.name}:');
      for (final b in books) {
        buffer.writeln('- ${b.title}');
      }
    }
    final uncategorized = _booksIn(-1);
    if (uncategorized.isNotEmpty) {
      buffer.writeln('\nبدون قسم:');
      for (final b in uncategorized) {
        buffer.writeln('- ${b.title}');
      }
    }
    if (_books.isEmpty) {
      buffer.writeln('\n(المكتبة فارغة)');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ قائمة الكتب — يمكنك لصقها في تلجرام أو الملاحظات كنسخة احتياطية.')),
    );
  }

  Widget _buildFolderList() {
    final uncategorizedCount = _booksIn(-1).length;
    final searching = _searchQuery.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'نسخ قائمة الكتب (نسخة احتياطية)',
            onPressed: _exportList,
          ),
        ],
      ),
      floatingActionButton: searching
          ? null
          : FloatingActionButton.extended(
              onPressed: _createCategory,
              icon: const Icon(Icons.create_new_folder_rounded),
              label: const Text('قسم جديد'),
            ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث في كل كتبك...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searching
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          if (searching) ..._buildSearchResults() else ..._buildFolders(uncategorizedCount),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults() {
    final results = _searchResults;
    if (results.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('لا توجد نتائج.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
        ),
      ];
    }
    return results
        .map((pb) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                title: Text(pb.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_categoryNameFor(pb.categoryId), style: const TextStyle(fontSize: 11)),
                onTap: () => _openBook(pb),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                  tooltip: 'حذف',
                  onPressed: () => _deleteBook(pb),
                ),
              ),
            ))
        .toList();
  }

  List<Widget> _buildFolders(int uncategorizedCount) {
    return [
      const Text('رتّب كتبك في أقسام (مثل: الفقه، العقيدة، السيرة) لتجدها بسهولة لاحقاً.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
      const SizedBox(height: 12),
      ..._categories.map((cat) => _folderRow(
            icon: Icons.folder_rounded,
            title: cat.name,
            count: _booksIn(cat.id).length,
            onTap: () => setState(() => _openCategoryId = cat.id),
            onRename: () => _renameCategory(cat),
            onDelete: () => _deleteCategory(cat),
          )),
      _folderRow(
        icon: Icons.folder_open_rounded,
        title: 'بدون قسم',
        count: uncategorizedCount,
        onTap: () => setState(() => _openCategoryId = -1),
      ),
    ];
  }

  Widget _folderRow({
    required IconData icon,
    required String title,
    required int count,
    required VoidCallback onTap,
    VoidCallback? onRename,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$count كتاب', style: const TextStyle(fontSize: 12)),
        onTap: onTap,
        trailing: (onRename == null && onDelete == null)
            ? const Icon(Icons.chevron_left_rounded)
            : PopupMenuButton<String>(
                onSelected: (v) => v == 'rename' ? onRename?.call() : onDelete?.call(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
                  PopupMenuItem(value: 'delete', child: Text('حذف القسم')),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryBooks() {
    final isUncategorized = _openCategoryId == -1;
    final name = isUncategorized
        ? 'بدون قسم'
        : _categories.firstWhere((c) => c.id == _openCategoryId, orElse: () => PersonalBookCategory(name: 'قسم')).name;
    final books = _booksIn(_openCategoryId);
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _openCategoryId = null),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _pickBookInto(_openCategoryId),
        icon: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add),
        label: Text(_busy ? 'جارٍ الإضافة...' : 'إضافة كتاب'),
      ),
      body: books.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('لا توجد كتب هنا بعد.\nاضغط "إضافة كتاب" لاختيار PDF من جهازك.',
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: books
                  .map((pb) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                          title: Text(pb.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _openBook(pb),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
                            tooltip: 'حذف',
                            onPressed: () => _deleteBook(pb),
                          ),
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}
