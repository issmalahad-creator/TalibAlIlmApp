import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_search_repository.dart';
import '../theme/app_theme.dart';
import 'quran_browse_screen.dart';
import 'quran_search_screen.dart';

/// "القرآن" hub — QURAN_COMPANION_ROADMAP.md section 4.15, expanded
/// 2026-08-16 per Ismail's explicit request ("اجعل كل متعلقات القرآن في
/// مكان وداخل ايقونة واحدة" — gather everything Quran-related into one
/// place behind one icon, instead of scattered separate screens/buttons).
/// Page-by-page reading is still the core (separate from memorization —
/// position auto-saves on leaving this screen or backgrounding the app
/// while on it, per Ismail's "الخروج من الشاشة يكفي"), with search and
/// tafsir now reachable from right here instead of requiring a trip
/// through the home screen. Translation display and per-ayah recitation
/// audio ("الترجمة"/"الاستماع" from the reference app Ismail described)
/// are NOT included yet — neither has real data sourced in this app yet
/// (translation text, and a licensed per-ayah audio source), and faking
/// either would violate this project's sourcing discipline; both are
/// flagged as real follow-up work, not silently dropped.
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
  bool _showTafsir = false;
  String _tafsirSource = QuranSearchRepository.defaultTafsirSource;
  Map<String, String> _tafsirByAyah = {};

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
    if (_showTafsir) _loadTafsir();
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
    if (_showTafsir) _loadTafsir();
  }

  Future<void> _loadTafsir() async {
    final tafsir = await _repo.tafsirForPage(_page, _tafsirSource);
    if (!mounted) return;
    setState(() => _tafsirByAyah = tafsir);
  }

  void _toggleTafsir() {
    setState(() => _showTafsir = !_showTafsir);
    if (_showTafsir) _loadTafsir();
  }

  Future<void> _openSearch() async {
    final page = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const QuranSearchScreen()));
    if (page != null) _goToPage(page);
  }

  void _openBrowseForCurrentPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuranBrowseScreen(highlightUnitId: _page)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة $_page'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), tooltip: 'البحث في القرآن', onPressed: _openSearch),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'tafsir') _toggleTafsir();
              if (v == 'mark') _openBrowseForCurrentPage();
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(value: 'tafsir', checked: _showTafsir, child: const Text('التفسير')),
              const PopupMenuItem(value: 'mark', child: Text('حدّد ما حفظته من هذه الصفحة')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showTafsir)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text('التفسير: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            isDense: true,
                            value: _tafsirSource,
                            underline: const SizedBox.shrink(),
                            items: QuranSearchRepository.tafsirSources
                                .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2, style: const TextStyle(fontSize: 12.5))))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _tafsirSource = v);
                              _loadTafsir();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ayat.length,
                    itemBuilder: (context, i) {
                      final a = _ayat[i];
                      final isFirstOfSurah = a.ayah == 1;
                      final tafsir = _tafsirByAyah['${a.surah}:${a.ayah}'];
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
                            if (_showTafsir && tafsir != null && tafsir.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                                  child: Text(tafsir, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, height: 1.7, color: AppColors.textDark)),
                                ),
                              ),
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
