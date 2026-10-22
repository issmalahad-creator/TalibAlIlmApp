import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import 'package:share_plus/share_plus.dart';

import '../repositories/adhkar_repository.dart';
import '../repositories/custom_adhkar_reminder_repository.dart';
import '../repositories/knowledge_review_repository.dart';
import '../repositories/milestone_repository.dart';
import '../services/adhkar_reading_prefs.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/month.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/loading_view.dart';
import '../widgets/notification_permission_sheet.dart';

/// This screen's strings — `basicText` in the current app language.
String _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);


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

  /// For the morning/evening chapter: 'morning' or 'evening'. Null picks by
  /// the clock (evening from mid-afternoon until 3 am). Ignored elsewhere.
  final String? session;
  const AdhkarCategoryScreen({super.key, required this.category, this.session});

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

  /// 'morning' | 'evening' | 'all' while reading the morning/evening
  /// chapter — the book gives each its own wording («أمسينا…») and a few
  /// adhkar belong to only one of them; 'all' is the whole chapter as one
  /// list. Null for every other chapter.
  String? _session;

  /// The reader's own choice, remembered (Ismail: the timing is optional,
  /// never forced): 'auto' follows the clock, or a fixed session.
  static const _modePrefKey = 'adhkar_session_mode';
  String _mode = 'auto';
  bool get _isMorningEvening => widget.category.title == _streakTrackedCategoryTitle;

  static String _defaultSession() {
    final h = DateTime.now().hour;
    return (h >= 15 || h < 3) ? 'evening' : 'morning';
  }

  // Per-session «done today» + resume position (the DB keeps one per
  // chapter; the streak still counts the chapter once a day).
  String get _sessionKey => 'adhkar_me_${_session}_${widget.category.id}';
  Future<bool> _sessionDoneToday() async =>
      (await SharedPreferences.getInstance()).getString('${_sessionKey}_done') == todayDate();
  Future<int> _sessionResume() async {
    final v = (await SharedPreferences.getInstance()).getString('${_sessionKey}_pos');
    final parts = v?.split('|');
    if (parts == null || parts.length != 2 || parts[0] != todayDate()) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

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
    await ensureNotificationPermission(context, NotificationReason.adhkar);
    await CustomAdhkarReminderRepository().add(widget.category.id, picked.hour);
    await NotificationService().scheduleCustomAdhkarReminder(
      categoryId: widget.category.id,
      categoryTitle: widget.category.title,
      hour: picked.hour,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('adc_reminder_added').replaceAll('{h}', '${picked.hour}'))));
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _countdownTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_isMorningEvening && _session == null) {
      _mode = (await SharedPreferences.getInstance()).getString(_modePrefKey) ?? 'auto';
      _session = _mode == 'auto' ? (widget.session ?? _defaultSession()) : _mode;
    }
    final session = _session;
    var items = await _repo.itemsFor(widget.category.id);
    if (session != null && session != 'all') {
      items = [for (final i in items) ?i.forSession(session)];
    }
    final doneToday = session != null ? await _sessionDoneToday() : await _repo.isCompletedToday(widget.category.id);
    final resumeIndex = doneToday
        ? 0
        : (session != null ? await _sessionResume() : await _repo.resumePosition(widget.category.id)).clamp(0, items.length);
    final minutes = await _repo.estimatedMinutes(widget.category.id);
    if (!mounted) return;
    setState(() {
      _items = items;
      _alreadyDoneToday = doneToday;
      _remaining = {for (final i in items) i.id: doneToday ? 0 : i.repeatCount};
      _currentIndex = resumeIndex;
      _pageController?.dispose();
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
      if (_session != null) {
        SharedPreferences.getInstance().then((p) => p.setString('${_sessionKey}_pos', '${todayDate()}|$index'));
      } else {
        _repo.saveSessionPosition(widget.category.id, index);
      }
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
    // A felt count, like a tasbih bead — so the eyes can stay on the words.
    if (current - 1 > 0) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
      _advanceAfterDone(item);
    }
    if (!_remaining.values.every((v) => v <= 0)) return;

    if (_session != null) {
      final p = await SharedPreferences.getInstance();
      await p.setString('${_sessionKey}_done', todayDate());
      await p.remove('${_sessionKey}_pos');
      if (!await _repo.isCompletedToday(widget.category.id)) {
        await _repo.markCompletedToday(widget.category.id);
      }
    } else {
      await _repo.markCompletedToday(widget.category.id);
      await _repo.clearSessionPosition(widget.category.id);
    }
    if (!mounted) return;

    if (widget.category.title != _streakTrackedCategoryTitle) return;
    final streak = await _repo.currentStreak(widget.category.id);
    final newlyEarned = await _milestoneRepo.checkAdhkarMilestones(streak);
    for (final milestone in newlyEarned) {
      if (!mounted) return;
      await showCelebration(context, milestone);
    }
  }

  /// A finished dhikr turns the page by itself after a short beat (only if
  /// the reader is still on it) — no extra swipe between adhkar.
  void _advanceAfterDone(AdhkarItem item) {
    final index = _items.indexOf(item);
    Future.delayed(const Duration(milliseconds: 450), () {
      final c = _pageController;
      if (!mounted || c == null || !c.hasClients || _currentIndex != index) return;
      c.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    });
  }

  /// [mode]: 'auto' | 'morning' | 'evening' | 'all' — remembered.
  void _switchSession(String mode) {
    if (mode == _mode) return;
    SharedPreferences.getInstance().then((p) => p.setString(_modePrefKey, mode));
    final session = mode == 'auto' ? _defaultSession() : mode;
    _mode = mode;
    if (session == _session) {
      setState(() {});
      return;
    }
    _countdownTimer?.cancel();
    setState(() {
      _session = session;
      _loading = true;
    });
    _load();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('adc_already_review'))));
      return;
    }
    await KnowledgeReviewRepository().startReviewing('adhkar', item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t('adc_added_review').replaceAll('{screen}', _t('knowledge_review_title')))));
  }

  @override
  Widget build(BuildContext context) {
    final pageController = _pageController;
    final chromeMuted = _darkReading ? _readingHintDark : AppColors.textMuted;
    return Scaffold(
      backgroundColor: _darkReading ? _readingBackgroundDark : _readingBackground,
      body: _loading || pageController == null
          ? AppLoadingView(icon: Icons.spa_outlined, message: _t('ad_loading'))
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
                      itemBuilder: (context, index) => _PageDepth(
                        controller: pageController,
                        index: index,
                        child: index < _items.length
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
                                    child: Text(widget.category.title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: chromeMuted)),
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
                              if (_session != null)
                                _SessionToggle(mode: _mode, session: _session!, onChanged: _switchSession, color: chromeMuted),
                              if (_items.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _ProgressBar(total: _items.length, current: _currentIndex),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _alreadyDoneToday
                                          ? _t('adc_review_counter').replaceAll('{i}', '${_currentIndex < _items.length ? _currentIndex + 1 : _items.length}').replaceAll('{n}', '${_items.length}')
                                          : _t('adc_dua_counter').replaceAll('{i}', '${_currentIndex < _items.length ? _currentIndex + 1 : _items.length}').replaceAll('{n}', '${_items.length}'),
                                      style: TextStyle(fontSize: 10.5, color: chromeMuted, fontWeight: FontWeight.w600),
                                    ),
                                    if (!_alreadyDoneToday && _remainingSeconds > 0) ...[
                                      const SizedBox(width: 8),
                                      Text('·', style: TextStyle(fontSize: 10.5, color: chromeMuted)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _t('adc_remaining').replaceAll('{t}', _formatCountdown(_remainingSeconds)),
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

/// «تلقائي | الصباح | المساء | الكل» for the morning/evening chapter. The
/// chosen [mode] is solid; under «تلقائي» the session the clock picked is
/// softly marked so the reader still sees which one is open.
class _SessionToggle extends StatelessWidget {
  final String mode;
  final String session;
  final ValueChanged<String> onChanged;
  final Color color;
  const _SessionToggle({required this.mode, required this.session, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    Widget chip(String value, String key, IconData icon) {
      final on = mode == value;
      final soft = !on && mode == 'auto' && session == value;
      final fg = on || soft ? AppColors.primary : color;
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: on ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
            border: Border.all(color: soft ? AppColors.primary.withValues(alpha: 0.45) : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(_t(key), style: TextStyle(fontSize: 12, fontWeight: on ? FontWeight.w800 : FontWeight.w600, color: fg)),
          ]),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        chip('auto', 'adc_session_auto', Icons.schedule_rounded),
        chip('morning', 'adc_session_morning', Icons.wb_sunny_outlined),
        chip('evening', 'adc_session_evening', Icons.wb_twilight),
        chip('all', 'adc_session_all', Icons.view_agenda_outlined),
      ]),
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
              // a raised bead-button that presses in with each repetition
              child: TweenAnimationBuilder<double>(
                key: ValueKey(widget.remaining),
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                builder: (context, press, child) => Transform.translate(
                  offset: Offset(0, 3 * press),
                  child: Transform.scale(scale: 1 - 0.06 * press, child: child),
                ),
                child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.45),
                    colors: _done
                        ? [const Color(0xFF7FD3A0), AppColors.primary, AppColors.primaryDark]
                        : [Colors.white, AppColors.primaryLight, Color.lerp(AppColors.primaryLight, AppColors.primary, 0.35)!],
                    stops: const [0, 0.6, 1],
                  ),
                  border: Border.all(color: AppColors.primary, width: _done ? 0 : 1.2),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Center(
                  child: _done
                      ? const Icon(Icons.check, color: Colors.white, size: 26)
                      : Text('${widget.remaining}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primaryDark)),
                ),
              ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _done ? _t('adc_done_swipe') : _t('adc_tap_repeat'),
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
                label: Text(_t('adc_add_memorize'), style: const TextStyle(fontSize: 11.5)),
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
              Text(_t('adc_completed').replaceAll('{c}', categoryTitle), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: hintColor)),
              const SizedBox(height: 6),
              Text('جزاك الله خيرًا 🌿', style: TextStyle(fontSize: 13, color: hintColor)),
              const SizedBox(height: 28),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: onDone, child: Text(_t('feedback_done')))),
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

/// Depth for the swipe between adhkar: the page being left tilts away on
/// its outer edge and recedes, the next one comes forward from behind —
/// a turning card instead of a flat slide. Reads the controller's live
/// page, so it follows the finger and adds no gesture of its own.
class _PageDepth extends StatelessWidget {
  final PageController controller;
  final int index;
  final Widget child;
  const _PageDepth({required this.controller, required this.index, required this.child});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          double d = 0;
          if (controller.hasClients && controller.position.haveDimensions) {
            d = (controller.page ?? controller.initialPage.toDouble()) - index;
          }
          d = d.clamp(-1.0, 1.0);
          if (d == 0) return child!;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          // which edge is the hinge: the one nearer the screen centre
          final towardStart = (d > 0) == rtl;
          return Opacity(
            opacity: (1 - d.abs() * 0.35).clamp(0.0, 1.0),
            child: Transform(
              alignment: towardStart ? Alignment.centerLeft : Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0011)
                ..rotateY((towardStart ? -1 : 1) * d.abs() * 0.55)
                ..scaleByDouble(1 - d.abs() * 0.08, 1 - d.abs() * 0.08, 1, 1),
              child: child,
            ),
          );
        },
      );
}
