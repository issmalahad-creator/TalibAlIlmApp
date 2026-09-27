import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/basic_translations.dart';
import '../models/student_profile.dart';
import '../repositories/profile_repository.dart';
import '../services/calendar_preference_service.dart';
import '../services/language_preference_service.dart';
import '../services/text_scale_preference_service.dart';
import '../theme/app_theme.dart';
import '../widgets/feedback/talib_action_button.dart';
import '../widgets/nav_tile.dart';
import '../widgets/restart_widget.dart';
import 'adab_screen.dart';
import 'adhkar_screen.dart';
import 'arabic_curriculum_screen.dart';
import 'hadith_screen.dart';
import 'new_muslim_guide_screen.dart';
import 'downloads_screen.dart';
import 'notification_settings_screen.dart';
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
  final String _lang = LanguagePreferenceService.currentLanguage;
  double _textScale = TextScalePreferenceService.scaleNotifier.value;

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(basicText('saved_confirmation', _lang))));
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
      appBar: AppBar(title: Text(basicText('nav_profile', _lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_progress', _lang))
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
                        child: Text(
                          basicText(_photoPath == null ? 'add_certificate_photo' : 'change_certificate_photo', _lang),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: basicText('full_name_label', _lang), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _residenceCtrl,
                  decoration: InputDecoration(labelText: basicText('residence_label', _lang), border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _studyTrack,
                  decoration: InputDecoration(labelText: basicText('study_track_label', _lang), border: const OutlineInputBorder()),
                  items: StudentProfile.studyTracks
                      .map((track) => DropdownMenuItem(value: track, child: Text(track)))
                      .toList(),
                  onChanged: (v) => setState(() => _studyTrack = v ?? _studyTrack),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _studySourceCtrl,
                  decoration: InputDecoration(
                    labelText: basicText('study_source_label', _lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                TalibActionButton(
                  onPressed: _save,
                  icon: Icons.save,
                  label: basicText('save', _lang),
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
                    title: Text(basicText('gregorian_toggle_title', _lang), style: const TextStyle(fontSize: 13.5)),
                    subtitle: Text(basicText('gregorian_toggle_subtitle', _lang), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
                      Text(basicText('basic_titles_language_label', _lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      Text(
                        basicText('basic_titles_language_desc', _lang),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _lang,
                        items: supportedLanguages.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        // 2026-08-17 ("نفس الوندوز"): was just `setState(() =>
                        // _lang = v)` — updated this screen's own labels but
                        // left every other already-mounted screen (which may
                        // read the language into its own local `State` field
                        // just like this one used to) showing whatever
                        // language was current when THEY were built. A full
                        // restart makes every screen remount fresh instead.
                        onChanged: (v) async {
                          if (v == null) return;
                          await LanguagePreferenceService.setLanguage(v);
                          if (!context.mounted) return;
                          RestartWidget.restartApp(context);
                        },
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(basicText('font_size_label', _lang), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: TextScalePreferenceService.presets
                            .map((scale) => ChoiceChip(
                                  label: Text(TextScalePreferenceService.presetLabels[scale]!),
                                  selected: _textScale == scale,
                                  onSelected: (_) async {
                                    await TextScalePreferenceService.setScale(scale);
                                    setState(() => _textScale = scale);
                                  },
                                ))
                            .toList(),
                      ),
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
                    label: basicText('teacher_hifz', _lang),
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
                    label: basicText('time_accountability', _lang),
                    color: NavColors.coral,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeAwarenessScreen())),
                  ),
                  NavTileData(
                    icon: Icons.format_quote_rounded,
                    label: basicText('hadith_arbaeen', _lang),
                    color: NavColors.brown,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HadithScreen())),
                  ),
                  NavTileData(
                    icon: Icons.menu_book_outlined,
                    label: basicText('aqeedah_wasitiyyah', _lang),
                    color: NavColors.deepPurple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WasitiyyahScreen())),
                  ),
                  NavTileData(
                    icon: Icons.history_edu_rounded,
                    label: basicText('zad_almaad', _lang),
                    color: NavColors.gold,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ZadAlMaadScreen())),
                  ),
                  NavTileData(
                    icon: Icons.terrain_rounded,
                    label: basicText('madarij_salikeen', _lang),
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
                    label: basicText('arabic_curriculum', _lang),
                    color: NavColors.cyan,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArabicCurriculumScreen())),
                  ),
                  NavTileData(
                    icon: Icons.record_voice_over_outlined,
                    label: basicText('tajweed', _lang),
                    color: NavColors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TajweedScreen())),
                  ),
                  NavTileData(
                    icon: Icons.mosque_outlined,
                    label: basicText('salah_companion', _lang),
                    color: NavColors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalahTrackerScreen())),
                  ),
                  NavTileData(
                    icon: Icons.podcasts_outlined,
                    label: basicText('audio_library', _lang),
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
                    icon: Icons.notifications_active_outlined,
                    label: basicText('notifications_title', _lang),
                    color: NavColors.cyan,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                  ),
                  NavTileData(
                    icon: Icons.download_for_offline_outlined,
                    label: basicText('downloads_title', _lang),
                    color: NavColors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())),
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
