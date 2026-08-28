import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/recitation_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'recitation_practice_screen.dart';

/// "سجل الأخطاء" (76.3-redesign phase 7) — the real, persisted mistake
/// history behind "تسميع", surfaced for the first time. Real Tarteel
/// reference (76.3-redesign-tarteel-research in TODO.md): a dedicated
/// Mistake History view sorted by frequency, so a student can see which
/// words/ayat they keep getting wrong across sessions, not just the last
/// one. Data comes straight from `RecitationRepository.recurringMistakes`
/// (real `recitation_mistakes` rows, grouped and counted in SQL) -- no
/// synthetic/estimated numbers.
class RecitationMistakesScreen extends StatefulWidget {
  const RecitationMistakesScreen({super.key});

  @override
  State<RecitationMistakesScreen> createState() => _RecitationMistakesScreenState();
}

class _RecitationMistakesScreenState extends State<RecitationMistakesScreen> {
  final _repo = RecitationRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  List<RecurringRecitationMistake> _mistakes = [];
  bool _loading = true;
  int? _surahFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mistakes = await _repo.recurringMistakes(limit: 100);
    if (!mounted) return;
    setState(() {
      _mistakes = mistakes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) {
        final visible = _surahFilter == null ? _mistakes : _mistakes.where((m) => m.surah == _surahFilter).toList();
        final presentSurahs = _mistakes.map((m) => m.surah).toSet().toList()..sort();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(basicText('recitation_mistakes_title', lang))),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _mistakes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(basicText('recitation_mistakes_empty', lang), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : Column(
                      children: [
                        if (presentSurahs.length > 1)
                          SizedBox(
                            height: 48,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(label: Text(basicText('all_label', lang)), selected: _surahFilter == null, onSelected: (_) => setState(() => _surahFilter = null)),
                                ),
                                ...presentSurahs.map((s) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: ChoiceChip(
                                        label: Text(_surahNames[s] ?? '$s'),
                                        selected: _surahFilter == s,
                                        onSelected: (_) => setState(() => _surahFilter = s),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final m = visible[i];
                              return Card(
                                elevation: 0,
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.divider)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFC0392B).withValues(alpha: 0.12),
                                    child: Text('${m.timesWrong}', style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w800)),
                                  ),
                                  title: Text(m.expectedWord, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18, fontWeight: FontWeight.w700)),
                                  subtitle: Text('${_surahNames[m.surah] ?? m.surah} — ${basicText('ayah_label', lang)} ${m.ayah}'),
                                  trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecitationPracticeScreen(surah: m.surah, ayah: m.ayah))),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}
