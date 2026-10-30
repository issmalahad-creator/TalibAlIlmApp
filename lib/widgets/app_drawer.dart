import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/app_feature_registry.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../utils/arabic_normalize.dart';

/// The side menu: every feature of the app (`appFeatures`) in collapsible
/// sections, with a search box on top. Opened from the shell's «المزيد»
/// tab, Home's menu button, or a swipe from the side edge. Sections are
/// collapsed except the first, so the menu opens short; the search shows
/// matches from every section at once.
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(AppFeature f) {
    Navigator.pop(context); // close the drawer first
    Navigator.push(context, MaterialPageRoute(builder: f.builder));
  }

  bool _matches(AppFeature f, String q, String lang) {
    String n(String s) => normalizeArabicForSearch(s).toLowerCase();
    final nq = n(q);
    return [basicText(f.titleKey, lang), basicText(f.titleKey, 'ar'), basicText(f.titleKey, 'en'), ...f.names].any((s) => n(s).contains(nq));
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguagePreferenceService.currentLanguage;
    final q = _query.text.trim();
    final hits = q.isEmpty ? const <AppFeature>[] : appFeatures.where((f) => _matches(f, q, lang)).toList();
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
              child: Row(children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 30),
                const SizedBox(width: 10),
                Expanded(child: Text(basicText('drawer_title', lang), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryDark))),
                IconButton(tooltip: MaterialLocalizations.of(context).closeButtonTooltip, icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: basicText('drawer_search_hint', lang),
                  suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(_query.clear)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: q.isNotEmpty
                  ? (hits.isEmpty
                      ? Center(child: Text(basicText('drawer_no_match', lang), style: const TextStyle(color: AppColors.textMuted)))
                      : ListView(children: [for (final f in hits) _FeatureTile(f: f, lang: lang, onTap: () => _open(f))]))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        for (final g in AppFeatureGroup.values)
                          Theme(
                            // No divider lines between sections — calmer list.
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              key: PageStorageKey('drawer_${g.name}'),
                              initiallyExpanded: g == AppFeatureGroup.quran,
                              leading: Icon(_groupIcon(g), color: AppColors.primaryDark),
                              title: Text(basicText('feat_group_${g.name}', lang), style: const TextStyle(fontWeight: FontWeight.w700)),
                              childrenPadding: const EdgeInsetsDirectional.only(start: 12),
                              children: [
                                for (final f in appFeatures.where((f) => f.group == g)) _FeatureTile(f: f, lang: lang, onTap: () => _open(f)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _groupIcon(AppFeatureGroup g) => switch (g) {
        AppFeatureGroup.quran => Icons.auto_stories_outlined,
        AppFeatureGroup.worship => Icons.mosque_outlined,
        AppFeatureGroup.health => Icons.health_and_safety_outlined,
        AppFeatureGroup.knowledge => Icons.school_outlined,
        AppFeatureGroup.life => Icons.eco_outlined,
        AppFeatureGroup.community => Icons.groups_outlined,
        AppFeatureGroup.settings => Icons.settings_outlined,
      };
}

class _FeatureTile extends StatelessWidget {
  final AppFeature f;
  final String lang;
  final VoidCallback onTap;
  const _FeatureTile({required this.f, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(f.icon, color: AppColors.primary, size: 22),
        title: Text(basicText(f.titleKey, lang), style: const TextStyle(fontSize: 14.5)),
        onTap: onTap,
      );
}
