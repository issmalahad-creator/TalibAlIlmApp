import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/content_badge_service.dart';
import '../services/language_preference_service.dart';
import '../services/start_screen_preference_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/side_menu_tab.dart';
import 'activities_screen.dart';
import 'book_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';
import 'mushaf_semantic_reader_screen.dart';

/// The shell's Scaffold — Home's menu button opens the side menu through it
/// (Home sits in its own nested Scaffold, so `Scaffold.of` would miss it).
final mainShellScaffoldKey = GlobalKey<ScaffoldState>();

/// Opens the side menu from anywhere: back to the root screen first (the
/// menu belongs to the shell underneath), then open it.
void openSideMenu(BuildContext context) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  mainShellScaffoldKey.currentState?.openDrawer();
}

/// The app's root. Two layouts, chosen in settings
/// (`StartScreenPreferenceService`):
/// * **المصحف** (default): the muṣḥaf fills the screen, resuming the last
///   page; every section lives in the side menu, opened from the reader's
///   «كل الأقسام» button, its side tab or an edge swipe.
/// * **الرئيسية**: the dashboard Home with its bottom tabs, as before.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: StartScreenPreferenceService.notifier,
      builder: (context, start, _) => Scaffold(
        key: mainShellScaffoldKey,
        drawer: const AppDrawer(),
        // A wide edge strip: on a phone the default 20 px is easy to miss.
        drawerEdgeDragWidth: 28,
        body: start == StartScreenPreferenceService.home
            ? const _TabbedHome()
            : MushafSemanticReaderScreen(asHome: true, onOpenSections: () => mainShellScaffoldKey.currentState?.openDrawer()),
      ),
    );
  }
}

/// The dashboard layout: Home + three tabs + «المزيد».
class _TabbedHome extends StatefulWidget {
  const _TabbedHome();

  @override
  State<_TabbedHome> createState() => _TabbedHomeState();
}

class _TabbedHomeState extends State<_TabbedHome> {
  int _index = 0;

  void _goToTab(int i) {
    // The fifth item is «المزيد»: it opens the side menu, it is not a tab.
    if (i == _tabs.length) {
      mainShellScaffoldKey.currentState?.openDrawer();
      return;
    }
    if (i == 0 && _index != 0) homeRefreshTick.value++;
    setState(() => _index = i);
  }

  late final _tabs = [
    const HomeScreen(),
    const ActivitiesScreen(),
    const GoalsScreen(),
    const BookScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _tabs),
          // Always-visible way into every section (see SideMenuTab).
          PositionedDirectional(
            start: 0,
            top: MediaQuery.sizeOf(context).height * 0.42,
            child: SideMenuTab(onOpen: () => mainShellScaffoldKey.currentState?.openDrawer()),
          ),
        ],
      ),
      // 2026-08-17: was 4 hardcoded Arabic labels — the single most
      // persistent, always-visible piece of chrome in the app, and the
      // first thing Ismail's language-coverage audit flagged. Now reacts
      // live to `LanguagePreferenceService.languageNotifier`, same pattern
      // `main.dart` already uses for locale/direction.
      bottomNavigationBar: ValueListenableBuilder<String>(
        valueListenable: LanguagePreferenceService.languageNotifier,
        builder: (context, lang, _) => BottomNavigationBar(
          currentIndex: _index,
          onTap: _goToTab,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: basicText('nav_home', lang)),
            BottomNavigationBarItem(icon: const Icon(Icons.checklist_rounded), label: basicText('nav_activities', lang)),
            BottomNavigationBarItem(icon: const Icon(Icons.flag_rounded), label: basicText('nav_goals', lang)),
            BottomNavigationBarItem(
              icon: ValueListenableBuilder<bool>(
                valueListenable: ContentBadgeService.instance.hasUnseen,
                builder: (context, hasUnseen, child) => Badge(isLabelVisible: hasUnseen, child: child),
                child: const Icon(Icons.menu_book_rounded),
              ),
              label: basicText('nav_book', lang),
            ),
            BottomNavigationBarItem(icon: const Icon(Icons.menu_rounded), label: basicText('nav_more', lang)),
          ],
        ),
      ),
    );
  }
}
