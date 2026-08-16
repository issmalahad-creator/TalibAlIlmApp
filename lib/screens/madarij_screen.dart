import 'package:flutter/material.dart';

import '../repositories/madarij_repository.dart';
import '../theme/app_theme.dart';
import 'madarij_chapter_screen.dart';
import '../widgets/loading_view.dart';

/// "مدارج السالكين" — Phase 5ح of QURAN_COMPANION_ROADMAP.md. **المستوى
/// المتقدم فقط** — أعمق نص بالتطبيق كله، والتحذير أعلى الشاشة ليس نصًا
/// شكليًا، هو الضمانة الوحيدة حاليًا (لا يوجد نظام قفل مستويات تقني بعد).
class MadarijScreen extends StatefulWidget {
  const MadarijScreen({super.key});

  @override
  State<MadarijScreen> createState() => _MadarijScreenState();
}

class _MadarijScreenState extends State<MadarijScreen> {
  final _repo = MadarijRepository();
  List<MadarijSection> _sections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sections = await _repo.all();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final readCount = _sections.where((s) => s.readDone).length;
    return Scaffold(
      appBar: AppBar(title: const Text('مدارج السالكين')),
      body: _loading
          ? const AppLoadingView(icon: Icons.hourglass_empty_rounded, message: 'جاري التحميل...')
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    'مستوى متقدم — يُنصح بإتقان العقيدة والفقه الأساسيين أولًا قبل هذا الكتاب. لا يوجد قفل إجباري، القرار لك.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.6),
                  ),
                ),
                Text('$readCount من ${_sections.length} مقطعًا — الجزء الأول، وبقية الأجزاء تُضاف تباعًا',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sections.length,
                    itemBuilder: (context, i) {
                      final s = _sections[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          s.readDone ? Icons.check_circle : Icons.circle_outlined,
                          color: s.readDone ? AppColors.primary : AppColors.textMuted,
                          size: 20,
                        ),
                        title: Text(s.title, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => MadarijChapterScreen(section: s)));
                          _load();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
