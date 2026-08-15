import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quran_surahs.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_search_repository.dart';
import '../theme/app_theme.dart';
import 'quran_browse_screen.dart';
import 'quran_search_screen.dart';

const _themeColors = {
  'brown': (Color(0xFF8B5E34), 'بنّي'),
  'teal': (AppColors.primary, 'أخضر'),
  'blue': (Color(0xFF2F80ED), 'أزرق'),
  'red': (Color(0xFFB33951), 'أحمر'),
  'purple': (Color(0xFF6A4C93), 'بنفسجي'),
};

/// "القرآن" hub — QURAN_COMPANION_ROADMAP.md section 4.15, expanded
/// 2026-08-16 per Ismail's explicit request ("اجعل كل متعلقات القرآن في
/// مكان وداخل ايقونة واحدة" — gather everything Quran-related into one
/// place behind one icon) and a reference app's tap-an-ayah context menu
/// + "طريقة عرض المصحف" options sheet he asked to be matched. Page-by-page
/// reading is still the core (position auto-saves on leaving this screen
/// or backgrounding the app while on it, per Ismail's "الخروج من الشاشة
/// يكفي"). Tapping any ayah opens a floating menu right there (تفسير /
/// مفضلة / نشر — real features) alongside الترجمة/الاستماع/المعاني, which
/// stay visibly present but disabled with an honest "لا يوجد مصدر بيانات
/// بعد" — neither translation text nor a licensed per-ayah audio source
/// nor a word-by-word gloss corpus has been sourced into this app yet,
/// and faking any of them would violate this project's sourcing
/// discipline; they're flagged as real follow-up work, not silently
/// dropped or invented.
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
  bool _nightMode = false;
  String _themeKey = 'brown';

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

  Future<void> _openSearch() async {
    final page = await Navigator.push<int>(context, MaterialPageRoute(builder: (_) => const QuranSearchScreen()));
    if (page != null) _goToPage(page);
  }

  void _openBrowseForCurrentPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuranBrowseScreen(highlightUnitId: _page)));
  }

  void _notAvailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$feature" لا يوجد لها مصدر بيانات موثوق بعد — لم تُضَف حتى لا نخترعها')),
    );
  }

  Future<void> _openIndex() async {
    final surah = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(14), child: Text('الفهرس', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: quranSurahs.length,
                itemBuilder: (context, i) {
                  final s = quranSurahs[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text('${s.number}', style: const TextStyle(fontSize: 10, color: AppColors.primaryDark))),
                    title: Text(s.name),
                    onTap: () => Navigator.pop(context, s.number),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (surah == null) return;
    final page = await _repo.firstPageOfSurah(surah);
    if (page != null) _goToPage(page);
  }

  Future<void> _openFavorites() async {
    final favorites = await _repo.favoriteAyahs();
    if (!mounted) return;
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(14), child: Text('المفضلة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
            if (favorites.isEmpty) const Expanded(child: Center(child: Text('لم تُضِف أي آية للمفضلة بعد', style: TextStyle(color: AppColors.textMuted))))
            else Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: favorites.length,
                itemBuilder: (context, i) {
                  final f = favorites[i];
                  return ListTile(
                    title: Text(f.text, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 16)),
                    subtitle: Text('سورة ${_surahNames[f.surah] ?? f.surah} — آية ${f.ayah}', textAlign: TextAlign.right),
                    onTap: () => Navigator.pop(context, f.pageNumber),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (page != null) _goToPage(page);
  }

  Future<void> _openDisplayOptionsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('طريقة عرض المصحف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ListTile(leading: const Icon(Icons.list_alt_outlined), title: const Text('الفهرس'), onTap: () { Navigator.pop(context); _openIndex(); }),
              ListTile(leading: const Icon(Icons.search_rounded), title: const Text('البحث'), onTap: () { Navigator.pop(context); _openSearch(); }),
              ListTile(leading: const Icon(Icons.check_circle_outline), title: const Text('حدّد ما حفظته من هذه الصفحة'), onTap: () { Navigator.pop(context); _openBrowseForCurrentPage(); }),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.menu_book_outlined),
                title: const Text('التفسير'),
                value: _showTafsir,
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _showTafsir = v);
                  if (v) _loadTafsir();
                },
              ),
              ListTile(leading: const Icon(Icons.list, color: AppColors.textMuted), title: const Text('المعاني', style: TextStyle(color: AppColors.textMuted)), onTap: () => _notAvailable('المعاني')),
              ListTile(leading: const Icon(Icons.headphones_outlined, color: AppColors.textMuted), title: const Text('الصوتيات', style: TextStyle(color: AppColors.textMuted)), onTap: () => _notAvailable('الاستماع للآيات')),
              ListTile(leading: const Icon(Icons.translate_outlined, color: AppColors.textMuted), title: const Text('الترجمة', style: TextStyle(color: AppColors.textMuted)), onTap: () => _notAvailable('الترجمة')),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.nightlight_outlined),
                title: const Text('الوضع الليلي'),
                value: _nightMode,
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _nightMode = v);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Align(alignment: Alignment.centerRight, child: Text('لون مصحفك', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _themeColors.entries.map((e) {
                  final selected = _themeKey == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _themeKey = e.key);
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: e.value.$1,
                        child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(),
              ListTile(leading: const Icon(Icons.bookmark_outline), title: const Text('المفضلة'), onTap: () { Navigator.pop(context); _openFavorites(); }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAyahTap(QuranAyahText a, TapDownDetails details) async {
    final isFav = await _repo.isFavorite(a.surah, a.ayah);
    if (!mounted) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(value: 'tafsir', child: ListTile(leading: Icon(Icons.menu_book_outlined), title: Text('التفسير'), dense: true)),
        const PopupMenuItem(value: 'translation', child: ListTile(leading: Icon(Icons.translate_outlined, color: AppColors.textMuted), title: Text('الترجمة', style: TextStyle(color: AppColors.textMuted)), dense: true)),
        const PopupMenuItem(value: 'listen', child: ListTile(leading: Icon(Icons.headphones_outlined, color: AppColors.textMuted), title: Text('الاستماع للآية', style: TextStyle(color: AppColors.textMuted)), dense: true)),
        PopupMenuItem(value: 'favorite', child: ListTile(leading: Icon(isFav ? Icons.bookmark : Icons.bookmark_outline), title: Text(isFav ? 'إزالة من المفضلة' : 'أضف للمفضلة'), dense: true)),
        const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share_outlined), title: Text('نشر'), dense: true)),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case 'tafsir':
        final tafsir = await _repo.tafsirForAyah(a.surah, a.ayah, _tafsirSource);
        if (!mounted) return;
        await showModalBottomSheet(
          context: context,
          builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سورة ${_surahNames[a.surah] ?? a.surah} — آية ${a.ayah}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(tafsir ?? 'لا يوجد تفسير محفوظ لهذه الآية من هذا المصدر', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, height: 1.7)),
              ],
            ),
          ),
        );
        break;
      case 'translation':
        _notAvailable('الترجمة');
        break;
      case 'listen':
        _notAvailable('الاستماع للآية');
        break;
      case 'favorite':
        if (isFav) {
          await _repo.removeFavorite(a.surah, a.ayah);
        } else {
          await _repo.addFavorite(a.surah, a.ayah);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFav ? 'أُزيلت من المفضلة' : 'أُضيفت للمفضلة')));
        break;
      case 'share':
        await Share.share('${a.text} (${_surahNames[a.surah] ?? a.surah}: ${a.ayah})');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeColors[_themeKey]!.$1;
    final bgColor = _nightMode ? const Color(0xFF121212) : const Color(0xFFFBF6EE);
    final textColor = _nightMode ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('صفحة $_page'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), tooltip: 'البحث في القرآن', onPressed: _openSearch),
          IconButton(icon: const Icon(Icons.menu_rounded), tooltip: 'طريقة عرض المصحف', onPressed: _openDisplayOptionsSheet),
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
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(border: Border.all(color: themeColor, width: 2), borderRadius: BorderRadius.circular(14)),
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
                                    style: TextStyle(fontWeight: FontWeight.w800, color: themeColor),
                                  ),
                                ),
                              GestureDetector(
                                onTapDown: (details) => _onAyahTap(a, details),
                                child: Text('${a.text} ﴿${a.ayah}﴾', textAlign: TextAlign.right, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 2.1, color: textColor)),
                              ),
                              if (_showTafsir && tafsir != null && tafsir.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: _nightMode ? const Color(0xFF1E1E1E) : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
                                    child: Text(tafsir, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, height: 1.7, color: textColor)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
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
