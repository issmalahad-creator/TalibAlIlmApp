import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/personal_accountability.dart';
import '../repositories/personal_accountability_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// "التزامي الشخصي" — QURAN_COMPANION_ROADMAP.md section 4.7. The student
/// writes their own reward and (optionally) their own consequence for
/// falling short. The app only ever reminds them of what they wrote here —
/// see the disclaimer at the top of the screen, which is not just UI copy,
/// it's the actual behavior: nothing here is automated or enforced.
class PersonalAccountabilityScreen extends StatefulWidget {
  const PersonalAccountabilityScreen({super.key});

  @override
  State<PersonalAccountabilityScreen> createState() => _PersonalAccountabilityScreenState();
}

class _PersonalAccountabilityScreenState extends State<PersonalAccountabilityScreen> {
  final _repo = PersonalAccountabilityRepository();
  final _rewardController = TextEditingController();
  final _punishmentController = TextEditingController();

  bool _loading = true;
  bool _rewardEnabled = false;
  bool _punishmentEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _repo.get();
    if (!mounted) return;
    setState(() {
      _rewardEnabled = value.rewardEnabled;
      _rewardController.text = value.rewardText;
      _punishmentEnabled = value.punishmentEnabled;
      _punishmentController.text = value.punishmentText;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _repo.save(PersonalAccountability(
      rewardEnabled: _rewardEnabled,
      rewardText: _rewardController.text.trim(),
      punishmentEnabled: _punishmentEnabled,
      punishmentText: _punishmentController.text.trim(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(basicText('saved_message', LanguagePreferenceService.currentLanguage))));
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _punishmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(title: Text(basicText('personal_accountability_title', lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: Text(
                    basicText('personal_accountability_intro', lang),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(basicText('my_reward_header', lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  basicText('reward_subtitle', lang),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(basicText('enable_reward_reminder_action', lang), style: const TextStyle(fontSize: 13.5)),
                  value: _rewardEnabled,
                  onChanged: (v) => setState(() => _rewardEnabled = v),
                ),
                if (_rewardEnabled)
                  TextField(
                    controller: _rewardController,
                    maxLines: 2,
                    decoration: InputDecoration(hintText: basicText('reward_hint_example', lang)),
                  ),
                const SizedBox(height: 28),
                Text(basicText('if_i_fall_short_header', lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  basicText('if_i_fall_short_subtitle', lang),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  groupValue: _punishmentEnabled,
                  onChanged: (v) => setState(() => _punishmentEnabled = v ?? false),
                  title: Text(basicText('no_punishment_option_title', lang), style: const TextStyle(fontSize: 13.5)),
                  subtitle: Text(basicText('no_punishment_option_subtitle', lang), style: const TextStyle(fontSize: 11.5)),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  groupValue: _punishmentEnabled,
                  onChanged: (v) => setState(() => _punishmentEnabled = v ?? false),
                  title: Text(basicText('set_own_commitment_option', lang), style: const TextStyle(fontSize: 13.5)),
                ),
                if (_punishmentEnabled)
                  TextField(
                    controller: _punishmentController,
                    maxLines: 2,
                    decoration: InputDecoration(hintText: basicText('punishment_hint_example', lang)),
                  ),
                const SizedBox(height: 28),
                FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: Text(basicText('save', lang))),
              ],
            ),
      ),
    );
  }
}
