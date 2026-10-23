import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/mushaf_layout_repository.dart';
import '../repositories/quran_search_repository.dart';
import '../widgets/mushaf/mushaf_chrome_style.dart';
import '../utils/digits.dart';

/// The reader's own search — by text («البقرة 255» or any words, no tashkeel)
/// or by number (page / juzʼ / ḥizb). Pops with the **MushafDatabase** page to
/// open: text hits go through `pageForReference(surah, ayah)`, never the
/// Tanzil `page_number` the search rows carry (ERRATA E-2).
class MushafSearchScreen extends StatefulWidget {
  final String lang;
  final bool night;
  const MushafSearchScreen({super.key, required this.lang, this.night = false});

  @override
  State<MushafSearchScreen> createState() => _MushafSearchScreenState();
}

class _NumberHit {
  final String label;
  final Future<int?> Function() page;
  _NumberHit(this.label, this.page);
}

class _MushafSearchScreenState extends State<MushafSearchScreen> {
  final _search = QuranSearchRepository();
  final _layout = MushafLayoutRepository();
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<QuranSearchResult> _results = const [];
  List<_NumberHit> _numbers = const [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  /// «١٢» or «12» → 12.
  static int? _number(String q) {
    final n = parseAnyDigits(q);
    return n != null && n < 1000 ? n : null;
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(v));
  }

  Future<void> _run(String v) async {
    final q = v.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _numbers = const [];
        _searched = false;
      });
      return;
    }
    final lang = widget.lang;
    final n = _number(q);
    if (n != null) {
      setState(() {
        _results = const [];
        _searched = true;
        _numbers = [
          if (n >= 1 && n <= 604)
            _NumberHit('${basicText('page_label', lang)} ${mushafDigits(n, lang)}', () async => n),
          if (n >= 1 && n <= 30)
            _NumberHit('${basicText('juz_label', lang)} $n', () => _layout.pageForJuz(n)),
          if (n >= 1 && n <= 60)
            _NumberHit('${basicText('hizb_label', lang)} $n', () => _layout.pageForHizb(n)),
        ];
      });
      return;
    }
    setState(() => _searching = true);
    final r = await _search.search(q);
    if (!mounted || _ctrl.text.trim() != q) return;
    setState(() {
      _results = r;
      _numbers = const [];
      _searching = false;
      _searched = true;
    });
  }

  Future<void> _open(Future<int?> Function() page) async {
    final p = await page();
    if (p != null && mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final night = widget.night;
    final fg = MushafChrome.fg(night);
    return Scaffold(
      backgroundColor: MushafChrome.bg(night),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: night ? Colors.black26 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MushafChrome.brownDark.withValues(alpha: 0.8)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        onChanged: _onChanged,
                        onSubmitted: _run,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(fontSize: 16, color: fg),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          hintText: basicText('mushaf_search_hint', lang),
                          hintStyle: TextStyle(color: fg.withValues(alpha: 0.45)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: Material(
                        color: night ? Colors.white10 : MushafChrome.tan,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _run(_ctrl.text),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.search_rounded,
                                color: night ? MushafChrome.gold : const Color(0xFF1F2A44)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              MushafSquareButton(
                  icon: mushafBackIcon(context), night: night, onTap: () => Navigator.pop(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Text(basicText('mushaf_search_results', lang),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
          ),
          Expanded(child: _body(lang, night, fg)),
        ]),
      ),
    );
  }

  Widget _body(String lang, bool night, Color fg) {
    if (_searching) return const Center(child: CircularProgressIndicator());
    if (!_searched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${basicText('mushaf_search_by', lang)}\n${basicText('mushaf_search_by_list', lang)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, height: 1.7, color: fg.withValues(alpha: 0.5)),
          ),
        ),
      );
    }
    if (_numbers.isEmpty && _results.isEmpty) {
      return Center(
          child: Text(basicText('no_results', lang),
              style: TextStyle(color: fg.withValues(alpha: 0.5))));
    }
    final rows = <Widget>[
      for (final h in _numbers)
        _tile(
          night: night,
          onTap: () => _open(h.page),
          child: Text(h.label,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: fg)),
        ),
      for (final r in _results)
        _tile(
          night: night,
          onTap: () => _open(() => _layout.pageForReference(r.surah, ayah: r.ayah)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${basicText('surah_word', lang)} ${r.surahName} · ${r.ayah}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: MushafChrome.gold)),
            const SizedBox(height: 6),
            Text(r.textUthmani,
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 19, height: 1.9, color: fg)),
          ]),
        ),
    ];
    return ListView(children: rows);
  }

  Widget _tile({required bool night, required VoidCallback onTap, required Widget child}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: MushafChrome.line(night)))),
          child: Row(children: [
            Expanded(child: child),
            Icon(Icons.chevron_right_rounded, color: MushafChrome.fg(night).withValues(alpha: 0.5)),
          ]),
        ),
      );
}
