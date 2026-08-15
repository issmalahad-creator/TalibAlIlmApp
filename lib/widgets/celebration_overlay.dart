import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../repositories/milestone_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/certificate_service.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import 'certificate_card.dart';

/// Full-screen celebration for a newly-earned certificate —
/// QURAN_COMPANION_ROADMAP.md §4.14: confetti intensity/duration scales with
/// [Milestone.celebrationTier] ("يرتفع مع ارتفاع الهمة"), and — unlike an
/// addictive-engagement loop — this only ever fires for a genuinely
/// completed milestone (called from `MilestoneRepository.checkQuranMilestones`/
/// `checkHadithMilestones`'s newly-earned results), never on a fixed timer.
Future<void> showCelebration(BuildContext context, Milestone milestone) async {
  final profile = await ProfileRepository().get();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black87,
    builder: (_) => _CelebrationDialog(milestone: milestone, studentName: profile.fullName),
  );
}

class _CelebrationDialog extends StatefulWidget {
  final Milestone milestone;
  final String studentName;
  const _CelebrationDialog({required this.milestone, required this.studentName});

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  late final ConfettiController _confetti;
  final _certificateKey = GlobalKey();
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    final tier = widget.milestone.celebrationTier;
    _confetti = ConfettiController(duration: Duration(seconds: 2 + tier));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    await CertificateService().shareFromBoundary(_certificateKey, 'شهادة_${widget.milestone.id}');
    await MilestoneRepository().markShared(widget.milestone.id);
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.milestone.celebrationTier;
    final grand = widget.milestone.milestoneType == 'full_quran';
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 12 * tier,
            emissionFrequency: 0.06,
            maxBlastForce: 12 + tier * 4,
            minBlastForce: 6,
            gravity: 0.25,
            colors: const [AppColors.primary, AppColors.primaryDark, Color(0xFFB8860B), Colors.white],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: _certificateKey,
                child: CertificateCard(
                  studentName: widget.studentName,
                  title: widget.milestone.title,
                  hijriDate: todayDate(),
                  grand: grand,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(_sharing ? 'جارٍ التجهيز...' : 'مشاركة الشهادة'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
