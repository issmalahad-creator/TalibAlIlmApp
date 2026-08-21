import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../repositories/worship_coach_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';

/// "مدرب العبادة" home-screen card (Ismail's request 2026-08-16) — shows
/// ONE current stage and ONE recommended task, never a full checklist,
/// per his explicit spec. Pure display; all the rule-based logic lives in
/// `WorshipCoachRepository`.
class WorshipCoachCard extends StatefulWidget {
  final VoidCallback onTap;
  const WorshipCoachCard({super.key, required this.onTap});

  @override
  State<WorshipCoachCard> createState() => _WorshipCoachCardState();
}

class _WorshipCoachCardState extends State<WorshipCoachCard> {
  final _repo = WorshipCoachRepository();
  WorshipCoachStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repo.status();
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) return const SizedBox.shrink();
    final lang = LanguagePreferenceService.currentLanguage;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        widget.onTap();
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.self_improvement_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(status.stageLabel, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.chevron_left_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 10),
            Text(status.taskLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _ConsistencyBar(label: basicText('consistency_prayer_label', lang), value: status.prayerConsistency, weak: status.focus == CoachFocusArea.prayer)),
                const SizedBox(width: 8),
                Expanded(child: _ConsistencyBar(label: basicText('consistency_quran_label', lang), value: status.quranConsistency, weak: status.focus == CoachFocusArea.quran)),
                const SizedBox(width: 8),
                Expanded(child: _ConsistencyBar(label: basicText('consistency_dhikr_label', lang), value: status.dhikrConsistency, weak: status.focus == CoachFocusArea.dhikr)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsistencyBar extends StatelessWidget {
  final String label;
  final double value;
  final bool weak;
  const _ConsistencyBar({required this.label, required this.value, required this.weak});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(weak ? const Color(0xFFD9A441) : Colors.white),
          ),
        ),
      ],
    );
  }
}
