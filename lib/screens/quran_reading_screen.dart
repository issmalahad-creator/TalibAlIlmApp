import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quran_surahs.dart';
import '../repositories/quran_reading_repository.dart';
import '../repositories/quran_search_repository.dart';
import '../theme/app_theme.dart';
import 'journey_screen.dart';
import 'quran_browse_screen.dart';
import 'quran_search_screen.dart';
import '../widgets/loading_view.dart';

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

  /// The currently tapped ayah — highlighted (per-line background, matching
  /// the reference app's boxed-highlight look) while its context menu is
  /// open, cleared once it closes. Ismail's 2026-08-16 "طبق الأصل" request.
  int? _selectedSurah;
  int? _selectedAyah;
  final List<TapGestureRecognizer> _recognizers = [];

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
    for (final r in _recognizers) {
      r.dispose();
    }
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

  /// نقطة تنقّل سريعة ثانية (أماكن أخرى غير الفهرس): اضغط رقم الصفحة في
  /// الأعلى لقفزة مباشرة، بلا فتح ورقة الفهرس الكاملة.
  Future<void> _quickPageJumpDialog() async {
    final ctrl = TextEditingController(text: '$_page');
    final page = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اذهب إلى صفحة'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: const InputDecoration(hintText: '1-604'),
          onSubmitted: (v) {
            final p = int.tryParse(v);
            if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(ctrl.text);
              if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
            },
            child: const Text('اذهب'),
          ),
        ],
      ),
    );
    if (page != null) _goToPage(page);
  }

  void _openJourney() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const JourneyScreen()));
  }

  void _notAvailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$feature" لا يوجد لها مصدر بيانات موثوق بعد — لم تُضَف حتى لا نخترعها')),
    );
  }

  /// "الفهرس" — تنقّل عبر 3 طرق (Ismail's request 2026-08-16: "أريد
  /// التنقل بين صفحات القرآن وليس السور فقط... من الفهرس ومن أماكن
  /// أخرى"): السور (الأصلي)، الأجزاء (جديد — نفس الفكرة كثيرًا ما تُستخدم
  /// في المصحف الورقي الحقيقي لتصفح الأجزاء)، ورقم صفحة مباشر (جديد —
  /// أسرع طريق لصفحة معيّنة إن كان الطالب يعرف رقمها).
  Future<void> _openIndex() async {
    final pageCtrl = TextEditingController();
    final page = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DefaultTabController(
        length: 3,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (context, scrollController) => Column(
            children: [
              const Padding(padding: EdgeInsets.all(14), child: Text('الفهرس', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
              const TabBar(tabs: [Tab(text: 'السور'), Tab(text: 'الأجزاء'), Tab(text: 'رقم الصفحة')]),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView.builder(
                      controller: scrollController,
                      itemCount: quranSurahs.length,
                      itemBuilder: (context, i) {
                        final s = quranSurahs[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text('${s.number}', style: const TextStyle(fontSize: 10, color: AppColors.primaryDark))),
                          title: Text(s.name),
                          onTap: () async {
                            final p = await _repo.firstPageOfSurah(s.number);
                            if (context.mounted) Navigator.pop(context, p);
                          },
                        );
                      },
                    ),
                    ListView.builder(
                      itemCount: 30,
                      itemBuilder: (context, i) {
                        final juz = i + 1;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryLight, child: Text('$juz', style: const TextStyle(fontSize: 10, color: AppColors.primaryDark))),
                          title: Text('الجزء $juz'),
                          onTap: () async {
                            final p = await _repo.firstPageOfJuz(juz);
                            if (context.mounted) Navigator.pop(context, p);
                          },
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('المصحف 604 صفحة — اكتب رقم الصفحة التي تريدها', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: pageCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(hintText: 'مثال: 250', border: OutlineInputBorder()),
                            onSubmitted: (v) {
                              final p = int.tryParse(v);
                              if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              final p = int.tryParse(pageCtrl.text);
                              if (p != null && p >= 1 && p <= 604) Navigator.pop(context, p);
                            },
                            child: const Text('اذهب'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('حدّد ما حفظته من هذه الصفحة'),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _openBrowseForCurrentPage());
                },
              ),
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: const Text('رحلتي ومدرب الحفظ'),
                subtitle: const Text('خطتك، تكليف اليوم، ووتيرتك المتكيفة', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) => _openJourney());
                },
              ),
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
    setState(() {
      _selectedSurah = a.surah;
      _selectedAyah = a.ayah;
    });
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
    if (!mounted) return;
    setState(() {
      _selectedSurah = null;
      _selectedAyah = null;
    });
    if (selected == null) return;
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

  /// Builds the page as continuously-flowing paragraphs (one per surah
  /// segment present on the page) instead of one isolated block per ayah —
  /// this is the actual visual difference from a real printed Mushaf page
  /// Ismail flagged ("طبق الأصل"): ayat wrap naturally into dense lines
  /// rather than each starting its own paragraph. True line-for-line
  /// replication of the official Madinah Mushaf's exact 15-lines-per-page
  /// breaks would need that print's own line-break dataset, which isn't
  /// sourced into this app — flagged here rather than faked; this gets the
  /// visual density and flow right without it.
  List<Widget> _buildContent(Color themeColor, Color textColor) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final widgets = <Widget>[];
    var currentSpans = <InlineSpan>[];
    void flush() {
      if (currentSpans.isEmpty) return;
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text.rich(TextSpan(children: currentSpans), textAlign: TextAlign.right, textDirection: TextDirection.rtl),
      ));
      currentSpans = [];
    }

    for (final a in _ayat) {
      if (a.ayah == 1) {
        flush();
        widgets.add(_SurahBanner(name: _surahNames[a.surah] ?? '${a.surah}', color: themeColor));
      }
      final isSelected = _selectedSurah == a.surah && _selectedAyah == a.ayah;
      final recognizer = TapGestureRecognizer()..onTapDown = (details) => _onAyahTap(a, details);
      _recognizers.add(recognizer);
      currentSpans.add(TextSpan(
        text: '${a.text} ',
        recognizer: recognizer,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 21,
          height: 2.3,
          color: textColor,
          backgroundColor: isSelected ? themeColor.withValues(alpha: 0.18) : null,
        ),
      ));
      currentSpans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _AyahMedallion(number: a.ayah, color: themeColor, litUp: isSelected),
        ),
      ));
      currentSpans.add(const TextSpan(text: '  '));

      if (_showTafsir) {
        final tafsir = _tafsirByAyah['${a.surah}:${a.ayah}'];
        if (tafsir != null && tafsir.trim().isNotEmpty) {
          flush();
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _nightMode ? const Color(0xFF1E1E1E) : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.divider)),
              child: Text(tafsir, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, height: 1.7, color: textColor)),
            ),
          ));
        }
      }
    }
    flush();
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _themeColors[_themeKey]!.$1;
    final bgColor = _nightMode ? const Color(0xFF121212) : const Color(0xFFFBF6EE);
    final textColor = _nightMode ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 64,
        title: GestureDetector(
          onTap: _quickPageJumpDialog,
          child: _ayat.isEmpty
              ? Text('صفحة $_page')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RibbonBadge(text: 'سورة ${_surahNames[_ayat.first.surah] ?? _ayat.first.surah}', color: themeColor),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RibbonBadge(text: 'الجزء ${_ayat.first.juzNumber ?? '-'}  ·  الصفحة $_page', color: themeColor, small: true),
                        const SizedBox(width: 4),
                        const Icon(Icons.unfold_more_rounded, size: 13, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), tooltip: 'البحث في القرآن', onPressed: _openSearch),
          IconButton(icon: const Icon(Icons.menu_rounded), tooltip: 'طريقة عرض المصحف', onPressed: _openDisplayOptionsSheet),
        ],
      ),
      body: _loading
          ? const AppLoadingView(icon: Icons.menu_book_outlined, message: 'جاري تحميل صفحة المصحف...')
          : Column(
              children: [
                InkWell(
                  onTap: _openJourney,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: AppColors.primaryLight,
                    child: Row(
                      children: [
                        const Icon(Icons.route_outlined, size: 16, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('رحلتي ومدرب الحفظ — تكليف اليوم ووتيرتك المتكيفة', style: TextStyle(fontSize: 11.5, color: AppColors.primaryDark, fontWeight: FontWeight.w700))),
                        const Icon(Icons.chevron_left, size: 16, color: AppColors.primaryDark),
                      ],
                    ),
                  ),
                ),
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
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                    child: CustomPaint(
                      foregroundPainter: _MushafFramePainter(color: themeColor),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ..._buildContent(themeColor, textColor),
                              const SizedBox(height: 6),
                              Center(child: _PageNumberCartouche(page: _page, color: themeColor)),
                            ],
                          ),
                        ),
                      ),
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

String _easternArabicDigits(int n) {
  const western = '0123456789';
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) {
    final i = western.indexOf(c);
    return i == -1 ? c : eastern[i];
  }).join();
}

/// Original ornamental ayah-number marker — a small circle ringed with
/// petal-like bumps, drawn from scratch with `CustomPainter` (not traced
/// from any Mushaf font's glyph artwork) — replaces the plain "﴿30﴾"
/// bracket-number the reading screen used before Ismail's 2026-08-16 "طبق
/// الأصل" request for a page that looks like an actual printed Mushaf.
class _AyahMedallion extends StatelessWidget {
  final int number;
  final Color color;
  final bool litUp;
  const _AyahMedallion({required this.number, required this.color, required this.litUp});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _MedallionPainter(color: litUp ? color : color.withValues(alpha: 0.7)),
        child: Center(
          child: Text(_easternArabicDigits(number), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  final Color color;
  const _MedallionPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = color;
    const petals = 8;
    for (var i = 0; i < petals; i++) {
      final angle = (i / petals) * 2 * pi;
      final bumpCenter = Offset(center.dx + r * 0.8 * cos(angle), center.dy + r * 0.8 * sin(angle));
      canvas.drawCircle(bumpCenter, r * 0.3, ringPaint);
    }
    canvas.drawCircle(center, r * 0.68, Paint()..color = color.withValues(alpha: 0.1));
    canvas.drawCircle(center, r * 0.68, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter oldDelegate) => oldDelegate.color != color;
}

/// Hexagonal ribbon-shaped badge (pointed left/right ends via `ClipPath`) —
/// used for the surah-name/juz-page header pills and the in-page surah
/// banner, echoing the reference app's ornate banner shapes with original
/// geometry rather than a copied asset.
class _RibbonBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool small;
  final bool large;
  const _RibbonBadge({required this.text, required this.color, this.small = false, this.large = false});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _RibbonClipper(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: large ? 24 : 16, vertical: large ? 9 : 5),
        color: color.withValues(alpha: 0.12),
        child: Text(text, style: TextStyle(fontSize: large ? 14 : (small ? 10.5 : 13), fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  const _RibbonClipper();

  @override
  Path getClip(Size size) {
    final notch = size.height * 0.28;
    return Path()
      ..moveTo(notch, 0)
      ..lineTo(size.width - notch, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width - notch, size.height)
      ..lineTo(notch, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SurahBanner extends StatelessWidget {
  final String name;
  final Color color;
  const _SurahBanner({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(child: _RibbonBadge(text: 'سورة $name', color: color, large: true)),
    );
  }
}

/// Double-ring page-number cartouche at the bottom of the page frame —
/// echoes the reference's ornate page-number circle at the page foot.
class _PageNumberCartouche extends StatelessWidget {
  final int page;
  final Color color;
  const _PageNumberCartouche({required this.page, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.3)),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5), width: 1)),
        child: Text(_easternArabicDigits(page), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}

/// Decorative double-line page border with small corner flourishes,
/// painted as a `foregroundPainter` over the reading area — the frame
/// upgrade behind Ismail's "طبق الأصل" request, in the student's own
/// chosen "لون مصحفك" theme color rather than a fixed gold.
class _MushafFramePainter extends CustomPainter {
  final Color color;
  const _MushafFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, size.width - 6, size.height - 6), const Radius.circular(12));
    final inner = RRect.fromRectAndRadius(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), const Radius.circular(9));
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color,
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: 0.7),
    );
    final diamondPaint = Paint()..color = color;
    for (final corner in [
      const Offset(3, 3),
      Offset(size.width - 3, 3),
      Offset(3, size.height - 3),
      Offset(size.width - 3, size.height - 3),
    ]) {
      final path = Path()
        ..moveTo(corner.dx, corner.dy - 5)
        ..lineTo(corner.dx + 5, corner.dy)
        ..lineTo(corner.dx, corner.dy + 5)
        ..lineTo(corner.dx - 5, corner.dy)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MushafFramePainter oldDelegate) => oldDelegate.color != color;
}
