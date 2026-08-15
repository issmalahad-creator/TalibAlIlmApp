import 'package:flutter/material.dart';

import '../models/student_profile.dart';
import '../repositories/profile_repository.dart';
import 'hifz_teacher_screen.dart';
import 'support_screen.dart';

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
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen())),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('الدعم والأسئلة الشائعة'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HifzTeacherScreen())),
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('أستاذ التحفيظ'),
                ),
              ],
            ),
    );
  }
}
