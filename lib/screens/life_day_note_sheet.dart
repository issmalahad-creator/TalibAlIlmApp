import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/basic_translations.dart';
import '../repositories/life_plan_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// «مُحرّك الحياة» — L5 · the day-note / tomorrow-goal capture
/// (`docs/LIFE_ENGINE.md` §2 reflection layer). A calm modal sheet: how the
/// day went, one intention for tomorrow, an optional mood. Backed by
/// `life_day_notes` (already in v55). Returns true if something was saved.
Future<bool> showLifeDayNoteSheet(BuildContext context, {String? date}) async {
  final ymd = date ?? LifePlanRepository.today();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LifeDayNoteSheet(date: ymd),
  );
  return saved ?? false;
}

class _LifeDayNoteSheet extends StatefulWidget {
  final String date;
  const _LifeDayNoteSheet({required this.date});

  @override
  State<_LifeDayNoteSheet> createState() => _LifeDayNoteSheetState();
}

class _LifeDayNoteSheetState extends State<_LifeDayNoteSheet> {
  final _repo = LifePlanRepository();
  final _note = TextEditingController();
  final _goal = TextEditingController();
  int? _mood;
  bool _loading = true;
  bool _saving = false;

  String get _lang => LanguagePreferenceService.currentLanguage;

  static const _gold = Color(0xFFD9A441);
  static const _moods = ['😔', '😐', '🙂', '😊', '🤩'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final n = await _repo.note(widget.date);
    if (!mounted) return;
    setState(() {
      _note.text = n?.note ?? '';
      _goal.text = n?.tomorrowGoal ?? '';
      _mood = n?.mood;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _repo.saveNote(
      widget.date,
      note: _note.text.trim(),
      tomorrowGoal: _goal.text.trim(),
      mood: _mood,
    );
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;
    final mq = MediaQuery.of(context);
    return AnimatedPadding(
      duration: AppMotion.fast,
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFBF6EE),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        // keep the save button clear of the gesture / nav bar
        padding: EdgeInsets.fromLTRB(18, 12, 18, 20 + mq.viewPadding.bottom),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    basicText('life_note_title', lang),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    basicText('life_note_sub', lang),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  _label(basicText('life_note_day_label', lang)),
                  const SizedBox(height: 6),
                  _field(_note, basicText('life_note_day_hint', lang), 3),
                  const SizedBox(height: 14),
                  _label(basicText('life_note_goal_label', lang)),
                  const SizedBox(height: 6),
                  _field(_goal, basicText('life_note_goal_hint', lang), 2),
                  const SizedBox(height: 16),
                  _label(basicText('life_note_mood_label', lang)),
                  const SizedBox(height: 8),
                  _moodRow(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(basicText('life_note_save', lang),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: AppColors.textDark));

  Widget _field(TextEditingController c, String hint, int lines) => TextField(
        controller: c,
        maxLines: lines,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 13, height: 1.5),
        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: TextDirection.rtl,
          hintStyle:
              const TextStyle(fontSize: 12, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: _gold, width: 1.6),
          ),
        ),
      );

  Widget _moodRow() => Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _moods.length; i++)
            GestureDetector(
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _mood = _mood == i + 1 ? null : i + 1);
              },
              child: AnimatedContainer(
                duration: AppMotion.fast,
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _mood == i + 1
                      ? _gold.withValues(alpha: 0.18)
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _mood == i + 1 ? _gold : AppColors.divider,
                    width: _mood == i + 1 ? 1.8 : 1,
                  ),
                ),
                child: Text(_moods[i], style: const TextStyle(fontSize: 22)),
              ),
            ),
        ],
      );
}
