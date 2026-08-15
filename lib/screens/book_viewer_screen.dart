import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../models/reading_record.dart';
import '../repositories/book_repository.dart';
import '../services/notification_service.dart';

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
    await _bookRepo.saveBookmark(BookBookmark(bookKey: widget.bookKey, lastPage: page, totalPages: total));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('${_currentPage + 1} / $_totalPages')),
            ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
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
