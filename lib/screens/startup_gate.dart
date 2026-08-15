import 'package:flutter/material.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
