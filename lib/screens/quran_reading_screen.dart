import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../repositories/quran_reading_repository.dart';
import '../theme/app_theme.dart';

/// "قراءة القرآن" — QURAN_COMPANION_ROADMAP.md section 4.15. Page-by-page
/// reading, separate from memorization. Position auto-saves when leaving
/// this screen (`dispose`) or when the app is backgrounded while on it
/// (`didChangeAppLifecycleState`, scoped to this screen only, per Ismail's
/// explicit "الخروج من الشاشة يكفي" — not a global app-level observer).
class QuranReadingScreen extends StatefulWidget {
  const QuranReadingScreen({super.key});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> with WidgetsBindingObserver {
  final _repo = QuranReadingRepository();
  static final _surahNames = {for (final s in quranSurahs) s.number: s.name};

  int _page = 1;
  List<QuranAyahText> _ayat = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _repo.savePosition(_page);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _repo.savePosition(_page);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final page = await _repo.lastPage();
    final ayat = await _repo.ayatForPage(page);
    if (!mounted) return;
    setState(() {
      _page = page;
      _ayat = ayat;
      _loading = false;
    });
  }

  Future<void> _goToPage(int page) async {
    if (page < 1) return;
    if (page > 604) {
      await _repo.completeKhatmAndRestart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بارك الله فيك — ختمت القرآن 🎉 نبدأ ختمة جديدة')));
      page = 1;
    }
    await _repo.savePosition(page);
    final ayat = await _repo.ayatForPage(page);
    if (!mounted) return;
    setState(() {
      _page = page;
      _ayat = ayat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('صفحة $_page')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ayat.length,
                    itemBuilder: (context, i) {
                      final a = _ayat[i];
                      final isFirstOfSurah = a.ayah == 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isFirstOfSurah)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'سورة ${_surahNames[a.surah] ?? a.surah}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                ),
                              ),
                            Text('${a.text} ﴿${a.ayah}﴾', textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 2.1)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => _goToPage(_page + 1), child: const Text('الصفحة التالية'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton(onPressed: () => _goToPage(_page - 1), child: const Text('الصفحة السابقة'))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
