import 'package:flutter/material.dart';

import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardSlide({required this.icon, required this.title, required this.body});
}

const _slides = <_OnboardSlide>[
  _OnboardSlide(
    icon: Icons.mosque_rounded,
    title: 'مرحباً بك 👋',
    body: 'تطبيق رابطة خريجي جامعة السنة يساعدك على تسجيل أنشطتك اليومية، متابعة أهدافك، وإرسال تقريرك الشهري بسهولة — حتى بدون إنترنت.',
  ),
  _OnboardSlide(
    icon: Icons.home_rounded,
    title: 'الرئيسية ومهام اليوم',
    body: 'من الشاشة الرئيسية تتابع نسبة تقدمك ومهام اليوم، ويمكنك إضافة مهمة جديدة والحصول على تذكير بها في وقتها.',
  ),
  _OnboardSlide(
    icon: Icons.flag_rounded,
    title: 'الأهداف الشهرية',
    body: 'حدّد أهدافك لهذا الشهر من تبويب "الأهداف"، وتابع نسبة إنجازها أولاً بأول.',
  ),
  _OnboardSlide(
    icon: Icons.menu_book_rounded,
    title: 'كتاب الشهر',
    body: 'يرسل لك المشرف كتاب الشهر عبر تلجرام فيظهر مباشرة في تبويب "الكتاب"، مع اختبار قصير في نهايته، وقد تصلك عدة كتب مع الوقت.',
  ),
  _OnboardSlide(
    icon: Icons.send_rounded,
    title: 'التقرير الشهري',
    body: 'في نهاية الشهر، أرسل تقريرك مباشرة من تبويب "التقرير". إن لم يتوفر إنترنت الآن سيُحفظ ويُرسل تلقائياً عند توفره.',
  ),
];

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

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(onPressed: _finish, child: const Text('تخطي')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
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
                        Text(s.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        const SizedBox(height: 14),
                        Text(s.body,
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
                _slides.length,
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
                  child: Text(isLast ? (widget.reviewMode ? 'إغلاق' : 'ابدأ الآن') : 'التالي'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
