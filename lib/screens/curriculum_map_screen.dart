import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/curriculum_levels.dart';
import '../repositories/curriculum_repository.dart';
import '../theme/app_theme.dart';
import 'adhkar_screen.dart';
import 'audio_library_screen.dart';
import 'hadith_screen.dart';
import 'madarij_screen.dart';
import 'new_muslim_guide_screen.dart';
import 'quran_browse_screen.dart';
import 'wasitiyyah_screen.dart';
import 'zad_almaad_screen.dart';

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
    for (final level in curriculumLevels) {
      _statuses[level.id] = await _repo.statusesFor(level.items);
    }
    if (!mounted) return;
    setState(() => _loading = false);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا المحتوى قيد التحضير')));
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('خريطتي التعليمية')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
    );
  }
}

class _MapKpiHeader extends StatelessWidget {
  final int completed;
  final int total;
  const _MapKpiHeader({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
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
                const Text('مسارك: من الصفر إلى التعمّق', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text('$completed من $total محطة مكتملة', style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                const SizedBox(height: 2),
                const Text('توصية لا قفل — افتح ما تشاء بأي ترتيب', style: TextStyle(fontSize: 10.5, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lane fractions (of available width) the path snakes between, and the
/// cycling order it visits them in — produces a left/center/right/center
/// wave rather than a flat two-column zigzag, closer to a real game map.
const _laneFractions = [0.24, 0.5, 0.76];
const _lanePattern = [0, 1, 2, 1];
const _nodeSize = 68.0;
const _rowHeight = 128.0;

class _LevelPath extends StatelessWidget {
  final CurriculumLevelDef level;
  final List<CurriculumItemStatus> statuses;
  final String? currentContentType;
  final void Function(String contentType) onTap;

  const _LevelPath({required this.level, required this.statuses, required this.currentContentType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = statuses.length;
    final stackHeight = n == 0 ? 0.0 : (n - 1) * _rowHeight + _nodeSize + 56;
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
      left: center.dx - 60,
      top: center.dy - _nodeSize / 2,
      width: 120,
      child: Column(
        children: [
          if (isCurrent) const _NowBadge(),
          _MapNode(status: status, isCurrent: isCurrent, onTap: onTap),
          const SizedBox(height: 6),
          Text(
            status.titleAr,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          Text(status.detailAr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
        ],
      ),
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
      child: const Text('أنت هنا', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w800)),
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
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
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
