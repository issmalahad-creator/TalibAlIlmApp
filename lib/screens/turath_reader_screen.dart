import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../services/text_scale_preference_service.dart';
import '../theme/app_theme.dart';

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
  const TurathReaderScreen({super.key, required this.bookId, required this.bookName, required this.pageNumber});

  @override
  State<TurathReaderScreen> createState() => _TurathReaderScreenState();
}

enum _PageStatus { loading, success, notFound, error }

class _TurathReaderScreenState extends State<TurathReaderScreen> {
  final _repo = TurathRepository();
  late int _pageNumber = widget.pageNumber;
  _PageStatus _status = _PageStatus.loading;
  TurathPage? _page;
  bool _nightMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _PageStatus.loading);
    try {
      final page = await _repo.getPage(widget.bookId, _pageNumber);
      if (!mounted) return;
      setState(() {
        _page = page;
        _status = _PageStatus.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _PageStatus.error);
    }
  }

  void _goToPage(int page) {
    if (page < 1) return;
    setState(() => _pageNumber = page);
    _load();
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
            padding: const EdgeInsets.all(20),
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
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15 * scale, color: AppColors.primaryDark),
                    ),
                  ),
                SelectableText(
                  _stripHtml(page.text),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 16 * scale, height: 2.0, color: textColor),
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

  // Real page text includes HTML markup (headings/spans) -- strip for
  // plain reading text, matching how the search snippet is handled.
  static String _stripHtml(String text) => text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}
