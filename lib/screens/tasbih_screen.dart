import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/basic_translations.dart';
import '../repositories/milestone_repository.dart';
import '../repositories/tasbih_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../widgets/celebration_overlay.dart';

const _phrases = <String, String>{
  'subhanallah': 'سبحان الله',
  'alhamdulillah': 'الحمد لله',
  'allahuakbar': 'الله أكبر',
  'lailahaillallah': 'لا إله إلا الله',
  'astaghfirullah': 'أستغفر الله',
  'subhanallahiwabihamdih': 'سبحان الله وبحمده',
};

const _targets = [33, 100, 300, 500, 1000];

/// "التسبيح" — a free-tap dhikr counter with a target, Ismail's 2026-08-16
/// request: a genuinely missing feature (confirmed via grep — the app had
/// nothing like it; adhkar's per-item counters are scripted content, not a
/// free "count any phrase toward any target" tool). Uses the new
/// `AppRadius`/`AppMotion` design tokens throughout rather than picking
/// ad-hoc numbers.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final _repo = TasbihRepository();
  final _milestoneRepo = MilestoneRepository();
  String _phraseKey = 'subhanallah';
  int _target = 33;
  int _count = 0;
  bool _loading = true;

  /// CUSTOMIZATION_IDEAS.md #1 — phrases the student added themselves,
  /// keyed `'custom_<id>'` so they never collide with the 6 built-in string
  /// keys. Combined with `_phrases` via `_allPhrases` everywhere a lookup
  /// is needed, so the rest of the screen doesn't need to know which list
  /// a given key came from.
  Map<String, String> _customPhrases = {};
  Map<String, String> get _allPhrases => {..._phrases, ..._customPhrases};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final customPhrases = await _repo.customPhrases();
    final count = await _repo.todayCount(_phraseKey);
    if (!mounted) return;
    setState(() {
      _customPhrases = {for (final (id, text) in customPhrases) 'custom_$id': text};
      _count = count;
      _loading = false;
    });
  }

  Future<void> _addCustomPhrase() async {
    final lang = LanguagePreferenceService.currentLanguage;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('add_custom_dhikr_title', lang)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.right,
          decoration: InputDecoration(hintText: basicText('write_dhikr_or_dua_hint', lang)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(basicText('cancel', lang))),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(basicText('add', lang))),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    await _repo.addCustomPhrase(text);
    await _load();
  }

  Future<void> _confirmDeleteCustomPhrase(String phraseKey, String text) async {
    final lang = LanguagePreferenceService.currentLanguage;
    final id = int.parse(phraseKey.substring('custom_'.length));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(basicText('delete_custom_dhikr_title', lang)),
        content: Text(text, textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(basicText('undo_action', lang))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(basicText('delete', lang))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repo.deleteCustomPhrase(id);
    if (_phraseKey == phraseKey) {
      setState(() => _phraseKey = 'subhanallah');
    }
    await _load();
  }

  Future<void> _tap() async {
    HapticFeedback.lightImpact();
    final next = await _repo.increment(_phraseKey);
    if (!mounted) return;
    setState(() => _count = next);
    // 100_IDEAS_FOR_IMPROVEMENT.md #33 ("التسبيح... لا شهادات له") — a
    // lifetime total across all phrases/days, not the daily count above,
    // matching the other pillars' certificate pattern.
    final lifetimeTotal = await _repo.lifetimeTotal();
    final newlyEarned = await _milestoneRepo.checkTasbihMilestones(lifetimeTotal);
    for (final milestone in newlyEarned) {
      if (!mounted) return;
      await showCelebration(context, milestone);
    }
  }

  Future<void> _reset() async {
    await _repo.reset(_phraseKey);
    if (!mounted) return;
    setState(() => _count = 0);
  }

  void _selectPhrase(String key) {
    setState(() => _phraseKey = key);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (_count / _target).clamp(0.0, 1.0);
    final complete = _count >= _target;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(
        title: Text(basicText('tasbih_title', lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: basicText('reset_today_tooltip', lang),
            onPressed: _reset,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._allPhrases.entries.map(
                          (e) => GestureDetector(
                            // Long-press to delete — only meaningful for
                            // custom phrases; built-in ones ignore it since
                            // `_confirmDeleteCustomPhrase` only accepts
                            // `custom_*` keys.
                            onLongPress: e.key.startsWith('custom_') ? () => _confirmDeleteCustomPhrase(e.key, e.value) : null,
                            child: ChoiceChip(
                              label: Text(
                                e.value,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                              selected: _phraseKey == e.key,
                              onSelected: (_) => _selectPhrase(e.key),
                            ),
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(basicText('custom_dhikr_chip_label', lang), style: const TextStyle(fontSize: 12.5)),
                          onPressed: _addCustomPhrase,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          basicText('target_label_prefix', lang),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            children: _targets
                                .map(
                                  (t) => ChoiceChip(
                                    label: Text(
                                      '$t',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    selected: _target == t,
                                    onSelected: (_) =>
                                        setState(() => _target = t),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: _tap,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _allPhrases[_phraseKey]!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: fraction),
                                      duration: AppMotion.normal,
                                      curve: AppMotion.stateCurve,
                                      builder: (context, value, _) =>
                                          CircularProgressIndicator(
                                            value: value,
                                            strokeWidth: 12,
                                            backgroundColor: AppColors.divider,
                                            valueColor: AlwaysStoppedAnimation(
                                              complete
                                                  ? const Color(0xFFB8860B)
                                                  : AppColors.primary,
                                            ),
                                          ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_count',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        '${basicText('of_target_prefix', lang)} $_target',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              complete
                                  ? basicText('tasbih_target_complete_message', lang)
                                  : basicText('tap_anywhere_to_tasbih_message', lang),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: complete
                                    ? const Color(0xFFB8860B)
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
