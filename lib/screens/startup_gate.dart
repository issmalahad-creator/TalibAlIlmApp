import 'package:flutter/material.dart';

import '../services/boot/boot_scheduler.dart';
import '../services/onboarding_service.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

/// Decides, once at app start, whether to show the first-launch tutorial or
/// go straight to [MainShell]. Kept as its own tiny widget so `main.dart`'s
/// `home:` stays a single, simple entry point.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    OnboardingService().hasSeenOnboarding().then((seen) {
      if (mounted) setState(() => _showOnboarding = !seen);
      if (!seen) BootScheduler.instance.markOnboardingShown();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      // Covered by BrandSplashGate; a plain page, never a second spinner.
      return const Scaffold(body: SizedBox.shrink());
    }
    if (_showOnboarding == true) {
      return OnboardingScreen(
        onDone: () {
          if (mounted) setState(() => _showOnboarding = false);
        },
      );
    }
    return const MainShell();
  }
}
