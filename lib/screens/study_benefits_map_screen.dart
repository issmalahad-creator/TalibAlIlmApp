import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// "خريطة الفوائد" (`79-sa-E`) — a plain, deterministic overview of the
/// student's study annotations: how many, how many carry a note, per
/// category / book / colour / author, plus a "تصدير" that hands the OS a
/// plain-text digest. No AI, no generation — every number is a `COUNT`.
class StudyBenefitsMapScreen extends StatefulWidget {
  /// Optionally scope the export to one book (from "فوائدي في هذا الكتاب").
  final int? bookId;
  final String? bookTitle;
  const StudyBenefitsMapScreen({super.key, this.bookId, this.bookTitle});

  @override
  State<StudyBenefitsMapScreen> createState() => _StudyBenefitsMapScreenState();
}

const _colorLabelKeys = <String, String>{
  'benefit': 'turath_annotation_type_benefit',
  'explain': 'turath_annotation_type_explain',
  'memorize': 'turath_annotation_type_memorize',
  'important': 'turath_annotation_type_important',
  'question': 'turath_annotation_type_question',
};

class _StudyBenefitsMapScreenState extends State<StudyBenefitsMapScreen> {
  final _repo = TurathRepository();
  StudyAnnotationStats? _stats;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _repo.annotationStats().then((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  Future<void> _export(String lang) async {
    setState(() => _exporting = true);
    final text = await _repo.annotationsDigest(bookId: widget.bookId);
    if (!mounted) return;
    setState(() => _exporting = false);
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(basicText('study_map_nothing_to_export', lang))));
      return;
    }
    await Share.share(text, subject: basicText('study_map_export_subject', lang));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.bookTitle == null
              ? basicText('study_map_title', lang)
              : '${basicText('study_map_title', lang)} — ${widget.bookTitle}'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _exporting ? null : () => _export(lang),
          icon: _exporting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.ios_share_rounded),
          label: Text(basicText('study_map_export_action', lang)),
        ),
        body: _stats == null
            ? const Center(child: CircularProgressIndicator())
            : _body(_stats!, lang),
      ),
    );
  }

  Widget _body(StudyAnnotationStats s, String lang) {
    if (s.total == 0) {
      return Center(child: Text(basicText('study_map_empty', lang), style: const TextStyle(color: AppColors.textMuted)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _summaryRow(s, lang),
        const SizedBox(height: 14),
        _section(basicText('study_map_by_color', lang), [
          for (final e in _colorLabelKeys.entries)
            if ((s.byColor[e.key] ?? 0) > 0)
              _bar(basicText(e.value, lang), s.byColor[e.key]!, s.total, AppColors.studyAnnotation(e.key).$3),
        ]),
        _section(basicText('study_map_by_category', lang), [
          for (final c in s.byCategory) _bar(c.name, c.count, s.total, AppColors.primary),
        ]),
        _section(basicText('study_map_by_book', lang), [
          for (final b in s.byBook.take(15)) _bar(b.name, b.count, s.total, AppColors.primaryDark),
        ]),
        _section(basicText('study_map_by_author', lang), [
          for (final a in s.byAuthor.take(15)) _bar(a.name, a.count, s.total, AppColors.textMuted),
        ]),
      ],
    );
  }

  Widget _summaryRow(StudyAnnotationStats s, String lang) {
    Widget tile(String label, int n, {Color? color}) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text('$n', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color ?? AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        tile(basicText('study_map_total', lang), s.total),
        const SizedBox(width: 8),
        tile(basicText('study_map_with_note', lang), s.withNote),
        const SizedBox(width: 8),
        tile(basicText('study_map_orphans', lang), s.orphans, color: s.orphans > 0 ? AppColors.textDark : AppColors.textMuted),
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _bar(String label, int count, int total, Color color) {
    final frac = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, textDirection: TextDirection.rtl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: frac, minHeight: 5, backgroundColor: AppColors.divider, color: color),
          ),
        ],
      ),
    );
  }
}
