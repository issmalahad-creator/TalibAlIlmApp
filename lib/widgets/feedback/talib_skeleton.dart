import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Skeleton screens (docs/architecture/INTERACTION_FEEDBACK_ARCHITECTURE.md
/// §5, IF-3): when the layout of what is coming is known, show its shape —
/// users perceive it as faster than a spinner for the same wait.
///
/// - Nothing is drawn for the first [revealAfter] (300 ms): a fast load never
///   flashes a skeleton.
/// - One slow pulse (≥1.6 s per cycle — slow motion reads as a shorter wait)
///   drives every block through an InheritedNotifier: one controller per
///   skeleton, not one per block.
/// - [semanticLabel] announces the contextual wait to screen readers.
class TalibSkeleton extends StatefulWidget {
  final Widget child;
  final String? semanticLabel;
  final Duration revealAfter;

  const TalibSkeleton({
    super.key,
    required this.child,
    this.semanticLabel,
    this.revealAfter = const Duration(milliseconds: 300),
  });

  @override
  State<TalibSkeleton> createState() => _TalibSkeletonState();
}

class _TalibSkeletonState extends State<TalibSkeleton> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;
  Timer? _reveal;

  @override
  void initState() {
    super.initState();
    _reveal = Timer(widget.revealAfter, () {
      if (!mounted) return;
      setState(() => _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat());
    });
  }

  @override
  void dispose() {
    _reveal?.cancel();
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = _pulse;
    final body = pulse == null
        ? const SizedBox.expand()
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 240),
            builder: (context, fade, child) => Opacity(opacity: fade, child: child),
            child: _SkeletonPulse(notifier: pulse, child: widget.child),
          );
    return Semantics(label: widget.semanticLabel, liveRegion: true, child: ExcludeSemantics(child: body));
  }
}

class _SkeletonPulse extends InheritedNotifier<AnimationController> {
  const _SkeletonPulse({required AnimationController super.notifier, required super.child});

  static double of(BuildContext context) {
    final c = context.dependOnInheritedWidgetOfExactType<_SkeletonPulse>()?.notifier;
    if (c == null) return 0.5;
    return 0.5 - 0.5 * math.cos(c.value * 2 * math.pi);
  }
}

/// One placeholder block. [width] null = fill the available width.
class SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  const SkeletonBlock({super.key, this.width, required this.height, this.radius = 8}) : shape = BoxShape.rectangle;
  const SkeletonBlock.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final t = _SkeletonPulse.of(context);
    final base = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.055 + 0.045 * t),
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A few text lines; the last one shorter, like a real paragraph.
class SkeletonLines extends StatelessWidget {
  final int lines;
  final double lineHeight;
  const SkeletonLines({super.key, this.lines = 2, this.lineHeight = 11});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++) ...[
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: i == lines - 1 && lines > 1 ? 0.62 : 1,
            child: SkeletonBlock(height: lineHeight, radius: 5),
          ),
          if (i < lines - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// A list of card-shaped rows: optional leading square, a title line and
/// [lines] body lines — books, search results, catalogue rows.
class SkeletonCardList extends StatelessWidget {
  final int count;
  final int lines;
  final bool leading;
  final double leadingSize;
  final EdgeInsetsGeometry padding;

  const SkeletonCardList({
    super.key,
    this.count = 6,
    this.lines = 2,
    this.leading = false,
    this.leadingSize = 48,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading) ...[
                SkeletonBlock(width: leadingSize, height: leadingSize, radius: 10),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 0.55 + 0.1 * (i % 3),
                      child: const SkeletonBlock(height: 14, radius: 6),
                    ),
                    const SizedBox(height: 12),
                    SkeletonLines(lines: lines),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shape of Home: greeting, the green Quran card, two cards, icon grid.
class SkeletonHome extends StatelessWidget {
  const SkeletonHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        const Row(
          children: [
            SkeletonBlock.circle(size: 44),
            SizedBox(width: 12),
            Expanded(child: SkeletonLines(lines: 2, lineHeight: 12)),
          ],
        ),
        const SizedBox(height: 18),
        const SkeletonBlock(height: 104, radius: 20),
        const SizedBox(height: 14),
        const SkeletonBlock(height: 130, radius: 16),
        const SizedBox(height: 14),
        const SkeletonBlock(height: 86, radius: 16),
        const SizedBox(height: 22),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          children: [
            for (var i = 0; i < 8; i++)
              const Column(
                children: [
                  SkeletonBlock.circle(size: 50),
                  SizedBox(height: 8),
                  SkeletonBlock(width: 44, height: 8, radius: 4),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
