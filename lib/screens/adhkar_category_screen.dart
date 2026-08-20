import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../repositories/adhkar_repository.dart';
import '../repositories/custom_adhkar_reminder_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../repositories/milestone_repository.dart';
import '../services/adhkar_reading_prefs.dart';
import '../services/notification_service.dart';
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

/// Dark counterpart for the reading screen's own night toggle — Ismail's
/// 2026-08-16 request after sharing a reference app's reading-screen
/// controls (share / A- / A+ / crescent-moon icon). Scoped to just this
/// screen (see `AdhkarReadingPrefs`'s doc comment) rather than a full
/// app-wide theme switch.
const _readingBackgroundDark = Color(0xFF1D2119);
const _readingTextDark = Color(0xFFEDE7D6);
const _readingHintDark = Color(0xFFB9B4A2);

/// Continuous, one-dua-at-a-time reading flow for a single adhkar
/// category — QURAN_COMPANION_ROADMAP.md Phase 5هـ, redesigned 2026-08-16
/// per Ismail's detailed "تجربة عبادة متصلة" spec (inspired by studying
/// Almosaly's UX, deliberately not copying its visuals). The swipe
/// direction itself went through three rounds of direct on-device feedback
/// the same day: vertical → horizontal, right-to-left = next → left-to-
/// right = next → back to right-to-left = next (his final call, "الحركة
/// معكوسة اعكسها" after trying the left-to-right version).
///
/// Navigation is a horizontal `PageView` with **no directionality
/// override** — the app is locked to `TextDirection.rtl` globally
/// (`main.dart`), and Flutter resolves a horizontal `PageView`'s page
/// order against that ambient direction automatically, so right-to-left
/// drag = next "just works" without any extra code. (An earlier revision
/// briefly wrapped the `PageView` in a local `Directionality(ltr)`
/// override to flip this — that's been removed now that right-to-left is
/// the final, confirmed direction, since it's literally the default
/// behavior with nothing to override.) Paging is on the horizontal axis
/// and reading-scroll is on the vertical axis, so the two never conflict:
/// each page is free to be an ordinary vertically-scrollable
/// `SingleChildScrollView` for long duas.
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
  final _readingPrefs = AdhkarReadingPrefs();
  List<AdhkarItem> _items = [];
  Map<int, int> _remaining = {};
  bool _loading = true;
  bool _alreadyDoneToday = false;
  int _currentIndex = 0;
  PageController? _pageController;
  double _fontScale = 1.0;
  bool _darkReading = false;

  Timer? _focusTimer;
  bool _chromeVisible = true;

  /// Live countdown from the category's estimated reading time (Ismail's
  /// 2026-08-17 "أريد عداد الوقت التنازلي... كي يحس أنه استغل الوقت"
  /// request) — session-local, not persisted, resets each time the screen
  /// opens. Reuses `AdhkarRepository.estimatedMinutes` built the same day
  /// for the notification copy/home-card minute badges. Stops at zero
  /// rather than going negative; hidden once today's reading is already
  /// done (no time-pressure framing for a review pass).
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadReadingPrefs();
  }

  Future<void> _loadReadingPrefs() async {
    final scale = await _readingPrefs.fontScale();
    final dark = await _readingPrefs.darkMode();
    if (!mounted) return;
    setState(() {
      _fontScale = scale;
      _darkReading = dark;
    });
  }

  void _adjustFont(double delta) {
    final next = (_fontScale + delta).clamp(AdhkarReadingPrefs.minScale, AdhkarReadingPrefs.maxScale);
    setState(() => _fontScale = next);
    _readingPrefs.setFontScale(next);
  }

  void _toggleDarkReading() {
    final next = !_darkReading;
    setState(() => _darkReading = next);
    _readingPrefs.setDarkMode(next);
  }

  void _shareCurrentDua() {
    if (_currentIndex >= _items.length) return;
    Share.share(_items[_currentIndex].text);
  }

  /// "🔔 أضف تذكيرًا" — Ismail's 2026-08-17 request to add a reminder for
  /// any adhkar category, not just the 3 fixed morning/evening/sleep
  /// slots, directly from the category's own reading screen.
  Future<void> _addReminder() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (picked == null || !mounted) return;
    await CustomAdhkarReminderRepository().add(widget.category.id, picked.hour);
    await NotificationService().scheduleCustomAdhkarReminder(
      categoryId: widget.category.id,
      categoryTitle: widget.category.title,
      hour: picked.hour,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة تذكير يومي الساعة ${picked.hour}:00')));
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _countdownTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.itemsFor(widget.category.id);
    final doneToday = await _repo.isCompletedToday(widget.category.id);
    final resumeIndex = doneToday ? 0 : (await _repo.resumePosition(widget.category.id)).clamp(0, items.length);
    final minutes = await _repo.estimatedMinutes(widget.category.id);
    if (!mounted) return;
    setState(() {
      _items = items;
      _alreadyDoneToday = doneToday;
      _remaining = {for (final i in items) i.id: doneToday ? 0 : i.repeatCount};
      _currentIndex = resumeIndex;
      _pageController = PageController(initialPage: resumeIndex);
      _loading = false;
      _remainingSeconds = minutes * 60;
    });
    _resetFocusTimer();
    if (!doneToday) _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        _countdownTimer?.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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

  /// Opts one dhikr into the generalized spaced-review engine — Ismail's
  /// 2026-08-16 "أريد المستخدم أن يحفظ الأذكار أيضًا" request. Text-only,
  /// same `KnowledgeReviewRepository` already built for hadith/Wasitiyyah
  /// (Phase 44); audio for adhkar stays a separate, optional layer (see
  /// `ADHKAR_AUDIO_SOURCES.md`) — this works today with zero audio content.
  Future<void> _memorize(AdhkarItem item) async {
    final alreadyIn = await KnowledgeReviewRepository().isUnderReview('adhkar', item.id);
    if (alreadyIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الذكر مضاف بالفعل لمراجعة الحفظ')));
      return;
    }
    await KnowledgeReviewRepository().startReviewing('adhkar', item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أُضيف — ستراجعه غدًا في "مراجعتك اليوم" 🌱')));
  }

  @override
  Widget build(BuildContext context) {
    final pageController = _pageController;
    final chromeMuted = _darkReading ? _readingHintDark : AppColors.textMuted;
    return Scaffold(
      backgroundColor: _darkReading ? _readingBackgroundDark : _readingBackground,
      body: _loading || pageController == null
          ? const AppLoadingView(icon: Icons.spa_outlined, message: 'جاري تحميل الأذكار...')
          : Listener(
              onPointerDown: (_) => _resetFocusTimer(),
              child: Stack(
                children: [
                  Positioned.fill(
                    // No directionality override — right-to-left = next is
                    // the ambient RTL app's default PageView behavior, so
                    // this is just the plain widget (see class doc comment).
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
                              fontScale: _fontScale,
                              dark: _darkReading,
                              onMemorize: () => _memorize(_items[index]),
                            )
                          : _CompletionPage(
                              categoryTitle: widget.category.title,
                              onDone: () => Navigator.pop(context),
                              dark: _darkReading,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(icon: Icon(Icons.arrow_back_ios_new, size: 18, color: chromeMuted), onPressed: () => Navigator.pop(context)),
                                  Expanded(
                                    child: Text(widget.category.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: chromeMuted)),
                                  ),
                                  _ChromeIconButton(icon: Icons.ios_share_outlined, color: chromeMuted, onPressed: _shareCurrentDua),
                                  _ChromeIconButton(icon: Icons.text_decrease, color: chromeMuted, onPressed: () => _adjustFont(-0.1)),
                                  _ChromeIconButton(icon: Icons.text_increase, color: chromeMuted, onPressed: () => _adjustFont(0.1)),
                                  _ChromeIconButton(
                                    icon: _darkReading ? Icons.light_mode_outlined : Icons.nightlight_round,
                                    color: chromeMuted,
                                    onPressed: _toggleDarkReading,
                                  ),
                                  _ChromeIconButton(icon: Icons.notifications_active_outlined, color: chromeMuted, onPressed: _addReminder),
                                ],
                              ),
                              if (_items.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _ProgressBar(total: _items.length, current: _currentIndex),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _alreadyDoneToday
                                          ? 'مراجعة — ${_currentIndex < _items.length ? _currentIndex + 1 : _items.length} من ${_items.length}'
                                          : 'الدعاء ${_currentIndex < _items.length ? _currentIndex + 1 : _items.length} من ${_items.length}',
                                      style: TextStyle(fontSize: 10.5, color: chromeMuted, fontWeight: FontWeight.w600),
                                    ),
                                    if (!_alreadyDoneToday && _remainingSeconds > 0) ...[
                                      const SizedBox(width: 8),
                                      Text('·', style: TextStyle(fontSize: 10.5, color: chromeMuted)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '⏱ ${_formatCountdown(_remainingSeconds)} متبقٍ',
                                        style: TextStyle(fontSize: 10.5, color: chromeMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
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

/// Compact icon button for the reading-screen chrome row — four of these
/// (share/A-/A+/night toggle) need to fit next to the back button and title
/// without overflowing narrow screens, so this trims the default
/// `IconButton`'s minimum tap-target padding down to just enough to stay
/// comfortably tappable.
class _ChromeIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _ChromeIconButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 17, color: color),
      onPressed: onPressed,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 18,
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
  final double fontScale;
  final bool dark;
  final VoidCallback onMemorize;
  const _DuaPage({required this.item, required this.remaining, required this.onTap, this.fontScale = 1.0, this.dark = false, required this.onMemorize});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 110, 24, 150),
      child: _AdhkarItemCard(item: item, remaining: remaining, onTap: onTap, fontScale: fontScale, dark: dark, onMemorize: onMemorize),
    );
  }
}

class _AdhkarItemCard extends StatefulWidget {
  final AdhkarItem item;
  final int remaining;
  final VoidCallback onTap;
  final double fontScale;
  final bool dark;
  final VoidCallback onMemorize;
  const _AdhkarItemCard({required this.item, required this.remaining, required this.onTap, this.fontScale = 1.0, this.dark = false, required this.onMemorize});

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
    final textColor = widget.dark ? _readingTextDark : AppColors.textDark;
    final hintColor = widget.dark ? _readingHintDark : AppColors.textMuted;
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
            Text(widget.item.text, textAlign: TextAlign.center, style: TextStyle(fontSize: 22 * widget.fontScale, height: 2.0, fontWeight: FontWeight.w600, color: textColor)),
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
              style: TextStyle(fontSize: 11.5, color: hintColor, fontWeight: FontWeight.w600),
            ),
            if (widget.item.footnote != null) ...[
              const SizedBox(height: 22),
              Text(widget.item.footnote!, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5 * widget.fontScale, color: hintColor)),
            ],
            const SizedBox(height: 18),
            Center(
              child: TextButton.icon(
                onPressed: widget.onMemorize,
                icon: const Icon(Icons.psychology_outlined, size: 16),
                label: const Text('أضفه لحفظ الأذكار', style: TextStyle(fontSize: 11.5)),
                style: TextButton.styleFrom(foregroundColor: hintColor, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              ),
            ),
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
  final bool dark;
  const _CompletionPage({required this.categoryTitle, required this.onDone, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? _readingTextDark : AppColors.textDark;
    final hintColor = dark ? _readingHintDark : AppColors.textMuted;
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 140),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 72, height: 72, child: _SproutIllustration()),
              const SizedBox(height: 18),
              Text('ما شاء الله', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 8),
              Text('أتممت $categoryTitle', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: hintColor)),
              const SizedBox(height: 6),
              Text('جزاك الله خيرًا 🌿', style: TextStyle(fontSize: 13, color: hintColor)),
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
