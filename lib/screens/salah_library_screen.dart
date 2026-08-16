import 'package:flutter/material.dart';

import '../data/salah_content.dart';
import '../repositories/salah_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_view.dart';

/// Curated lesson library for "إقامة الصلاة" — browsable by category,
/// mark-as-read tracking (reading/reflection material, no quiz — same
/// pattern as Zad al-Ma'ad/Madarij elsewhere in this app).
class SalahLibraryScreen extends StatefulWidget {
  const SalahLibraryScreen({super.key});

  @override
  State<SalahLibraryScreen> createState() => _SalahLibraryScreenState();
}

class _SalahLibraryScreenState extends State<SalahLibraryScreen> {
  final _repo = SalahRepository();
  Set<String> _read = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final read = await _repo.readLessonKeys();
    if (!mounted) return;
    setState(() {
      _read = read;
      _loading = false;
    });
  }

  Future<void> _toggle(String key) async {
    if (_read.contains(key)) return;
    await _repo.markLessonRead(key);
    setState(() => _read = {..._read, key});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة إقامة الصلاة')),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final category in salahLibrary) ...[
                  Text(category.titleAr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ...category.lessons.map((lesson) {
                    final key = '${category.key}_${lesson.titleAr}';
                    final isRead = _read.contains(key);
                    return InkWell(
                      onTap: () => _toggle(key),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isRead ? AppColors.primary : AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(lesson.titleAr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                                Icon(isRead ? Icons.check_circle : Icons.circle_outlined, size: 18, color: isRead ? AppColors.primary : AppColors.textMuted),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(lesson.bodyAr, style: const TextStyle(fontSize: 13, height: 1.7)),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ],
            ),
    );
  }
}
