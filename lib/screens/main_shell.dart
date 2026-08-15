import 'package:flutter/material.dart';

import '../services/content_badge_service.dart';
import 'activities_screen.dart';
import 'book_screen.dart';
import 'goals_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goToTab(int i) => setState(() => _index = i);

  late final _tabs = [
    const HomeScreen(),
    const ActivitiesScreen(),
    const GoalsScreen(),
    const BookScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goToTab,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          const BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'الأنشطة'),
          const BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: 'الأهداف'),
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<bool>(
              valueListenable: ContentBadgeService.instance.hasUnseen,
              builder: (context, hasUnseen, child) => Badge(isLabelVisible: hasUnseen, child: child),
              child: const Icon(Icons.menu_book_rounded),
            ),
            label: 'الكتاب',
          ),
        ],
      ),
    );
  }
}
