import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/quran_surahs.dart';
import '../../theme/app_theme.dart';

/// Where each juzʼ starts, `(surah, ayah)` — the standard Ḥafṣ division
/// (juzʼ 1 = 148 ayat … juzʼ 30 = 564; checked in `test/juz_shelf_test.dart`).
const kJuzStarts = <(int, int)>[
  (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), (4, 148), (5, 82), (6, 111), (7, 88), (8, 41), //
  (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), (18, 75), (21, 1), (23, 1), (25, 21), (27, 56), //
  (29, 46), (33, 31), (36, 28), (39, 32), (41, 47), (46, 1), (51, 31), (58, 1), (67, 1), (78, 1),
];

/// For each juzʼ (index 0 = juzʼ 1), the share of its ayat that sit in a
/// memorized surah. Pure — the shelf and the tests share it.
List<double> juzMemorizedFractions(Set<int> memorizedSurahs) {
  final offset = <int>[0];
  for (final s in quranSurahs) {
    offset.add(offset.last + s.ayahCount);
  }
  final total = offset.last;
  final starts = [for (final (s, a) in kJuzStarts) offset[s - 1] + a - 1, total];
  final memorized = List<bool>.filled(total, false);
  for (final n in memorizedSurahs) {
    if (n < 1 || n > quranSurahs.length) continue;
    for (var i = offset[n - 1]; i < offset[n]; i++) {
      memorized[i] = true;
    }
  }
  return [
    for (var j = 0; j < 30; j++)
      () {
        final len = starts[j + 1] - starts[j];
        var m = 0;
        for (var i = starts[j]; i < starts[j + 1]; i++) {
          if (memorized[i]) m++;
        }
        return len == 0 ? 0.0 : m / len;
      }(),
  ];
}

/// «خريطة حفظي» as the muṣḥaf itself: its page block seen in 3/4 view, cut
/// into 30 ajzāʼ, each filling with gold-green as it is memorized (Ismail
/// 2026-10-22: «حوّل من 2D إلى 3D»). Juzʼ 1 on the right, as an Arabic
/// muṣḥaf lies. Tap a juzʼ for its share. Grows in once, then rests.
class JuzShelf3D extends StatefulWidget {
  final List<double> fractions;
  final String Function(int juz, double fraction) labelFor;
  const JuzShelf3D({super.key, required this.fractions, required this.labelFor});

  @override
  State<JuzShelf3D> createState() => _JuzShelf3DState();
}

class _JuzShelf3DState extends State<JuzShelf3D> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(-0.42),
          child: SizedBox(
            height: 92,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var j = 0; j < 30; j++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _picked = _picked == j ? null : j);
                      },
                      child: _Bundle(
                        fill: (widget.fractions[j] * t).clamp(0.0, 1.0),
                        picked: picked == j,
                        // the five-juzʼ marks every printed muṣḥaf has
                        heavy: (j + 1) % 5 == 0,
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Text(
          picked == null ? ' ' : widget.labelFor(picked + 1, widget.fractions[picked]),
          key: ValueKey(picked),
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
        ),
      ),
    ]);
  }
}

/// One juzʼ: a bundle of pages, paper on top, filling from the bottom.
class _Bundle extends StatelessWidget {
  final double fill;
  final bool picked;
  final bool heavy;
  const _Bundle({required this.fill, required this.picked, required this.heavy});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD9A441);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(left: heavy ? 2.2 : 0.8, bottom: picked ? 10 : 0),
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCF4), Color(0xFFEADFC8)],
        ),
        border: Border.all(color: picked ? gold : const Color(0x22000000), width: picked ? 1.4 : 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: picked ? 0.28 : 0.12),
            blurRadius: picked ? 8 : 3,
            offset: Offset(0, picked ? 6 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: fill,
            widthFactor: 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6FBF8B), AppColors.primary],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
