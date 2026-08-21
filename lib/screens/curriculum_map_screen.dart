import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/curriculum_levels.dart';
import '../l10n/basic_translations.dart';
import '../repositories/curriculum_repository.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'adhkar_screen.dart';
import 'audio_library_screen.dart';
import 'hadith_screen.dart';
import 'madarij_screen.dart';
import 'new_muslim_guide_screen.dart';
import 'quran_browse_screen.dart';
import 'wasitiyyah_screen.dart';
import 'zad_almaad_screen.dart';
import '../widgets/loading_view.dart';

const _stateVisual = {
  CurriculumItemState.comingSoon: (Icons.hourglass_empty_rounded, AppColors.textMuted),
  CurriculumItemState.notStarted: (Icons.circle_outlined, AppColors.textMuted),
  CurriculumItemState.inProgress: (Icons.local_fire_department_rounded, AppColors.primaryDark),
  CurriculumItemState.completed: (Icons.check_rounded, Colors.white),
  CurriculumItemState.ongoing: (Icons.autorenew_rounded, AppColors.primaryDark),
};

/// "خريطتي التعليمية" — QURAN_COMPANION_ROADMAP.md §4.11 (Phase 7), redesigned
/// 2026-08-16 per Ismail's explicit request: he called the original plain
/// list "بدائية" (primitive) and asked for a real game-style path map
/// (Duolingo/skill-tree style) with a winding connecting line, progress
/// rings, and a pulsing "you are here" node — not a bare vertical list.
/// Still purely a navigation/recommendation layer on the SAME live data as
/// before (`CurriculumRepository`) — this pass only changed how it's drawn,
/// nothing about what's tracked or locked (still nothing is locked).
class CurriculumMapScreen extends StatefulWidget {
  const CurriculumMapScreen({super.key});

  @override
  State<CurriculumMapScreen> createState() => _CurriculumMapScreenState();
}

class _CurriculumMapScreenState extends State<CurriculumMapScreen> {
  final _repo = CurriculumRepository();
  final Map<int, List<CurriculumItemStatus>> _statuses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _repo.allStatuses();
    if (!mounted) return;
    setState(() {
      _statuses
        ..clear()
        ..addAll(all);
      _loading = false;
    });
  }

  void _open(String contentType) {
    Widget? screen;
    switch (contentType) {
      case 'juz_amma':
      case 'quran_memorization':
      case 'full_quran_mastery':
        screen = const QuranBrowseScreen();
        break;
      case 'adhkar':
        screen = const AdhkarScreen();
        break;
      case 'arbain':
        screen = const HadithScreen();
        break;
      case 'wasitiyyah':
        screen = const WasitiyyahScreen();
        break;
      case 'fiqh_taharah_salah':
        screen = const NewMuslimGuideScreen();
        break;
      case 'ajlan_tafsir':
        screen = const AudioLibraryScreen();
        break;
      case 'zad_almaad':
        screen = const ZadAlMaadScreen();
        break;
      case 'madarij':
        screen = const MadarijScreen();
        break;
    }
    if (screen == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(basicText('content_coming_soon_message', LanguagePreferenceService.currentLanguage))));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!)).then((_) => _load());
  }

  /// The first item, in level+item order, that isn't finished and isn't
  /// "coming soon" — the one real "أنت هنا" (you are here) step. Purely
  /// derived from the same live statuses, not a separate tracked field.
  String? get _currentContentType {
    for (final level in curriculumLevels) {
      for (final s in _statuses[level.id] ?? const <CurriculumItemStatus>[]) {
        if (s.state != CurriculumItemState.completed && s.state != CurriculumItemState.comingSoon) {
          return s.contentType;
        }
      }
    }
    return null;
  }

  (int completed, int total) get _overallCounts {
    var completed = 0, total = 0;
    for (final level in curriculumLevels) {
      for (final s in _statuses[level.id] ?? const <CurriculumItemStatus>[]) {
        if (s.state == CurriculumItemState.comingSoon) continue;
        total++;
        if (s.state == CurriculumItemState.completed) completed++;
      }
    }
    return (completed, total);
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentContentType;
    final (completed, total) = _overallCounts;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(basicText('curriculum_map_title', lang))),
      body: _loading
          ? AppLoadingView(icon: Icons.hourglass_empty_rounded, message: basicText('loading_generic', lang))
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: _MapKpiHeader(completed: completed, total: total),
                ),
                for (final level in curriculumLevels)
                  _LevelPath(
                    level: level,
                    statuses: _statuses[level.id] ?? const [],
                    currentContentType: current,
                    onTap: _open,
                  ),
              ],
            ),
      ),
    );
  }
}

class _MapKpiHeader extends StatelessWidget {
  final int completed;
  final int total;
  const _MapKpiHeader({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final percent = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text('${(percent * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(basicText('your_path_header', lang), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text('$completed ${basicText('weekly_progress_middle', lang)} $total ${basicText('stations_completed_suffix', lang)}', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                const SizedBox(height: 2),
                Text(basicText('no_lock_recommendation', lang), style: const TextStyle(fontSize: 10.5, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single gently-winding lane rather than a 3-lane zigzag — Ismail's
/// 2026-08-16 request for richer EduTree-style info cards (icon, title,
/// detail line, progress) at each node meant the old 3-lane layout no
/// longer had room: a ~300px-wide card centered at the 24%/76% side lanes
/// would overflow a typical phone's content width. A small alternating
/// offset (±7%) keeps the "it's a path, not a list" feel without risking
/// card overflow.
const _laneFractions = [0.46, 0.54];
const _lanePattern = [0, 1];
const _nodeSize = 56.0;
const _rowHeight = 176.0;
const _cardWidth = 264.0;

class _LevelPath extends StatelessWidget {
  final CurriculumLevelDef level;
  final List<CurriculumItemStatus> statuses;
  final String? currentContentType;
  final void Function(String contentType) onTap;

  const _LevelPath({required this.level, required this.statuses, required this.currentContentType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = statuses.length;
    final stackHeight = n == 0 ? 0.0 : (n - 1) * _rowHeight + _nodeSize + 170;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level.titleAr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                const SizedBox(height: 2),
                Text(level.descriptionAr, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final points = List.generate(n, (i) {
                final lane = _laneFractions[_lanePattern[i % _lanePattern.length]];
                final x = lane * width;
                final y = i * _rowHeight + _nodeSize / 2 + 8;
                return Offset(x, y);
              });
              return SizedBox(
                height: stackHeight,
                width: width,
                child: Stack(
                  children: [
                    if (points.length > 1)
                      CustomPaint(
                        size: Size(width, stackHeight),
                        painter: _PathPainter(
                          points: points,
                          reached: List.generate(n - 1, (i) => statuses[i].state == CurriculumItemState.completed),
                        ),
                      ),
                    for (var i = 0; i < n; i++)
                      _MapNodeSlot(
                        center: points[i],
                        status: statuses[i],
                        isCurrent: statuses[i].contentType == currentContentType,
                        onTap: () => onTap(statuses[i].contentType),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  final List<bool> reached;
  const _PathPainter({required this.points, required this.reached});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midY = (p0.dy + p1.dy) / 2;
      final segment = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(p0.dx, midY, p1.dx, midY, p1.dx, p1.dy);

      final isReached = reached[i];
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = isReached ? AppColors.primary : AppColors.divider;

      if (isReached) {
        canvas.drawPath(segment, paint);
      } else {
        _drawDashed(canvas, segment, paint);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 7.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final next = distance + (draw ? dashLength : gapLength);
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, math.min(next, metric.length)), paint);
        }
        distance = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.reached != reached;
}

class _MapNodeSlot extends StatelessWidget {
  final Offset center;
  final CurriculumItemStatus status;
  final bool isCurrent;
  final VoidCallback onTap;

  const _MapNodeSlot({required this.center, required this.status, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - _cardWidth / 2,
      top: center.dy - _nodeSize / 2,
      width: _cardWidth,
      child: Column(
        children: [
          if (isCurrent) const _NowBadge(),
          _MapNode(status: status, isCurrent: isCurrent, onTap: onTap),
          const SizedBox(height: 8),
          _MapInfoCard(status: status, isCurrent: isCurrent, onTap: onTap),
        ],
      ),
    );
  }
}

/// The EduTree-style info card under each path node — icon badge, title,
/// one real detail line (`status.detailAr`, already-live data, not
/// invented copy), and a thin progress bar for in-progress items. No
/// points/XP badge: Ismail was explicit earlier this session that the
/// reward should be the actual learning milestone, not a fake currency
/// ("لا يجب أن يتحول طالب العلم إلى: أجمع نقاطاً").
class _MapInfoCard extends StatelessWidget {
  final CurriculumItemStatus status;
  final bool isCurrent;
  final VoidCallback onTap;
  const _MapInfoCard({required this.status, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final (icon, iconColor) = _stateVisual[status.state]!;
    final isCompleted = status.state == CurriculumItemState.completed;
    final isComingSoon = status.state == CurriculumItemState.comingSoon;
    final fraction = status.progressFraction;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCurrent ? AppColors.primary : AppColors.divider, width: isCurrent ? 1.6 : 1),
          boxShadow: isCurrent
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), blurRadius: 14, spreadRadius: 1)]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? AppColors.primary : AppColors.primaryLight,
              ),
              child: Icon(icon, size: 17, color: isCompleted ? Colors.white : iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.titleAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(status.detailAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  if (status.advisoryText != null) ...[
                    const SizedBox(height: 3),
                    Text(status.advisoryText!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFFB8860B), fontWeight: FontWeight.w600)),
                  ],
                  if (fraction != null && !isCompleted) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: fraction, minHeight: 5, backgroundColor: AppColors.divider, valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (isCompleted)
                        _CardTag(text: basicText('tag_completed_label', lang), color: AppColors.primary, textColor: Colors.white)
                      else if (isComingSoon)
                        _CardTag(text: basicText('tag_coming_soon_label', lang), color: AppColors.divider, textColor: AppColors.textMuted)
                      else
                        _CardTag(
                            text: basicText(isCurrent ? 'tag_continue_now_label' : 'tag_open_label', lang),
                            color: AppColors.primaryLight,
                            textColor: AppColors.primaryDark),
                      const Spacer(),
                      if (!isComingSoon) const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _CardTag({required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textColor)),
    );
  }
}

class _NowBadge extends StatelessWidget {
  const _NowBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(20)),
      child: Text(basicText('you_are_here_badge', LanguagePreferenceService.currentLanguage), style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

class _MapNode extends StatefulWidget {
  final CurriculumItemStatus status;
  final bool isCurrent;
  final VoidCallback onTap;
  const _MapNode({required this.status, required this.isCurrent, required this.onTap});

  @override
  State<_MapNode> createState() => _MapNodeState();
}

class _MapNodeState extends State<_MapNode> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppMotion.ambient)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = _stateVisual[widget.status.state]!;
    final isCompleted = widget.status.state == CurriculumItemState.completed;
    final fraction = widget.status.progressFraction;

    Widget node = Container(
      width: _nodeSize,
      height: _nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: isCompleted
              ? AppColors.primaryDark
              : widget.status.state == CurriculumItemState.comingSoon
                  ? AppColors.divider
                  : AppColors.primary,
          width: widget.isCurrent ? 3 : 2,
        ),
        boxShadow: isCompleted
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 1)]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (fraction != null && !isCompleted)
            SizedBox(
              width: _nodeSize - 8,
              height: _nodeSize - 8,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 4,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          Icon(icon, color: iconColor, size: isCompleted ? 30 : 24),
        ],
      ),
    );

    if (widget.isCurrent) {
      node = AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final scale = 1.0 + (_pulse.value * 0.08);
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25 * (1 - _pulse.value) + 0.1), blurRadius: 16, spreadRadius: 4 + _pulse.value * 4)],
            ),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: node,
      );
    }

    return GestureDetector(onTap: widget.onTap, child: node);
  }
}
