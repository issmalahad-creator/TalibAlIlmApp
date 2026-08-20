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
    title: 'مرحباً بك في طالب العلم 👋',
    body: 'رفيقك في حفظ القرآن وفهمه وتطبيقه — مع الحديث والعقيدة والأذكار والتجويد وأكثر، كل ذلك بلا إنترنت ولا إعلانات.',
  ),
  _OnboardSlide(
    icon: Icons.menu_book_rounded,
    title: 'حفظ القرآن ومراجعته',
    body: 'اقرأ المصحف صفحة بصفحة برسم عثماني حقيقي، احفظ بوتيرتك الخاصة، وراجع بمحرك مراجعة ذكي (6 محطات) يذكّرك بالوقت الأمثل لكل صفحة قبل أن تُنسى.',
  ),
  _OnboardSlide(
    icon: Icons.route_rounded,
    title: 'رحلتك ومدرّب الحفظ',
    body: 'من "رحلتي" حدّد هدف ختمك وتابع وتيرتك المتكيفة يومًا بيوم — بالموعد أو متأخر أو متقدم — بلا ضغط ولا معاقبة عند الانقطاع.',
  ),
  _OnboardSlide(
    icon: Icons.auto_stories_outlined,
    title: 'أبعد من القرآن',
    body: 'الأربعون النووية، العقيدة الواسطية، أحكام التجويد، حصن المسلم للأذكار، ودروس تطبيقية — كل علم له مكانه ومراجعته الخاصة.',
  ),
  _OnboardSlide(
    icon: Icons.today_rounded,
    title: 'جلسة اليوم ورفيقك',
    body: 'ابدأ "جلسة اليوم" لخطة موجّهة بالوقت المتاح لديك، ورفيق طالب العلم معك يشجعك ويذكّرك — كل هذا يعمل بالكامل دون اتصال بالإنترنت.',
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
