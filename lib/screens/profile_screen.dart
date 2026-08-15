import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../models/student_profile.dart';
import '../repositories/profile_repository.dart';
import '../services/calendar_preference_service.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'adab_screen.dart';
import 'adhkar_screen.dart';
import 'hadith_screen.dart';
import 'new_muslim_guide_screen.dart';
import 'prayer_times_screen.dart';
import 'qibla_screen.dart';
import 'wird_screen.dart';
import 'hifz_teacher_screen.dart';
import 'personal_accountability_screen.dart';
import 'support_screen.dart';
import 'completion_goals_screen.dart';
import 'journey_screen.dart';
import 'madarij_screen.dart';
import 'wasitiyyah_screen.dart';
import 'zad_almaad_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = ProfileRepository();
  final _nameCtrl = TextEditingController();
  final _residenceCtrl = TextEditingController();
  final _studySourceCtrl = TextEditingController();
  String _studyTrack = StudentProfile.studyTracks.first;
  bool _loading = true;
  bool _useGregorian = CalendarPreferenceService.useGregorian;
  String _lang = LanguagePreferenceService.currentLanguage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _repo.get();
    _nameCtrl.text = profile.fullName;
    _residenceCtrl.text = profile.residence;
    _studySourceCtrl.text = profile.studySource;
    if (profile.studyTrack.isNotEmpty && StudentProfile.studyTracks.contains(profile.studyTrack)) {
      _studyTrack = profile.studyTrack;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await _repo.save(StudentProfile(
      fullName: _nameCtrl.text.trim(),
      residence: _residenceCtrl.text.trim(),
      studyTrack: _studyTrack,
      studySource: _studySourceCtrl.text.trim(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _residenceCtrl.dispose();
    _studySourceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _residenceCtrl,
                  decoration: const InputDecoration(labelText: 'محل الإقامة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _studyTrack,
                  decoration: const InputDecoration(labelText: 'المسار العلمي', border: OutlineInputBorder()),
                  items: StudentProfile.studyTracks
                      .map((track) => DropdownMenuItem(value: track, child: Text(track)))
                      .toList(),
                  onChanged: (v) => setState(() => _studyTrack = v ?? _studyTrack),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _studySourceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'مصدر الدراسة (مثال: الراسخون في العلم)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('عرض التواريخ بالتقويم الميلادي', style: TextStyle(fontSize: 13.5)),
                    subtitle: const Text('التخزين الداخلي يبقى هجريًا دائمًا — هذا يغيّر طريقة العرض فقط', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    value: _useGregorian,
                    onChanged: (v) async {
                      await CalendarPreferenceService.setUseGregorian(v);
                      setState(() => _useGregorian = v);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('لغة العناوين الأساسية', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      const Text(
                        'يبقى المحتوى الإسلامي العميق (القرآن، الأذكار، الفقه) بالعربية دائمًا — هذا يترجم فقط عناوين التنقل الأساسية',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _lang,
                        items: supportedLanguages.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          await LanguagePreferenceService.setLanguage(v);
                          setState(() => _lang = v);
                        },
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text(basicText('support_faq', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HifzTeacherScreen())),
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('أستاذ التحفيظ'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const PersonalAccountabilityScreen())),
                  icon: const Icon(Icons.self_improvement_rounded),
                  label: Text(basicText('personal_commitment', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithScreen())),
                  icon: const Icon(Icons.format_quote_rounded),
                  label: const Text('الأربعين النووية'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WasitiyyahScreen())),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('العقيدة الواسطية'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ZadAlMaadScreen())),
                  icon: const Icon(Icons.history_edu_rounded),
                  label: const Text('زاد المعاد'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MadarijScreen())),
                  icon: const Icon(Icons.terrain_rounded),
                  label: const Text('مدارج السالكين (متقدم)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdabScreen())),
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: Text(basicText('adab', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
                  icon: const Icon(Icons.access_time_outlined),
                  label: Text(basicText('prayer_times', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
                  icon: const Icon(Icons.explore_outlined),
                  label: Text(basicText('qibla', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletionGoalsScreen())),
                  icon: const Icon(Icons.flag_circle_outlined),
                  label: Text(basicText('completion_plans', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JourneyScreen())),
                  icon: const Icon(Icons.route_outlined),
                  label: Text(basicText('my_journey', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhkarScreen())),
                  icon: const Icon(Icons.nights_stay_outlined),
                  label: Text(basicText('adhkar', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WirdScreen())),
                  icon: const Icon(Icons.checklist_rtl_outlined),
                  label: Text(basicText('wird', _lang)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewMuslimGuideScreen())),
                  icon: const Icon(Icons.diversity_3_outlined),
                  label: Text(basicText('new_muslim_guide', _lang)),
                ),
              ],
            ),
    );
  }
}
