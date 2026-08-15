import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// An eye-catching promo/notice banner shown on the Home screen, sourced from
/// whatever the admin most recently pushed via the Telegram bot's "🖼 إرسال
/// بانر" option (see [BannerInfo] / CLAUDE.md "Book content feed"). Purely
/// additive UI — if there's no banner, callers simply don't build this widget.
///
/// "Animated" = a soft fade/scale entrance when it first appears, plus (when
/// a caption is present) a continuously scrolling text ticker under the
/// image — no new package, just Flutter's own animation APIs.
class AnimatedBanner extends StatefulWidget {
  final String imageUrl;
  final String caption;

  const AnimatedBanner({super.key, required this.imageUrl, required this.caption});

  @override
  State<AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<AnimatedBanner> {
  bool _visible = false;
  bool _imageFailed = false;

  @override
  void initState() {
    super.initState();
    // Kick the entrance animation off one frame after first build so the
    // AnimatedXxx widgets actually animate from their initial state instead
    // of snapping straight to the end value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_imageFailed)
                Image.network(
                  widget.imageUrl,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 150,
                      color: AppColors.primaryLight,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (context, error, stack) {
                    // Defer the setState out of the build phase.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_imageFailed) setState(() => _imageFailed = true);
                    });
                    return const SizedBox.shrink();
                  },
                ),
              if (widget.caption.trim().isNotEmpty) _MarqueeCaption(text: widget.caption.trim()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Continuously-scrolling single-line text ticker (marquee), built with a
/// plain [AnimationController] — no extra package.
class _MarqueeCaption extends StatefulWidget {
  final String text;
  const _MarqueeCaption({required this.text});

  @override
  State<_MarqueeCaption> createState() => _MarqueeCaptionState();
}

class _MarqueeCaptionState extends State<_MarqueeCaption> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return LayoutBuilder(builder: (context, constraints) {
              // Scroll from fully off-screen on one side to fully off-screen
              // on the other so the ticker loops seamlessly.
              final dx = constraints.maxWidth - _controller.value * (constraints.maxWidth * 2.2);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            });
          },
          child: Text(
            widget.text,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
