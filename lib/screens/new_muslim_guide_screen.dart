import 'package:flutter/material.dart';

import '../data/new_muslim_guide.dart';
import '../repositories/guide_progress_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/guide_diagram.dart';
import 'guide_topic_screen.dart';

/// "دليل المسلم الجديد" — QURAN_COMPANION_ROADMAP.md §4.9 (5د, expanded).
/// Topic list: Wudu, Ghusl, Istinja, Salah.
class NewMuslimGuideScreen extends StatefulWidget {
  const NewMuslimGuideScreen({super.key});

  @override
  State<NewMuslimGuideScreen> createState() => _NewMuslimGuideScreenState();
}

class _NewMuslimGuideScreenState extends State<NewMuslimGuideScreen> {
  final _repo = GuideProgressRepository();
  Set<String> _readTopics = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final read = await _repo.readTopicKeys();
    if (!mounted) return;
    setState(() {
      _readTopics = read;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دليل المسلم الجديد')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'خطوات أساسية للطهارة والصلاة — بالعربية والإنجليزية والأمهرية',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                ...newMuslimGuideTopics.map((t) => _TopicCard(
                      topic: t,
                      isRead: _readTopics.contains(t.key),
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => GuideTopicScreen(topic: t)));
                        _load();
                      },
                    )),
              ],
            ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final GuideTopic topic;
  final bool isRead;
  final VoidCallback onTap;
  const _TopicCard({required this.topic, required this.isRead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GuideDiagram(topicKey: topic.key),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(topic.titleAr, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
                if (isRead) const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
              ],
            ),
            Text('${topic.steps.length} خطوة', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
