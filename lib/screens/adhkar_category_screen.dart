import 'dart:async';

import 'package:flutter/material.dart';

import '../repositories/adhkar_repository.dart';
import '../repositories/milestone_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/loading_view.dart';

/// The book's title for the merged morning+evening chapter — only this
/// category's completions count toward the streak certificates (see
/// `MilestoneRepository.checkAdhkarMilestones`'s doc comment for why it's
/// one combined habit rather than two separate morning/evening ones).
const _streakTrackedCategoryTitle = 'أذكار الصباح والمساء';

/// A warm, calm reading background shared with this app's other "reading
/// mode" screens (matches `quran_reading_screen.dart`'s cream tone) — part
/// of Ismail's 2026-08-16 "تجربة عبادة متصلة" request for a premium,
/// unhurried worship-session feel instead of a busy list screen.
const _readingBackground = Color(0xFFFBF6EE);

/// Continuous, one-dua-at-a-time reading flow for a single adhkar
/// category — QURAN_COMPANION_ROADMAP.md Phase 5هـ, redesigned 2026-08-16
/// per Ismail's detailed "تجربة عبادة متصلة" spec (inspired by studying
/// Almosaly's UX, deliberately not copying its visuals), then adjusted the
/// same day per his direct feedback ("السحب... من اليمين إلى اليسار أفضل"
/// after trying the first version) to swipe horizontally instead of
/// vertically.
///
/// Navigation is a horizontal `PageView` — the app is locked to
/// `TextDirection.rtl` globally (`main.dart`), so Flutter resolves a
/// horizontal `PageView`'s page order against that automatically: dragging
/// right-to-left (the natural "next" gesture in Arabic) moves to a higher
/// page index, with no manual direction-flipping needed. This replaced an
/// earlier vertical-swipe design that used scroll-*overscroll* to navigate
/// specifically to avoid a same-axis conflict between page-swiping and
/// reading-scroll (both vertical) — with paging now on the horizontal axis
/// and reading-scroll on the vertical axis, that conflict doesn't exist:
/// each page is free to be an ordinary vertically-scrollable
/// `SingleChildScrollView` for long duas, independent of the swipe gesture.
///
/// The existing tap-to-decrement-repeat-count interaction and its one-shot
/// golden glow flash (`_AdhkarItemCard`/`TweenSequence`, built earlier this
/// same session) are preserved as-is. The existing sprout-illustration
/// completion moment (`_SproutIllustration`) is preserved too, as the final
/// page in this same continuous flow instead of a modal `showDialog`.
class AdhkarCategoryScreen extends StatefulWidget {
  final AdhkarCategory category;
  const AdhkarCategoryScreen({super.key, required this.category});

  @override
  State<AdhkarCategoryScreen> createState() => _AdhkarCategoryScreenState();
}

class _AdhkarCategoryScreenState extends State<AdhkarCategoryScreen> {
  final _repo = AdhkarRepository();
  final _milestoneRepo = MilestoneRepository();
  List<AdhkarItem> _items = [];
  Map<int, int> _remaining = {};
  bool _loading = true;
  bool _alreadyDoneToday = false;
  int _currentIndex = 0;
  PageController? _pageController;

  Timer? _focusTimer;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.itemsFor(widget.category.id);
    final doneToday = await _repo.isCompletedToday(widget.category.id);
    final resumeIndex = doneToday ? 0 : (await _repo.resumePosition(widget.category.id)).clamp(0, items.length);
    if (!mounted) return;
    setState(() {
      _items = items;
      _alreadyDoneToday = doneToday;
      _remaining = {for (final i in items) i.id: doneToday ? 0 : i.repeatCount};
      _currentIndex = resumeIndex;
      _pageController = PageController(initialPage: resumeIndex);
      _loading = false;
    });
    _resetFocusTimer();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (index < _items.length) {
      _repo.saveSessionPosition(widget.category.id, index);
    }
    _resetFocusTimer();
  }

  /// Focus mode — Ismail's explicit request: after a few seconds of no
  /// interaction, non-content chrome (back button, progress bar) fades out
  /// so only the dua text remains, and reappears on any touch.
  void _resetFocusTimer() {
    _focusTimer?.cancel();
    if (!_chromeVisible) setState(() => _chromeVisible = true);
    _focusTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  Future<void> _tap(AdhkarItem item) async {
    final current = _remaining[item.id] ?? 0;
    if (current <= 0) return;
    setState(() => _remaining[item.id] = current - 1);
    if (!_remaining.values.every((v) => v <= 0)) return;

    await _repo.markCompletedToday(widget.category.id);
    await _repo.clearSessionPosition(widget.category.id);
    if (!mounted) return;

    if (widget.category.title != _streakTrackedCategoryTitle) return;
    final streak = await _repo.currentStreak(widget.category.id);
    final newlyEarned = await _milestoneRepo.checkAdhkarMilestones(streak);
    for (final milestone in newlyEarned) {
      if (!mounted) return;
      await showCelebration(context, milestone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageController = _pageController;
    return Scaffold(
      backgroundColor: _readingBackground,
      body: _loading || pageController == null
          ? const AppLoadingView(icon: Icons.spa_outlined, message: 'جاري تحميل الأذكار...')
          : Listener(
              onPointerDown: (_) => _resetFocusTimer(),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      controller: pageController,
                      scrollDirection: Axis.horizontal,
                      onPageChanged: _onPageChanged,
                      itemCount: _items.length + 1,
                      itemBuilder: (context, index) => index < _items.length
                          ? _DuaPage(
                              item: _items[index],
                              remaining: _remaining[_items[index].id] ?? 0,
                              onTap: () => _tap(_items[index]),
                            )
                          : _CompletionPage(
                              categoryTitle: widget.category.title,
                              onDone: () => Navigator.pop(context),
                            ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _chromeVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: IgnorePointer(
                      ignoring: !_chromeVisible,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
                                  Expanded(
                                    child: Text(widget.category.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                              if (_items.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _ProgressBar(total: _items.length, current: _currentIndex),
                                const SizedBox(height: 4),
                                Text(
                                  _alreadyDoneToday
                                      ? 'مراجعة — ${_currentIndex < _items.length ? _currentIndex + 1 : _items.length} من ${_items.length}'
                                      : 'الدعاء ${_currentIndex < _items.length ? _currentIndex + 1 : _items.length} من ${_items.length}',
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Slim Stories-style progress segments — Ismail's explicit request for
/// something more elegant than a bare "3 / 27" counter.
class _ProgressBar extends StatelessWidget {
  final int total;
  final int current;
  const _ProgressBar({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final passed = i < current;
        final isCurrent = i == current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == total - 1 ? 0 : 3),
            height: 4,
            decoration: BoxDecoration(
              color: passed || isCurrent ? AppColors.primary : AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// One full-page dua reading surface — an ordinary vertical scrollable, safe
/// to nest inside the outer horizontal `PageView` since the two no longer
/// share an axis (see the screen-level doc comment).
class _DuaPage extends StatelessWidget {
  final AdhkarItem item;
  final int remaining;
  final VoidCallback onTap;
  const _DuaPage({required this.item, required this.remaining, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 150),
      child: _AdhkarItemCard(item: item, remaining: remaining, onTap: onTap),
    );
  }
}

class _AdhkarItemCard extends StatefulWidget {
  final AdhkarItem item;
  final int remaining;
  final VoidCallback onTap;
  const _AdhkarItemCard({required this.item, required this.remaining, required this.onTap});

  @override
  State<_AdhkarItemCard> createState() => _AdhkarItemCardState();
}

/// A one-shot golden glow flash the instant a dhikr's count hits zero —
/// Ismail's 2026-08-16 decorative-features request (roadmap §4.34 point 4),
/// preserved unchanged through the reading-flow redesign. Detected via
/// `didUpdateWidget`'s not-done→done transition so it fires exactly once
/// per completion, not on every rebuild.
class _AdhkarItemCardState extends State<_AdhkarItemCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _glow = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 75),
  ]).animate(_glowController);

  bool get _done => widget.remaining <= 0;

  @override
  void didUpdateWidget(covariant _AdhkarItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remaining > 0 && _done) _glowController.forward(from: 0);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _glow.value > 0
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5 * _glow.value), blurRadius: 10 + 20 * _glow.value, spreadRadius: 3 * _glow.value)]
                : const [],
          ),
          child: child,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, height: 2.0, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(height: 28),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _done ? AppColors.primary : AppColors.primaryLight,
                  border: Border.all(color: AppColors.primary, width: _done ? 0 : 1.4),
                ),
                child: Center(
                  child: _done
                      ? const Icon(Icons.check, color: Colors.white, size: 26)
                      : Text('${widget.remaining}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primaryDark)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _done ? 'تم — اسحب لليسار للمتابعة' : 'اضغط للتكرار',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
            if (widget.item.footnote != null) ...[
              const SizedBox(height: 22),
              Text(widget.item.footnote!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Calm, non-confetti completion page — Ismail's explicit request ("لا
/// تعرض شاشة ضخمة مليئة بالأزرار... اعرض شاشة هادئة"). Reserved for
/// finishing an ordinary category; the big confetti+certificate
/// celebration (`celebration_overlay.dart`) is untouched and still fires
/// separately, only for the one streak-tracked category, exactly as before.
class _CompletionPage extends StatelessWidget {
  final String categoryTitle;
  final VoidCallback onDone;
  const _CompletionPage({required this.categoryTitle, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 140),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 72, height: 72, child: _SproutIllustration()),
              const SizedBox(height: 18),
              const Text('ما شاء الله', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('أتممت $categoryTitle', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              const Text('جزاك الله خيرًا 🌿', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 28),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: onDone, child: const Text('تم'))),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small original hand-drawn sprouting-plant illustration — two curved
/// leaves and a stem rising from a ground line, drawn with basic `Path`
/// curves rather than an imported asset. Chosen for the growth-from-
/// good-deeds imagery.
class _SproutIllustration extends StatelessWidget {
  const _SproutIllustration();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SproutPainter());
}

class _SproutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawCircle(
      Offset(w / 2, h * 0.42),
      w * 0.46,
      Paint()..color = const Color(0xFFD9A441).withValues(alpha: 0.14),
    );

    final groundY = h * 0.86;
    canvas.drawLine(Offset(w * 0.18, groundY), Offset(w * 0.82, groundY), Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.35)
      ..strokeWidth = 2);

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.primary;
    final stem = Path()
      ..moveTo(w / 2, groundY)
      ..quadraticBezierTo(w * 0.46, h * 0.55, w / 2, h * 0.24);
    canvas.drawPath(stem, stemPaint);

    final leafPaint = Paint()..color = AppColors.primary;
    final leftLeaf = Path()
      ..moveTo(w / 2, h * 0.5)
      ..quadraticBezierTo(w * 0.18, h * 0.42, w * 0.22, h * 0.62)
      ..quadraticBezierTo(w * 0.4, h * 0.62, w / 2, h * 0.5)
      ..close();
    final rightLeaf = Path()
      ..moveTo(w / 2, h * 0.36)
      ..quadraticBezierTo(w * 0.82, h * 0.28, w * 0.78, h * 0.48)
      ..quadraticBezierTo(w * 0.6, h * 0.48, w / 2, h * 0.36)
      ..close();
    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant _SproutPainter oldDelegate) => false;
}
