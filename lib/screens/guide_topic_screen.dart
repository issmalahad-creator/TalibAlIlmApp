import 'package:flutter/material.dart';

import '../data/new_muslim_guide.dart';
import '../repositories/guide_progress_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/guide_diagram.dart';

enum _GuideLang { ar, en, am }

/// Sequential step view for one دليل topic, with an ar/en/am toggle scoped
/// to this screen only (full app-wide i18n is still Phase 6, not built).
class GuideTopicScreen extends StatefulWidget {
  final GuideTopic topic;
  const GuideTopicScreen({super.key, required this.topic});

  @override
  State<GuideTopicScreen> createState() => _GuideTopicScreenState();
}

class _GuideTopicScreenState extends State<GuideTopicScreen> {
  _GuideLang _lang = _GuideLang.ar;

  @override
  void initState() {
    super.initState();
    GuideProgressRepository().markRead(widget.topic.key);
  }

  String _title() => switch (_lang) {
        _GuideLang.ar => widget.topic.titleAr,
        _GuideLang.en => widget.topic.titleEn,
        _GuideLang.am => widget.topic.titleAm,
      };

  String _stepText(GuideStep s) => switch (_lang) {
        _GuideLang.ar => s.textAr,
        _GuideLang.en => s.textEn,
        _GuideLang.am => s.textAm,
      };

  TextDirection _direction() => _lang == _GuideLang.en ? TextDirection.ltr : TextDirection.rtl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GuideDiagram(topicKey: widget.topic.key),
          const SizedBox(height: 14),
          SegmentedButton<_GuideLang>(
            segments: const [
              ButtonSegment(value: _GuideLang.ar, label: Text('العربية')),
              ButtonSegment(value: _GuideLang.en, label: Text('English')),
              ButtonSegment(value: _GuideLang.am, label: Text('አማርኛ')),
            ],
            selected: {_lang},
            onSelectionChanged: (s) => setState(() => _lang = s.first),
          ),
          if (_lang == _GuideLang.am)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'الترجمة الأمهرية بمساعدة الذكاء الاصطناعي ولم تُراجَع من متحدث أصلي بعد.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
          const SizedBox(height: 18),
          Directionality(
            textDirection: _direction(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(widget.topic.steps.length, (i) {
                final step = widget.topic.steps[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primaryLight,
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_stepText(step), style: const TextStyle(fontSize: 14, height: 1.7))),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
