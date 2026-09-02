import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../services/text_scale_preference_service.dart';
import '../theme/app_theme.dart';
import '../utils/study_annotation_anchor.dart';
import '../widgets/annotated_page_text.dart';
import 'turath_book_search_screen.dart';

/// The real reader (Phase 79.6/79.7) — RTL, real page text, page
/// navigation, font size (reuses `TextScalePreferenceService`, the exact
/// preference every other reading screen in this app already shares —
/// not a parallel system, per Ismail's own reuse discipline), and a
/// simple local night-mode toggle (same per-screen-local pattern
/// `quran_reading_screen.dart` already uses for the same concept).
class TurathReaderScreen extends StatefulWidget {
  final int bookId;
  final String bookName;
  final int pageNumber;

  /// From a notebook deep-link: after the page renders, scroll this
  /// annotation into view and pulse it (Phase 79 `79-sa-D`).
  final int? focusAnnotationId;

  /// From "أعد ربطها" on an orphan annotation (`79-sa-E`): open straight
  /// into re-select mode for this annotation.
  final int? editRangeAnnotationId;

  const TurathReaderScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.pageNumber,
    this.focusAnnotationId,
    this.editRangeAnnotationId,
  });

  @override
  State<TurathReaderScreen> createState() => _TurathReaderScreenState();
}

enum _PageStatus { loading, success, notFound, error }

class _TurathReaderScreenState extends State<TurathReaderScreen> {
  final _repo = TurathRepository();
  final _scrollController = ScrollController();
  final _textKey = GlobalKey();
  late int _pageNumber = widget.pageNumber;
  _PageStatus _status = _PageStatus.loading;
  TurathPage? _page;
  String _normText = '';
  List<ResolvedAnnotation> _resolved = const [];
  int? _pulseAnnotationId;
  late int? _editRangeId = widget.editRangeAnnotationId; // highlight whose range the user is re-selecting
  bool _nightMode = false;

  /// True while a non-collapsed text selection exists — freezes the page
  /// scroll so selection-handle drags stay smooth.
  bool _selectionActive = false;
  bool _isFavoritePage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = _PageStatus.loading);
    final TurathPage page;
    try {
      page = await _repo.getPage(widget.bookId, _pageNumber);
    } catch (_) {
      if (mounted) setState(() => _status = _PageStatus.error);
      return;
    }
    if (!mounted) return;
    // Render the page NOW. Everything after this point is best-effort and
    // must never keep the reader on the spinner or discard the page
    // (favourites, study-annotation re-anchoring, last-read).
    setState(() {
      _page = page;
      _normText = normalizePageText(page.text);
      _resolved = const [];
      _pulseAnnotationId = null;
      _status = _PageStatus.success;
    });
    unawaited(_repo.saveLastRead(widget.bookId, widget.bookName, _pageNumber));
    _loadPageExtras();
  }

  Future<void> _loadPageExtras() async {
    try {
      final fav = await _repo.isFavoritePage(widget.bookId, _pageNumber);
      if (mounted) setState(() => _isFavoritePage = fav);
    } catch (_) {/* non-fatal */}
    await _reloadAnnotations();
    _maybeFocusAnnotation();
  }

  /// Notebook deep-link: once the target page's annotations are resolved,
  /// scroll the requested one into view and pulse it briefly. Best-effort —
  /// the scroll offset is estimated with a `TextPainter` at the real layout
  /// width (needs a real-device check, risk R3).
  void _maybeFocusAnnotation() {
    final id = widget.focusAnnotationId;
    if (id == null || _pulseAnnotationId != null) return;
    final match = _resolved.where((r) => r.annotation.id == id && r.resolved.drawable);
    if (match.isEmpty) return;
    final start = match.first.resolved.start!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final textBox = _textKey.currentContext?.findRenderObject() as RenderBox?;
      if (textBox != null && _scrollController.hasClients) {
        final scrollBox = context.findRenderObject() as RenderBox?;
        final topInView = scrollBox == null ? 0.0 : textBox.localToGlobal(Offset.zero, ancestor: scrollBox).dy;
        final style = TextStyle(fontFamily: 'Amiri', fontSize: 16 * TextScalePreferenceService.scaleNotifier.value, height: 2.0);
        final tp = TextPainter(
          text: TextSpan(text: _normText, style: style),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        )..layout(maxWidth: textBox.size.width);
        final caretDy = tp.getOffsetForCaret(TextPosition(offset: start.clamp(0, _normText.length)), Rect.zero).dy;
        final target = _scrollController.offset + topInView + caretDy - 140;
        _scrollController.animateTo(
          target.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
      setState(() => _pulseAnnotationId = id);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _pulseAnnotationId = null);
      });
    });
  }

  Future<void> _reloadAnnotations() async {
    try {
      final resolved = await _repo.resolvedAnnotationsForPage(widget.bookId, _pageNumber, _normText);
      if (mounted) setState(() => _resolved = resolved);
    } catch (_) {/* highlights are optional — a failure here must not break the page */}
  }

  Future<void> _toggleFavoritePage() async {
    await _repo.toggleFavoritePage(widget.bookId, widget.bookName, _pageNumber);
    if (!mounted) return;
    setState(() => _isFavoritePage = !_isFavoritePage);
  }

  void _goToPage(int page) {
    if (page < 1) return;
    setState(() => _pageNumber = page);
    _load();
  }

  // ---- Study annotations (Phase 79 «علامات الدراسة» / Phase B + C) ----

  List<PageHighlight> _pageHighlights() => [
        for (final r in _resolved)
          if (r.resolved.drawable && !r.annotation.isPageLevel)
            PageHighlight(
              annotationId: r.annotation.id,
              start: r.resolved.start!,
              end: r.resolved.end!,
              colorKey: r.annotation.colorKey,
            ),
      ];

  /// Page notes on the current page (coloured notes attached to the whole
  /// page, not a text span). Derived from `_resolved` so it stays in sync.
  List<StudyAnnotation> get _pageNotes =>
      [for (final r in _resolved) if (r.annotation.isPageLevel) r.annotation];

  /// Create a new page note, or view/edit an existing one. The durable
  /// alternative to highlighting — a colour + a note, attached to the page.
  Future<void> _openPageNoteSheet(String lang, {StudyAnnotation? existing}) async {
    if (existing != null) {
      // an existing note reuses the shared annotation sheet (recolour /
      // edit note / delete) — identical affordances to a highlight.
      await _openAnnotationSheet(existing.id, lang);
      return;
    }
    final catalog = await _repo.catalogBook(widget.bookId);
    if (!mounted) return;
    final noteController = TextEditingController();
    var chosenColor = StudyAnnotationColors.benefit;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(basicText('turath_page_note_action', lang),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${widget.bookName} · ${basicText('turath_page_short', lang)} $_pageNumber',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Text(basicText('turath_highlight_pick_color', lang),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final key in StudyAnnotationColors.all)
                      GestureDetector(
                        onTap: () => setSheetState(() => chosenColor = key),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.studyAnnotation(key).$3,
                            shape: BoxShape.circle,
                            border: key == chosenColor
                                ? Border.all(color: AppColors.textDark, width: 2.5)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(basicText('turath_page_note_body_label', lang),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  textDirection: TextDirection.rtl,
                  autofocus: true,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(hintText: basicText('turath_note_hint', lang)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: saving ? null : () => Navigator.pop(sheetContext),
                        child: Text(basicText('cancel_action', lang)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (noteController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(
                                      content: Text(basicText('turath_page_note_empty', lang))));
                                  return;
                                }
                                setSheetState(() => saving = true);
                                await _repo.addPageNote(
                                  bookId: widget.bookId,
                                  pageNumber: _pageNumber,
                                  volume: _page?.volume,
                                  colorKey: chosenColor,
                                  noteBody: noteController.text.trim(),
                                  bookName: widget.bookName,
                                  authorName: catalog?.authorName,
                                );
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                await _reloadAnnotations();
                              },
                        child: Text(basicText('save_action', lang)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Chips for `PageMarksBar` — a reliable way to open an annotation even
  /// where a tap on the highlighted text doesn't register (risk R2).
  List<(int, String, String)> _pageMarks(String lang) {
    final out = <(int, String, String)>[];
    for (final r in _resolved) {
      final a = r.annotation;
      final raw = (a.isPageLevel ? (a.noteBody ?? '') : (a.selectedText ?? '')).trim();
      final label = raw.isEmpty
          ? _annotationTypeLabel(a.noteType, lang)
          : (raw.length <= 24 ? raw : '${raw.substring(0, 24)}…');
      out.add((a.id, a.colorKey, label));
    }
    return out;
  }

  /// The create flow (Phase C). `selectedText` is the AUTHORITATIVE full
  /// string the user selected (from `selection.textInside(value.text)`, not
  /// re-sliced from an offset — that was losing everything after the first
  /// space). Pick a colour, optionally write a note, then ONE save — nothing
  /// is written until the user taps حفظ.
  Future<void> _startHighlight(String selectedText, int? charStartHint, String lang) async {
    final selected = selectedText.trim();
    if (selected.isEmpty) return;
    final catalog = await _repo.catalogBook(widget.bookId);
    if (!mounted) return;

    final noteController = TextEditingController();
    var chosenColor = StudyAnnotationColors.benefit;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(basicText('turath_highlight_action', lang), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '"$selectedText"',
                    textDirection: TextDirection.rtl,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, height: 1.7),
                  ),
                ),
                const SizedBox(height: 14),
                Text(basicText('turath_highlight_pick_color', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final key in StudyAnnotationColors.all)
                      GestureDetector(
                        onTap: () => setSheetState(() => chosenColor = key),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.studyAnnotation(key).$3,
                            shape: BoxShape.circle,
                            border: key == chosenColor ? Border.all(color: AppColors.textDark, width: 2.5) : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(basicText('turath_highlight_add_note_optional', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: basicText('turath_note_hint', lang)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: saving ? null : () => Navigator.pop(sheetContext),
                        child: Text(basicText('cancel_action', lang)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                setSheetState(() => saving = true);
                                await _repo.addAnnotation(
                                  bookId: widget.bookId,
                                  pageNumber: _pageNumber,
                                  volume: _page?.volume,
                                  normalizedPageText: _normText,
                                  selectedText: selectedText,
                                  charStartHint: charStartHint,
                                  colorKey: chosenColor,
                                  noteType: chosenColor,
                                  noteBody: noteController.text.trim(),
                                  bookName: widget.bookName,
                                  authorName: catalog?.authorName,
                                );
                                if (sheetContext.mounted) Navigator.pop(sheetContext);
                                await _reloadAnnotations();
                              },
                        child: Text(basicText('save_action', lang)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _annotationTypeLabel(String? type, String lang) {
    switch (type) {
      case 'explain':
        return basicText('turath_annotation_type_explain', lang);
      case 'memorize':
        return basicText('turath_annotation_type_memorize', lang);
      case 'important':
        return basicText('turath_annotation_type_important', lang);
      case 'question':
        return basicText('turath_annotation_type_question', lang);
      case 'correction':
        return basicText('turath_annotation_type_correction', lang);
      case 'benefit':
      default:
        return basicText('turath_annotation_type_benefit', lang);
    }
  }

  Future<void> _openAnnotationSheet(int id, String lang) async {
    final match = _resolved.where((r) => r.annotation.id == id);
    if (match.isEmpty) return;
    final ann = match.first.annotation;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        final (_, _, accent) = AppColors.studyAnnotation(ann.colorKey);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      _annotationTypeLabel(ann.noteType, lang),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(basicText('turath_annotation_sheet_title', lang), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                if (!ann.isPageLevel)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '"${ann.selectedText}"',
                      textDirection: TextDirection.rtl,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, height: 1.7),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  ann.hasNote ? ann.noteBody! : basicText('turath_annotation_no_note', lang),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: ann.hasNote ? AppColors.textDark : AppColors.textMuted,
                    fontStyle: ann.hasNote ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Text(basicText('turath_annotation_change_color', lang), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final key in StudyAnnotationColors.all)
                      GestureDetector(
                        onTap: () async {
                          await _repo.recolorAnnotation(id, key);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await _reloadAnnotations();
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.studyAnnotation(key).$3,
                            shape: BoxShape.circle,
                            border: key == ann.colorKey ? Border.all(color: AppColors.textDark, width: 2) : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(basicText('turath_annotation_edit_note', lang)),
                        onPressed: () async {
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await _editAnnotationNote(ann, lang);
                        },
                      ),
                    ),
                    // "edit range" only makes sense for a text highlight —
                    // a page note has no span to resize.
                    if (!ann.isPageLevel) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.straighten_rounded, size: 18),
                          label: Text(basicText('turath_annotation_edit_range', lang)),
                          onPressed: () {
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            setState(() => _editRangeId = id);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                  label: Text(basicText('turath_annotation_delete', lang)),
                  onPressed: () async {
                    await _repo.deleteAnnotation(id);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    await _reloadAnnotations();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Confirm the new range for the highlight being edited (`_editRangeId`),
  /// from a fresh selection. Same authoritative-string rule as create.
  Future<void> _confirmEditRange(String selectedText, int? charStartHint, String lang) async {
    final id = _editRangeId;
    if (id == null || selectedText.trim().isEmpty) return;
    await _repo.updateAnnotationRange(id, normalizedPageText: _normText, selectedText: selectedText, charStartHint: charStartHint);
    if (!mounted) return;
    setState(() => _editRangeId = null);
    await _reloadAnnotations();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(basicText('turath_range_updated_toast', lang)), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _editAnnotationNote(StudyAnnotation ann, String lang) async {
    final controller = TextEditingController(text: ann.noteBody ?? '');
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('turath_annotation_edit_note', lang)),
        content: TextField(controller: controller, textDirection: TextDirection.rtl, autofocus: true, maxLines: 4, decoration: InputDecoration(hintText: basicText('turath_note_hint', lang))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(basicText('cancel_action', lang))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(basicText('save_action', lang))),
        ],
      ),
    );
    if (newText == null) return;
    await _repo.updateAnnotationNote(ann.id, noteType: ann.noteType, noteBody: newText);
    await _reloadAnnotations();
  }

  Future<void> _pickPage(String lang) async {
    final controller = TextEditingController(text: '$_pageNumber');
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('turath_go_to_page', lang)),
        content: TextField(controller: controller, keyboardType: TextInputType.number, textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(basicText('cancel_action', lang))),
          TextButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: Text(basicText('go_action', lang))),
        ],
      ),
    );
    if (picked != null && picked > 0) _goToPage(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: _nightMode ? const Color(0xFF1A1A1A) : AppColors.background,
        appBar: AppBar(
          title: Text(widget.bookName, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 15)),
          actions: [
            if (_status == _PageStatus.success)
              IconButton(
                tooltip: basicText('turath_page_note_action', lang),
                icon: Badge(
                  isLabelVisible: _pageNotes.isNotEmpty,
                  label: Text('${_pageNotes.length}'),
                  child: const Icon(Icons.note_add_outlined),
                ),
                onPressed: () => _openPageNoteSheet(lang),
              ),
            if (_status == _PageStatus.success)
              IconButton(
                icon: Icon(_isFavoritePage ? Icons.bookmark : Icons.bookmark_outline),
                onPressed: _toggleFavoritePage,
              ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathBookSearchScreen(bookId: widget.bookId, bookName: widget.bookName))),
            ),
            IconButton(icon: Icon(_nightMode ? Icons.wb_sunny : Icons.wb_sunny_outlined), onPressed: () => setState(() => _nightMode = !_nightMode)),
            IconButton(icon: const Icon(Icons.text_fields_rounded), onPressed: _pickFontSize),
          ],
        ),
        body: _buildBody(lang),
        bottomNavigationBar: _status == _PageStatus.success ? _buildNavBar(lang) : null,
      ),
    );
  }

  Widget _buildBody(String lang) {
    switch (_status) {
      case _PageStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case _PageStatus.notFound:
      case _PageStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(basicText('turath_page_load_error', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: Text(basicText('retry_action', lang))),
            ],
          ),
        );
      case _PageStatus.success:
        final page = _page!;
        final textColor = _nightMode ? const Color(0xFFE0E0E0) : AppColors.textDark;
        return ValueListenableBuilder<double>(
          valueListenable: TextScalePreferenceService.scaleNotifier,
          builder: (context, scale, _) => SingleChildScrollView(
            controller: _scrollController,
            // While a selection handle is being dragged, freeze the page
            // scroll so the handle drag doesn't lose the gesture-arena fight
            // to the scroll view (the "left handle is very tiring" report).
            physics: _selectionActive
                ? const NeverScrollableScrollPhysics()
                : null,
            // Trimmed side padding (was 20) so dragging the left selection
            // handle sideways doesn't run out of the text's hit-test box.
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (page.headings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      page.headings.last,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w800, fontSize: 15 * scale, color: AppColors.primaryDark),
                    ),
                  ),
                if (_editRangeId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.straighten_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(basicText('turath_edit_range_banner', lang), style: const TextStyle(fontSize: 12))),
                        TextButton(onPressed: () => setState(() => _editRangeId = null), child: Text(basicText('cancel_action', lang))),
                      ],
                    ),
                  ),
                PageMarksBar(marks: _pageMarks(lang), onTap: (id) => _openAnnotationSheet(id, lang)),
                AnnotatedPageText(
                  key: _textKey,
                  focusHighlightId: _editRangeId ?? _pulseAnnotationId,
                  onSelectionActive: (a) {
                    if (a != _selectionActive) {
                      setState(() => _selectionActive = a);
                    }
                  },
                  // `normalizePageText` (not the old `_stripHtml`) so the
                  // string shown here is byte-identical to the one study
                  // annotations are anchored against.
                  text: _normText,
                  highlights: _pageHighlights(),
                  // 'Amiri' -- not the theme default -- because the default
                  // has no glyph for real classical-Arabic ligatures like
                  // U+FD4A (found live 2026-08-28: rendered as an empty
                  // "[]" box on a real book page). Amiri is built for
                  // exactly this kind of classical typesetting.
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 16 * scale, height: 2.0, color: textColor),
                  night: _nightMode,
                  onTapHighlight: (id) => _openAnnotationSheet(id, lang),
                  contextMenuBuilder: (context, editableTextState) {
                    final value = editableTextState.textEditingValue;
                    final selection = value.selection;
                    final selectedText = selection.textInside(value.text);
                    final items = <ContextMenuButtonItem>[
                      ...editableTextState.contextMenuButtonItems,
                      if (selectedText.trim().isNotEmpty) ...[
                        ContextMenuButtonItem(
                          label: basicText('share_action', lang),
                          onPressed: () {
                            editableTextState.hideToolbar();
                            Share.share('$selectedText\n\n— ${widget.bookName}، ص $_pageNumber');
                          },
                        ),
                        if (_editRangeId != null)
                          ContextMenuButtonItem(
                            label: basicText('turath_update_range_action', lang),
                            onPressed: () {
                              editableTextState.hideToolbar();
                              _confirmEditRange(selectedText, selection.start, lang);
                            },
                          )
                        else
                          ContextMenuButtonItem(
                            label: basicText('turath_highlight_action', lang),
                            onPressed: () {
                              editableTextState.hideToolbar();
                              // Pass the SELECTED STRING as the source of truth
                              // (not offsets re-sliced from `_normText` — that
                              // was dropping everything after the first space);
                              // `selection.start` is only a locate hint.
                              _startHighlight(selectedText, selection.start, lang);
                            },
                          ),
                      ],
                    ];
                    return AdaptiveTextSelectionToolbar.buttonItems(anchors: editableTextState.contextMenuAnchors, buttonItems: items);
                  },
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildNavBar(String lang) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: _nightMode ? const Color(0xFF242424) : AppColors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _pageNumber > 1 ? () => _goToPage(_pageNumber - 1) : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(basicText('previous_page_action', lang)),
            ),
            GestureDetector(
              onTap: () => _pickPage(lang),
              child: Text('$_pageNumber', style: TextStyle(fontWeight: FontWeight.w800, color: _nightMode ? Colors.white : AppColors.textDark)),
            ),
            TextButton.icon(
              onPressed: () => _goToPage(_pageNumber + 1),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(basicText('next_page_action', lang)),
              iconAlignment: IconAlignment.end,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFontSize() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 8,
            children: TextScalePreferenceService.presets.map((scale) {
              final selected = TextScalePreferenceService.scaleNotifier.value == scale;
              return ChoiceChip(
                label: Text(TextScalePreferenceService.presetLabels[scale] ?? '$scale'),
                selected: selected,
                onSelected: (_) {
                  TextScalePreferenceService.setScale(scale);
                  setSheetState(() {});
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
