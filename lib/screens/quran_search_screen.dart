import 'dart:async';

import 'package:flutter/material.dart';

import '../repositories/quran_search_repository.dart';
import '../theme/app_theme.dart';

/// "البحث عن آية" — Phase 1 of QURAN_COMPANION_ROADMAP.md. Search a word or
/// phrase (no tashkeel needed) and get every matching ayah in the Quran with
/// its surah name, or search "السورة رقم" (e.g. "البقرة 255") to jump
/// straight to one ayah.
class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final _repo = QuranSearchRepository();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<QuranSearchResult> _results = [];
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    setState(() => _searching = true);
    final results = await _repo.search(value);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث في القرآن')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              onChanged: _onChanged,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'اكتب كلمة، أو "السورة رقم الآية" مثل: البقرة 255',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'لا حاجة للتشكيل — البحث يعمل بالحروف العادية',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searching) return const Center(child: CircularProgressIndicator());
    if (!_hasSearched) {
      return const Center(
        child: Text('ابحث عن أي كلمة لتظهر كل الآيات التي وردت فيها', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('لم يُعثر على نتائج', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      itemCount: _results.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('${_results.length} نتيجة', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          );
        }
        final r = _results[i - 1];
        return _ResultCard(result: r);
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final QuranSearchResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'سورة ${result.surahName} — آية ${result.ayah}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                ),
              ),
              const Spacer(),
              if (result.pageNumber != null)
                Text('صفحة ${result.pageNumber}', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          // TODO(Phase 0 follow-up): no Uthmani-script font is bundled yet
          // (e.g. Amiri, SIL-licensed) — falls back to the system font for
          // now, which doesn't render Quranic glyphs/marks as cleanly.
          Text(
            result.textUthmani,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 17, height: 1.9),
          ),
          if (result.tafsir != null && result.tafsir!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('التفسير (ابن كثير)', style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark)),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      result.tafsir!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14, height: 1.7, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
