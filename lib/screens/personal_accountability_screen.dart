import 'package:flutter/material.dart';

import '../models/personal_accountability.dart';
import '../repositories/personal_accountability_repository.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
  }

  @override
  void dispose() {
    _rewardController.dispose();
    _punishmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التزامي الشخصي')),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    'هذا التزام بينك وبين نفسك فقط. التطبيق يذكّرك بما كتبته هنا عند إنجازك أو تقصيرك — ولا ينفّذ شيئًا نيابة عنك بأي حال.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.6),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('مكافأتي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'شيء تكافئ به نفسك عند إنجاز مهمة أو استلام شهادة',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('فعّل التذكير بالمكافأة', style: TextStyle(fontSize: 13.5)),
                  value: _rewardEnabled,
                  onChanged: (v) => setState(() => _rewardEnabled = v),
                ),
                if (_rewardEnabled)
                  TextField(
                    controller: _rewardController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'مثلًا: سأشتري كتابًا أحبه'),
                  ),
                const SizedBox(height: 28),
                const Text('إن قصّرت', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'قرارك بالكامل — لا يوجد صح أو خطأ هنا',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  groupValue: _punishmentEnabled,
                  onChanged: (v) => setState(() => _punishmentEnabled = v ?? false),
                  title: const Text('بدون عقاب — أعتمد على نفسي فقط', style: TextStyle(fontSize: 13.5)),
                  subtitle: const Text('خيار صحي تمامًا؛ الالتزام الذاتي وحده كافٍ لكثير من الناس', style: TextStyle(fontSize: 11.5)),
                ),
                RadioListTile<bool>(
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  groupValue: _punishmentEnabled,
                  onChanged: (v) => setState(() => _punishmentEnabled = v ?? false),
                  title: const Text('أضع لنفسي التزامًا عند التقصير', style: TextStyle(fontSize: 13.5)),
                ),
                if (_punishmentEnabled)
                  TextField(
                    controller: _punishmentController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'مثلًا: سأتصدق بمبلغ معيّن'),
                  ),
                const SizedBox(height: 28),
                FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('حفظ')),
              ],
            ),
    );
  }
}
