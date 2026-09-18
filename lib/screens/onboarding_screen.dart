import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

class _OnboardSlide {
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  const _OnboardSlide({required this.icon, required this.titleKey, required this.bodyKey});
}

const _slides = <_OnboardSlide>[
  _OnboardSlide(icon: Icons.mosque_rounded, titleKey: 'onboarding_slide1_title', bodyKey: 'onboarding_slide1_body'),
  _OnboardSlide(icon: Icons.menu_book_rounded, titleKey: 'onboarding_slide2_title', bodyKey: 'onboarding_slide2_body'),
  _OnboardSlide(icon: Icons.route_rounded, titleKey: 'onboarding_slide3_title', bodyKey: 'onboarding_slide3_body'),
  _OnboardSlide(icon: Icons.auto_stories_outlined, titleKey: 'onboarding_slide4_title', bodyKey: 'onboarding_slide4_body'),
  _OnboardSlide(icon: Icons.today_rounded, titleKey: 'onboarding_slide5_title', bodyKey: 'onboarding_slide5_body'),
];

/// KHATM_SYSTEM_AND_STYLE_REFERENCE.md §1.3 — a representative country flag
/// per offered language (Unicode emoji, no new asset needed), keyed exactly
/// to `supportedLanguages`' codes.
const _kLanguageFlags = <String, String>{
  'ar': '🇸🇦', 'en': '🇬🇧', 'am': '🇪🇹', 'fr': '🇫🇷', 'sw': '🇹🇿',
  'ur': '🇵🇰', 'tr': '🇹🇷', 'id': '🇮🇩', 'bn': '🇧🇩', 'ha': '🇳🇬',
  'so': '🇸🇴', 'fa': '🇮🇷', 'ms': '🇲🇾',
};

/// First-launch tutorial. Shown automatically once (gated by
/// [OnboardingService]) via [StartupGate], and re-openable any time from the
/// Home screen's help icon with [reviewMode] = true (in which case it just
/// closes instead of re-marking/navigating).
class OnboardingScreen extends StatefulWidget {
  final bool reviewMode;
  final VoidCallback? onDone;
  const OnboardingScreen({super.key, this.reviewMode = false, this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    if (widget.reviewMode) {
      Navigator.of(context).pop();
      return;
    }
    await OnboardingService().markSeen();
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// §1.3 — the language picker is page 0 of this same PageView (gated by
  /// the same "first launch only" `OnboardingService` flag, not a separate
  /// screen/flag), so [_slides] shift one page to the right.
  static final _pageCount = _slides.length + 1;

  Future<void> _pickLanguage(String code) async {
    await LanguagePreferenceService.setLanguage(code);
    if (mounted) _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pageCount - 1;
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(onPressed: _finish, child: Text(basicText('onboarding_skip', lang))),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    if (i == 0) return _LanguagePickerPage(lang: lang, onPicked: _pickLanguage);
                    final s = _slides[i - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                            child: Icon(s.icon, size: 56, color: AppColors.primary),
                          ),
                          const SizedBox(height: 32),
                          Text(basicText(s.titleKey, lang),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                          const SizedBox(height: 14),
                          Text(basicText(s.bodyKey, lang),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted, height: 1.6)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pageCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                    child: Text(isLast
                        ? basicText(widget.reviewMode ? 'onboarding_close' : 'onboarding_start_now', lang)
                        : basicText('onboarding_next', lang)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// §1.3 — page 0 of the onboarding `PageView`: a 2-column grid of language
/// cards (flag + native/English name, straight from the app's own real
/// `supportedLanguages`, not a fabricated list). Tapping a card sets
/// [LanguagePreferenceService] immediately and auto-advances — "التالي"
/// still works untouched (keeps whatever language is already current, 'ar'
/// by default) for a user who doesn't want to pick explicitly.
class _LanguagePickerPage extends StatelessWidget {
  final String lang;
  final ValueChanged<String> onPicked;
  const _LanguagePickerPage({required this.lang, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('🌐 ${basicText('onboarding_language_title', lang)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                for (final entry in supportedLanguages.entries)
                  _LanguageCard(
                    flag: _kLanguageFlags[entry.key] ?? '🌐',
                    label: entry.value,
                    selected: entry.key == lang,
                    onTap: () => onPicked(entry.key),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageCard({required this.flag, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
