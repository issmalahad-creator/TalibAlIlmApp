import 'package:flutter/material.dart';

import '../repositories/zad_almaad_repository.dart';
import '../theme/app_theme.dart';

class ZadAlMaadChapterScreen extends StatefulWidget {
  final ZadAlMaadChapter chapter;
  const ZadAlMaadChapterScreen({super.key, required this.chapter});

  @override
  State<ZadAlMaadChapterScreen> createState() => _ZadAlMaadChapterScreenState();
}

class _ZadAlMaadChapterScreenState extends State<ZadAlMaadChapterScreen> {
  final _repo = ZadAlMaadRepository();
  late bool _readDone;

  @override
  void initState() {
    super.initState();
    _readDone = widget.chapter.readDone;
  }

  Future<void> _markRead() async {
    await _repo.markRead(widget.chapter.id);
    setState(() => _readDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    return Scaffold(
      appBar: AppBar(title: Text(c.title, style: const TextStyle(fontSize: 15))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!c.hasUthaymeenCommentary)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'نص ابن القيم الأصلي — تعليق ابن عثيمين على هذا الفصل لم يُضَف بعد',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ),
          Text(c.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, height: 1.9)),
          const SizedBox(height: 20),
          if (!_readDone)
            FilledButton.icon(onPressed: _markRead, icon: const Icon(Icons.check), label: const Text('قرأته'))
          else
            const Text('قرأت هذا الفصل 🌱', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
