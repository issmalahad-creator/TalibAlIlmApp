import 'package:flutter/material.dart';

import '../repositories/madarij_repository.dart';
import '../theme/app_theme.dart';

class MadarijChapterScreen extends StatefulWidget {
  final MadarijSection section;
  const MadarijChapterScreen({super.key, required this.section});

  @override
  State<MadarijChapterScreen> createState() => _MadarijChapterScreenState();
}

class _MadarijChapterScreenState extends State<MadarijChapterScreen> {
  final _repo = MadarijRepository();
  late bool _readDone;

  @override
  void initState() {
    super.initState();
    _readDone = widget.section.readDone;
  }

  Future<void> _markRead() async {
    await _repo.markRead(widget.section.id);
    setState(() => _readDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return Scaffold(
      appBar: AppBar(title: Text(s.title, style: const TextStyle(fontSize: 14))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, height: 1.9)),
          const SizedBox(height: 20),
          if (!_readDone)
            FilledButton.icon(onPressed: _markRead, icon: const Icon(Icons.check), label: const Text('قرأته'))
          else
            const Text('قرأت هذا المقطع 🌱', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
