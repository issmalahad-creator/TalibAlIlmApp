import 'package:flutter/material.dart';

import '../data/quran_surahs.dart';
import '../l10n/basic_translations.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../repositories/mushaf_stats_repository.dart';
import '../services/language_preference_service.dart';
import '../services/mushaf_stats.dart';
import '../theme/app_theme.dart';
import 'mushaf_semantic_reader_screen.dart';

/// «إحصاءات المصحف» — what the muṣḥaf itself holds, for the whole of it or
/// any surah, juzʼ, ḥizb or page: ayat, words, letters, pages and lines, every
/// waqf sign by kind, the saktāt and sajdāt (each opens the muṣḥaf at its
/// place), and how often each letter occurs. Counted from the text, never
/// typed in (`lib/services/mushaf_stats.dart`); the definitions are shown,
/// because published counts differ by how they count.
class MushafStatsScreen extends StatefulWidget {
  final StatsScope initialScope;
  const MushafStatsScreen({super.key, this.initialScope = StatsScope.all});

  @override
  State<MushafStatsScreen> createState() => _MushafStatsScreenState();
}

class _MushafStatsScreenState extends State<MushafStatsScreen> {
  late StatsScope _scope = widget.initialScope;
  ScopedStats? _data;
  Object? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = ++_request;
    setState(() {
      _data = null;
      _error = null;
    });
    try {
      final d = await MushafStatsRepository.instance.stats(_scope);
      if (mounted && id == _request) setState(() => _data = d);
    } catch (e) {
      if (mounted && id == _request) setState(() => _error = e);
    }
  }

  void _setScope(StatsScope s) {
    _scope = s;
    _load();
  }

  static int _max(StatsScopeKind k) => switch (k) {
        StatsScopeKind.all => 0,
        StatsScopeKind.surah => 114,
        StatsScopeKind.juz => 30,
        StatsScopeKind.hizb => 60,
        StatsScopeKind.page => 604,
      };

  Future<void> _pickSurah(String lang) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView.builder(
        itemCount: quranSurahs.length,
        itemBuilder: (_, i) => ListTile(
          dense: true,
          leading: Text('${i + 1}'),
          title: Text(quranSurahs[i].name),
          trailing: Text('${quranSurahs[i].ayahCount}'),
          onTap: () => Navigator.pop(ctx, i + 1),
        ),
      ),
    );
    if (picked != null) _setScope(StatsScope(StatsScopeKind.surah, picked));
  }

  Future<void> _openAt(AyahRef r) async {
    final page = await MushafLayoutRepository().pageForAyah(r.surah, r.ayah);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => MushafSemanticReaderScreen(initialPage: page, focusAyah: (surah: r.surah, ayah: r.ayah))));
  }

  String _ref(AyahRef r) => '${quranSurahs[r.surah - 1].name} ${r.ayah}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) {
        String t(String k) => basicText(k, lang);
        return Scaffold(
          appBar: AppBar(title: Text(t('ms_title'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (final k in StatsScopeKind.values)
                  ChoiceChip(
                    label: Text(t('ms_scope_${k.name}')),
                    selected: _scope.kind == k,
                    onSelected: (_) {
                      if (k == StatsScopeKind.surah) {
                        _pickSurah(lang);
                      } else {
                        _setScope(StatsScope(k, k == StatsScopeKind.all ? 0 : 1));
                      }
                    },
                  ),
              ]),
              if (_scope.kind != StatsScopeKind.all) _ScopeStepper(
                label: _scope.kind == StatsScopeKind.surah ? quranSurahs[_scope.value - 1].name : '${t('ms_scope_${_scope.kind.name}')} ${_scope.value}',
                canBack: _scope.value > 1,
                canForward: _scope.value < _max(_scope.kind),
                onBack: () => _setScope(StatsScope(_scope.kind, _scope.value - 1)),
                onForward: () => _setScope(StatsScope(_scope.kind, _scope.value + 1)),
                onTap: _scope.kind == StatsScopeKind.surah ? () => _pickSurah(lang) : null,
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(padding: const EdgeInsets.all(24), child: Text(t('ms_error'), textAlign: TextAlign.center))
              else if (_data == null)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(t('ms_counting'), style: const TextStyle(color: AppColors.textMuted)),
                  ]),
                )
              else
                ..._results(_data!, t),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _results(ScopedStats d, String Function(String) t) {
    final s = d.stats;
    return [
      Text('${t('ms_from')} ${_ref(d.first)} ${t('ms_to')} ${_ref(d.last)}',
          textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.25,
        children: [
          _Tile(t('ms_ayat'), s.ayat),
          _Tile(t('ms_words'), s.words),
          _Tile(t('ms_letters'), s.letters),
          _Tile(t('ms_pages'), d.pages),
          _Tile(t('ms_lines'), d.lines),
          _Tile(t('ms_waqf_total'), s.waqfTotal),
        ],
      ),
      const SizedBox(height: 20),
      _Header(t('ms_waqf_title')),
      Card(
        child: Column(children: [
          for (final k in WaqfKind.values)
            ListTile(
              dense: true,
              leading: SizedBox(
                width: 36,
                child: Text(k.mark, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 26, color: AppColors.primaryDark, height: 1.6)),
              ),
              title: Text(t('ms_waqf_${k.name}')),
              subtitle: Text(t('ms_waqf_${k.name}_desc'), style: const TextStyle(fontSize: 12)),
              trailing: Text('${s.waqf[k]}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      _Header('${t('ms_saktat')} (${s.saktat.length})'),
      _RefChips(refs: s.saktat, label: _ref, onTap: _openAt, empty: t('ms_none_here')),
      const SizedBox(height: 16),
      _Header('${t('ms_sajdat')} (${s.sajdat.length})'),
      _RefChips(refs: s.sajdat, label: _ref, onTap: _openAt, empty: t('ms_none_here')),
      const SizedBox(height: 8),
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(t('ms_letter_freq'), style: const TextStyle(fontWeight: FontWeight.w700)),
          children: [
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in s.letterFrequency)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                  child: Text('${e.key}  ${e.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(t('ms_definitions'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    ];
  }
}

class _ScopeStepper extends StatelessWidget {
  final String label;
  final bool canBack;
  final bool canForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback? onTap;
  const _ScopeStepper({required this.label, required this.canBack, required this.canForward, required this.onBack, required this.onForward, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          IconButton(onPressed: canBack ? onBack : null, icon: const Icon(Icons.chevron_right_rounded)),
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          IconButton(onPressed: canForward ? onForward : null, icon: const Icon(Icons.chevron_left_rounded)),
        ]),
      );
}

class _Tile extends StatelessWidget {
  final String label;
  final int value;
  const _Tile(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FittedBox(child: Text(_group(value), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        ]),
      );

  /// 327514 → 327,514
  static String _group(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _RefChips extends StatelessWidget {
  final List<AyahRef> refs;
  final String Function(AyahRef) label;
  final void Function(AyahRef) onTap;
  final String empty;
  const _RefChips({required this.refs, required this.label, required this.onTap, required this.empty});

  @override
  Widget build(BuildContext context) => refs.isEmpty
      ? Text(empty, style: const TextStyle(color: AppColors.textMuted))
      : Wrap(spacing: 6, runSpacing: 6, children: [
          for (final r in refs) ActionChip(avatar: const Icon(Icons.menu_book_outlined, size: 16), label: Text(label(r)), onPressed: () => onTap(r)),
        ]);
}
