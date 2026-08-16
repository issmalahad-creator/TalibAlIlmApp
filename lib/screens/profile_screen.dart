import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/basic_translations.dart';
import '../models/student_profile.dart';
import '../repositories/profile_repository.dart';
import '../services/calendar_preference_service.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nav_tile.dart';
import 'adab_screen.dart';
import 'adhkar_screen.dart';
import 'arabic_curriculum_screen.dart';
import 'hadith_screen.dart';
import 'new_muslim_guide_screen.dart';
import 'prayer_times_screen.dart';
import 'qibla_screen.dart';
import 'salah_tracker_screen.dart';
import 'audio_library_screen.dart';
import 'tajweed_screen.dart';
import 'wird_screen.dart';
import 'hifz_teacher_screen.dart';
import 'personal_accountability_screen.dart';
import 'time_awareness_screen.dart';
import 'support_screen.dart';
import 'completion_goals_screen.dart';
import 'journey_screen.dart';
import 'madarij_screen.dart';
import 'wasitiyyah_screen.dart';
import 'zad_almaad_screen.dart';
import '../widgets/loading_view.dart';

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
  String? _photoPath;
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
    _photoPath = profile.photoPath;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await _repo.save(StudentProfile(
      fullName: _nameCtrl.text.trim(),
      residence: _residenceCtrl.text.trim(),
      studyTrack: _studyTrack,
      studySource: _studySourceCtrl.text.trim(),
      photoPath: _photoPath,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
    Navigator.pop(context);
  }

  /// "صورة الشهادة" (Ismail's request 2026-08-16) — reuses `file_picker`
  /// (already a dependency for the personal PDF library) instead of adding
  /// `image_picker`. Copies the chosen image into the app's own documents
  /// directory under a fixed name so it survives regardless of where the
  /// original file lives/gets moved — same reasoning as why certificate
  /// captures go through `path_provider` already.
  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = pickedPath.contains('.') ? pickedPath.split('.').last : 'jpg';
    final dest = await File(pickedPath).copy('${docsDir.path}/certificate_photo.$ext');
    if (!mounted) return;
    setState(() => _photoPath = dest.path);
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
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                          child: _photoPath == null ? const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryDark) : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _pickPhoto,
                        child: Text(_photoPath == null ? 'إضافة صورة للشهادات' : 'تغيير صورة الشهادات', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 16),
                NavGrid(items: [
                  NavTileData(
                    icon: Icons.route_outlined,
                    label: basicText('my_journey', _lang),
                    color: NavColors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JourneyScreen())),
                  ),
                  NavTileData(
                    icon: Icons.flag_circle_outlined,
                    label: basicText('completion_plans', _lang),
                    color: NavColors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletionGoalsScreen())),
                  ),
                  NavTileData(
                    icon: Icons.school_rounded,
                    label: 'أستاذ التحفيظ',
                    color: NavColors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HifzTeacherScreen())),
                  ),
                  NavTileData(
                    icon: Icons.self_improvement_rounded,
                    label: basicText('personal_commitment', _lang),
                    color: NavColors.indigo,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalAccountabilityScreen())),
                  ),
                  NavTileData(
                    icon: Icons.hourglass_bottom_rounded,
                    label: 'محاسبة الوقت',
                    color: NavColors.coral,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeAwarenessScreen())),
                  ),
                  NavTileData(
                    icon: Icons.format_quote_rounded,
                    label: 'الأربعين النووية',
                    color: NavColors.brown,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithScreen())),
                  ),
                  NavTileData(
                    icon: Icons.menu_book_outlined,
                    label: 'العقيدة الواسطية',
                    color: NavColors.deepPurple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WasitiyyahScreen())),
                  ),
                  NavTileData(
                    icon: Icons.history_edu_rounded,
                    label: 'زاد المعاد',
                    color: NavColors.gold,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZadAlMaadScreen())),
                  ),
                  NavTileData(
                    icon: Icons.terrain_rounded,
                    label: 'مدارج السالكين',
                    color: NavColors.coral,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MadarijScreen())),
                  ),
                  NavTileData(
                    icon: Icons.volunteer_activism_outlined,
                    label: basicText('adab', _lang),
                    color: NavColors.pink,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdabScreen())),
                  ),
                  NavTileData(
                    icon: Icons.school_outlined,
                    label: 'منهج تعلم العربية',
                    color: NavColors.cyan,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArabicCurriculumScreen())),
                  ),
                  NavTileData(
                    icon: Icons.record_voice_over_outlined,
                    label: 'التجويد',
                    color: NavColors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TajweedScreen())),
                  ),
                  NavTileData(
                    icon: Icons.mosque_outlined,
                    label: 'إقامة الصلاة',
                    color: NavColors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahTrackerScreen())),
                  ),
                  NavTileData(
                    icon: Icons.podcasts_outlined,
                    label: 'كتب صوتية',
                    color: NavColors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioLibraryScreen())),
                  ),
                  NavTileData(
                    icon: Icons.access_time_outlined,
                    label: basicText('prayer_times', _lang),
                    color: NavColors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
                  ),
                  NavTileData(
                    icon: Icons.explore_outlined,
                    label: basicText('qibla', _lang),
                    color: NavColors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen())),
                  ),
                  NavTileData(
                    icon: Icons.nights_stay_outlined,
                    label: basicText('adhkar', _lang),
                    color: NavColors.indigo,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdhkarScreen())),
                  ),
                  NavTileData(
                    icon: Icons.checklist_rtl_outlined,
                    label: basicText('wird', _lang),
                    color: NavColors.gold,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WirdScreen())),
                  ),
                  NavTileData(
                    icon: Icons.diversity_3_outlined,
                    label: basicText('new_muslim_guide', _lang),
                    color: NavColors.pink,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewMuslimGuideScreen())),
                  ),
                  NavTileData(
                    icon: Icons.support_agent_rounded,
                    label: basicText('support_faq', _lang),
                    color: NavColors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                  ),
                ]),
              ],
            ),
    );
  }
}
