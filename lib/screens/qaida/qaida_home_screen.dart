import 'package:flutter/material.dart';

import '../../l10n/basic_translations.dart';
import '../../models/qaida.dart';
import '../../repositories/arabic_curriculum_repository.dart';
import '../../services/language_preference_service.dart';
import '../../services/qaida_content.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_view.dart';
import 'qaida_lesson_screen.dart';

String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);

/// «القاعدة النورانية» — learning to read the Quran from the single letter
/// to the shadda, nine lessons in the traditional order. One learner per
/// phone (Ismail 2026-11-13); progress lives in `arabic_curriculum_progress`
/// as `qaida_<lesson>` keys, so no new table.
class QaidaHomeScreen extends StatefulWidget {
  const QaidaHomeScreen({super.key});

  @override
  State<QaidaHomeScreen> createState() => _QaidaHomeScreenState();
}

class _QaidaHomeScreenState extends State<QaidaHomeScreen> {
  final _repo = ArabicCurriculumRepository();
  List<QaidaLesson> _lessons = const [];
  Set<String> _done = {};
  Set<String> _recorded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await QaidaContent.instance.lessons();
    final recorded = await QaidaContent.instance.recordedAudioIds();
    final learned = await _repo.learnedKeys();
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _recorded = recorded;
      _done = {for (final l in lessons) if (learned.contains(qaidaProgressKey(l.id))) l.id};
      _loading = false;
    });
  }

  Future<void> _open(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QaidaLessonScreen(lessons: _lessons, index: index)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    return Scaffold(
      appBar: AppBar(title: Text(_t('feat_qaida'))),
      body: _loading
          ? AppLoadingView(icon: Icons.abc_rounded, message: basicText('loading_lesson', lang))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(_t('qaida_sub'), style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.6)),
                const SizedBox(height: 10),
                _ProgressLine(done: _done.length, total: _lessons.length),
                const SizedBox(height: 14),
                for (var i = 0; i < _lessons.length; i++)
                  _LessonCard(
                    lesson: _lessons[i],
                    done: _done.contains(_lessons[i].id),
                    isNext: !_done.contains(_lessons[i].id) && _lessons.take(i).every((l) => _done.contains(l.id)),
                    recorded: _lessons[i].distinctSounds.where((s) => _recorded.contains(s.audioId)).length,
                    onTap: () => _open(i),
                  ),
              ],
            ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final int done;
  final int total;
  const _ProgressLine({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _t('cur_n_of_m').replaceAll('{done}', '$done').replaceAll('{total}', '$total'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final QaidaLesson lesson;
  final bool done;
  final bool isNext;
  final int recorded;
  final VoidCallback onTap;
  const _LessonCard({required this.lesson, required this.done, required this.isNext, required this.recorded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sample = lesson.items.take(lesson.id == 'q02' ? 1 : 3).map((i) => i.text).join('  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isNext ? AppColors.primary : AppColors.divider, width: isNext ? 1.6 : 1),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: done ? AppColors.primary : AppColors.primaryLight,
                  child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : Text('${lesson.number}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t(lesson.titleKey),
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(
                        recorded == 0
                            ? _t('qaida_items_n').replaceAll('{n}', '${lesson.items.length}')
                            : '${_t('qaida_items_n').replaceAll('{n}', '${lesson.items.length}')} · 🔊 $recorded',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(sample,
                      style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, color: AppColors.primaryDark, height: 1.9)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
