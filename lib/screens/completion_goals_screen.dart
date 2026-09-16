import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/language_preference_service.dart';
import '../widgets/completion_goal_list_view.dart';

/// "خطط ختمي" — QURAN_COMPANION_ROADMAP.md section 4.15. Create and track
/// completion plans for Quran reading, Quran memorization, or any book —
/// one shared screen, not one per content type. The list/card rendering and
/// the creation wizard both live in `completion_goal_list_view.dart`
/// (shared with the mushaf reader's reading-only "الختمات" bottom sheet);
/// this screen owns only the chrome (AppBar/FAB).
class CompletionGoalsScreen extends StatefulWidget {
  const CompletionGoalsScreen({super.key});

  @override
  State<CompletionGoalsScreen> createState() => _CompletionGoalsScreenState();
}

class _CompletionGoalsScreenState extends State<CompletionGoalsScreen> {
  final _listKey = GlobalKey<CompletionGoalListViewState>();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguagePreferenceService.languageNotifier,
      builder: (context, lang, _) => Scaffold(
        appBar: AppBar(title: Text(basicText('completion_goals_title', lang))),
        floatingActionButton: FloatingActionButton(
          onPressed: () => openNewCompletionGoalSheet(context, onCreated: () => _listKey.currentState?.reload()),
          child: const Icon(Icons.add),
        ),
        body: CompletionGoalListView(key: _listKey),
      ),
    );
  }
}
