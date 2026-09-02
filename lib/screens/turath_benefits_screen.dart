import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/turath_models.dart';
import '../repositories/turath_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'turath_reader_screen.dart';

/// "فوائدي" (spec item 14: "دفتر الفوائد") — standalone learning takeaways
/// the student writes for themselves, optionally citing a source. Unlike
/// [TurathQuote] (an exact excerpt) or [TurathNote] (tied to one page),
/// a benefit can be created from scratch at any time via the + button,
/// which is why this screen (unlike quotes/notes) needs its own creation
/// dialog rather than only ever being written from the reader.
class TurathBenefitsScreen extends StatefulWidget {
  const TurathBenefitsScreen({super.key});

  @override
  State<TurathBenefitsScreen> createState() => _TurathBenefitsScreenState();
}

class _TurathBenefitsScreenState extends State<TurathBenefitsScreen> {
  final _repo = TurathRepository();
  List<TurathBenefit>? _benefits;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final benefits = await _repo.allBenefits();
    if (!mounted) return;
    setState(() => _benefits = benefits);
  }

  Future<void> _addBenefit(String lang) async {
    final textController = TextEditingController();
    final topicController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('turath_add_benefit_action', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: textController, textDirection: TextDirection.rtl, autofocus: true, maxLines: 4, decoration: InputDecoration(hintText: basicText('turath_benefit_hint', lang))),
            const SizedBox(height: 8),
            TextField(controller: topicController, textDirection: TextDirection.rtl, decoration: InputDecoration(hintText: basicText('turath_benefit_topic_hint', lang))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('cancel_action', lang))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('save_action', lang))),
        ],
      ),
    );
    if (saved != true || textController.text.trim().isEmpty) return;
    await _repo.addBenefit(text: textController.text.trim(), topic: topicController.text.trim().isEmpty ? null : topicController.text.trim());
    _load();
  }

  Future<void> _editBenefit(TurathBenefit b, String lang) async {
    final controller = TextEditingController(text: b.text);
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('edit_action', lang)),
        content: TextField(controller: controller, textDirection: TextDirection.rtl, autofocus: true, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(basicText('cancel_action', lang))),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(basicText('save_action', lang))),
        ],
      ),
    );
    if (newText == null || newText.isEmpty) return;
    await _repo.updateBenefit(b.id, newText);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(basicText('turath_benefits_title', lang))),
        floatingActionButton: FloatingActionButton(onPressed: () => _addBenefit(lang), child: const Icon(Icons.add)),
        body: _benefits == null
            ? const Center(child: CircularProgressIndicator())
            : _benefits!.isEmpty
                ? Center(child: Text(basicText('turath_no_benefits_empty', lang), style: const TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _benefits!.length,
                    itemBuilder: (context, i) {
                      final b = _benefits![i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(b.text, textDirection: TextDirection.rtl, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (b.topic != null && b.topic!.isNotEmpty)
                                Padding(padding: const EdgeInsets.only(top: 4), child: Text(b.topic!, textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700))),
                              if (b.sourceBookName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('${b.sourceBookName} — ص${b.sourcePageNumber}', textDirection: TextDirection.rtl, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ),
                            ],
                          ),
                          onTap: b.sourceBookId != null
                              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => TurathReaderScreen(bookId: b.sourceBookId!, bookName: b.sourceBookName!, pageNumber: b.sourcePageNumber!)))
                              : () => _editBenefit(b, lang),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editBenefit(b, lang)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                                onPressed: () async {
                                  await _repo.deleteBenefit(b.id);
                                  _load();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
