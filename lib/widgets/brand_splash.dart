import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_version.dart';
import '../l10n/basic_translations.dart';
import '../services/boot/boot_scheduler.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import 'feedback/light_trail.dart';

/// The brand moment laid over the first real screen while it gets ready
/// (docs/architecture/ZERO_WAIT_PROGRESSIVE_ARCHITECTURE.md §4, ZW-3).
///
/// It never waits for anything itself: [child] (StartupGate → onboarding or
/// Home) builds and loads underneath from the first frame; the splash only
/// leaves once that screen reports ready via
/// [BootScheduler.firstScreenReady] and the logo has had [minVisible] to be
/// seen — so a fast start is a short, calm reveal, never a flash, and a slow
/// start (first-launch seeding) is a composed wait, never a bare spinner.
class BrandSplashGate extends StatefulWidget {
  final Widget child;
  final Duration minVisible;

  /// Safety valve: even if the first screen never reports ready (a load
  /// error), the splash steps aside so the app is never held hostage.
  final Duration maxVisible;
  const BrandSplashGate({
    super.key,
    required this.child,
    this.minVisible = const Duration(milliseconds: 1400),
    this.maxVisible = const Duration(seconds: 12),
  });

  @override
  State<BrandSplashGate> createState() => _BrandSplashGateState();
}

class _BrandSplashGateState extends State<BrandSplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _exit =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  Timer? _minTimer;
  Timer? _maxTimer;
  bool _minElapsed = false;
  bool _forced = false;
  bool _gone = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    BootScheduler.instance.firstScreenReady.addListener(_maybeLeave);
    // The minimum brand moment counts from when it is actually visible.
    _whenFramesShown(() {
      if (!mounted) return;
      _minTimer = Timer(widget.minVisible, () {
        _minElapsed = true;
        _maybeLeave();
      });
    });
    _maxTimer = Timer(widget.maxVisible, () {
      _forced = true;
      _minElapsed = true;
      _maybeLeave();
    });
  }

  /// Leaves once the first screen is ready (or the safety valve fired) and
  /// the logo has been visible for at least [BrandSplashGate.minVisible].
  Future<void> _maybeLeave() async {
    final ready = _forced || BootScheduler.instance.firstScreenReady.value;
    if (_leaving || !ready || !_minElapsed || !mounted) return;
    _leaving = true;
    _maxTimer?.cancel();
    await _exit.forward();
    releaseBrandMark();
    if (mounted) setState(() => _gone = true);
  }

  @override
  void dispose() {
    BootScheduler.instance.firstScreenReady.removeListener(_maybeLeave);
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_gone)
          AnimatedBuilder(
            animation: _exit,
            builder: (context, splash) {
              final t = Curves.easeInCubic.transform(_exit.value);
              return IgnorePointer(
                ignoring: _leaving,
                child: Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(scale: 1 + 0.04 * t, child: splash),
                ),
              );
            },
            child: const BrandSplash(),
          ),
      ],
    );
  }
}

/// Ivory, light, gold — the feather-and-inkwell mark with a breathing glow.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key});

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> with TickerProviderStateMixin {
  /// One-shot entrance (logo → line → name → tagline).
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  /// Slow ambient loop: glow breathing, dust drift, gentle tilt, loader dot.
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();

  static const _statusKeys = ['splash_status_env', 'splash_status_library', 'splash_status_app'];
  int _status = 0;
  bool _showLoader = false;
  Timer? _loaderTimer;
  Timer? _statusTimer;

  static const _ink = Color(0xFF3B2A1A);
  static const _gold = Color(0xFFC9A24A);

  @override
  void initState() {
    super.initState();
    // The first frame may be held back until the mark is decoded
    // (holdFirstFrameUntilBrandMarkReady); start the rise only once pixels
    // are really on screen, so it is seen from the system-splash position.
    _whenFramesShown(() {
      if (mounted) _intro.forward();
    });
    // Only a wait that is actually long earns a loader and a message
    // (a fast start should never *look* like loading).
    _loaderTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showLoader = true);
    });
    _statusTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) setState(() => _status = (_status + 1) % _statusKeys.length);
    });
  }

  @override
  void dispose() {
    _loaderTimer?.cancel();
    _statusTimer?.cancel();
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Animation<double> _seg(double from, double to, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _intro, curve: Interval(from, to, curve: curve));

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final rise = _seg(0.0, 0.5, Curves.easeInOutCubic);
    final lineIn = _seg(0.35, 0.65);
    final nameIn = _seg(0.45, 0.75);
    final tagIn = _seg(0.6, 0.95);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      // Material (not a bare ColoredBox): the splash sits above the app's
      // Scaffold, and Text with no Material ancestor gets Flutter's yellow
      // "missing Material" underline in release builds.
      child: Material(
        color: AppColors.background,
        child: LayoutBuilder(builder: (context, box) {
          // Centre on the physical *screen*, like the native launch window
          // does — not on this view, which on Android 11 stops above the
          // navigation bar (the mark was 41 px too high at the hand-off).
          final display = View.of(context).display;
          final screenH = display.size.height / display.devicePixelRatio;
          final cy = (screenH > 0 ? screenH : box.maxHeight) / 2;
          // Final resting centre of the mark: lifted so the name and the
          // hadith sit below it with the whole group optically centred.
          final restY = cy - kBrandMarkLift;
          return Stack(
            children: [
              // Warm ivory glow + barely-there dust.
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _AtmospherePainter(_ambient, _gold)),
                ),
              ),
              // The mark starts exactly where and as big as the Android 12+
              // system splash drew it (screen centre, kBrandMarkStartHeight),
              // then rises and grows — one continuous motion, never a blink.
              AnimatedBuilder(
                animation: Listenable.merge([_intro, _ambient]),
                builder: (context, logo) {
                  final a = _ambient.value * 2 * math.pi;
                  final r = rise.value;
                  const start = kBrandMarkStartHeight / kBrandMarkHeight;
                  final scale = start + (1 - start) * r;
                  final centreY = cy + (restY - cy) * r;
                  // The ambient 3D drift fades in only as the mark settles.
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: centreY - kBrandMarkHeight / 2,
                    height: kBrandMarkHeight,
                    child: RepaintBoundary(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012) // perspective
                          ..translateByDouble(0.0, 3 * math.sin(a) * r, 0.0, 1.0)
                          ..rotateY(0.05 * math.sin(a) * r)
                          ..rotateX(0.025 * math.cos(a) * r)
                          ..scaleByDouble(scale, scale, 1.0, 1.0),
                        child: logo,
                      ),
                    ),
                  );
                },
                child: const Center(child: _Logo()),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: restY + kBrandMarkHeight / 2 + 22,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: lineIn,
                      builder: (context, _) => Container(
                        width: 110 * lineIn.value,
                        height: 1.2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0x00C9A24A), _gold, Color(0x00C9A24A)]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FadeUp(
                      animation: nameIn,
                      child: const Text(
                        'طالب العلم',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w700,
                          fontSize: 38,
                          height: 1.2,
                          color: _ink,
                          shadows: [Shadow(color: Color(0x33C9A24A), blurRadius: 12, offset: Offset(0, 2))],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FadeUp(
                      animation: tagIn,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          basicText('splash_tagline', lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 14.5,
                            height: 1.7,
                            color: _ink.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + 64,
                child: AnimatedOpacity(
                  opacity: _showLoader ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 86,
                        height: 6,
                        child: CustomPaint(painter: LightTrailPainter(_ambient, _gold)),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          basicText(_statusKeys[_status], lang),
                          key: ValueKey(_status),
                          style: TextStyle(fontSize: 12.5, color: _ink.withValues(alpha: 0.55)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + 16,
                child: Text(
                  'طالب العلم  •  ${basicText('splash_version', lang)} $kAppVersion',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, letterSpacing: 0.3, color: _ink.withValues(alpha: 0.32)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Height the Android 12+ system splash draws the mark at (measured on the
/// emulator 2026-09-26: 143 dp, screen-centred; `res/drawable-nodpi/
/// splash_mark.png`). The Flutter mark starts here so the hand-off is seamless.
const double kBrandMarkStartHeight = 143;

/// Final height of the mark on the brand splash, and how far it rises.
const double kBrandMarkHeight = 168;
const double kBrandMarkLift = 84;

/// The logo, decoded at display size. [holdFirstFrameUntilBrandMarkReady] warms this same
/// provider before the first frame so the mark is never a blank box.
ImageProvider brandMarkProvider(double devicePixelRatio) => ResizeImage(
      const AssetImage('assets/brand/quill_ink.webp'),
      height: (kBrandMarkHeight * devicePixelRatio).round(),
    );

/// Decodes the mark while Flutter's first frame is held back, then lets the
/// frame through. Until then Android keeps showing its own splash (the same
/// mark, same place), so the hand-off never shows an empty ivory page — the
/// emulator showed ~0.6 s of blank before this. Bounded by [maxHold] so a
/// slow decode can never delay boot noticeably.
void holdFirstFrameUntilBrandMarkReady({Duration maxHold = const Duration(milliseconds: 1200)}) {
  final binding = WidgetsBinding.instance;
  binding.deferFirstFrame();
  brandFirstFrameReleased.value = false;
  var released = false;
  void release() {
    if (released) return;
    released = true;
    binding.allowFirstFrame();
    brandFirstFrameReleased.value = true;
  }

  final dpr = binding.platformDispatcher.views.first.devicePixelRatio;
  final stream = brandMarkProvider(dpr).resolve(ImageConfiguration.empty);
  final listener = ImageStreamListener((_, _) => release(), onError: (_, _) => release());
  stream.addListener(listener);
  // Held until the splash leaves: keeps the decoded frame live in the image
  // cache until the splash's own Image subscribes (see releaseBrandMark).
  _precacheHold = (stream, listener);
  Timer(maxHold, release);
}

/// False while the first frame is held back; the splash's clocks (entrance
/// animation, minimum visible time) start only when it flips to true, so
/// nothing "happens" while the user can't see it. True by default (tests,
/// or if the hold is never used).
final ValueNotifier<bool> brandFirstFrameReleased = ValueNotifier(true);

/// Runs [fn] once frames are being shown.
void _whenFramesShown(VoidCallback fn) {
  if (brandFirstFrameReleased.value) {
    fn();
    return;
  }
  void l() {
    if (!brandFirstFrameReleased.value) return;
    brandFirstFrameReleased.removeListener(l);
    fn();
  }

  brandFirstFrameReleased.addListener(l);
}

(ImageStream, ImageStreamListener)? _precacheHold;

/// Lets the precached mark be evicted normally once the splash is gone.
void releaseBrandMark() {
  final h = _precacheHold;
  _precacheHold = null;
  h?.$1.removeListener(h.$2);
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    const w = kBrandMarkHeight * 428 / 560; // source aspect ratio
    return SizedBox(
      width: w,
      height: kBrandMarkHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Image(
            image: brandMarkProvider(MediaQuery.devicePixelRatioOf(context)),
            width: w,
            height: kBrandMarkHeight,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ],
      ),
    );
  }
}

class _FadeUp extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _FadeUp({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) => Opacity(
        opacity: animation.value,
        child: Transform.translate(offset: Offset(0, 8 * (1 - animation.value)), child: c),
      ),
      child: child,
    );
  }
}

/// Radial ivory "light of knowledge" that breathes, plus 18 slow dust motes
/// at fixed seeded positions (deterministic — no allocation per frame).
class _AtmospherePainter extends CustomPainter {
  final Animation<double> t;
  final Color gold;
  _AtmospherePainter(this.t, this.gold) : super(repaint: t);

  static final _motes = List.generate(18, (i) {
    final r = math.Random(1441 + i);
    return (x: r.nextDouble(), y: r.nextDouble(), size: 0.8 + r.nextDouble() * 1.6, speed: 0.3 + r.nextDouble() * 0.7, phase: r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final a = t.value * 2 * math.pi;
    final breathe = 0.5 + 0.5 * math.sin(a);
    final center = Offset(size.width / 2, size.height * 0.40);
    final radius = size.width * (0.62 + 0.05 * breathe);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.lerp(const Color(0xFFFFFCF3), const Color(0xFFFFF8E6), breathe)!,
          const Color(0x00FBF2D9),
        ]).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final mote = Paint();
    for (final m in _motes) {
      final p = (m.phase + t.value * m.speed) % 1.0;
      final y = (m.y - p * 0.25) % 1.0;
      final flicker = 0.5 + 0.5 * math.sin(a * 2 + m.phase * 6);
      mote.color = gold.withValues(alpha: 0.05 + 0.09 * flicker);
      canvas.drawCircle(Offset(m.x * size.width, y * size.height), m.size, mote);
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) => false;
}
