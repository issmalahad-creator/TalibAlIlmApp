import 'package:flutter/material.dart';

import '../l10n/basic_translations.dart';
import '../services/app_feature_registry.dart';
import '../services/drawer_prefs.dart';
import '../services/language_preference_service.dart';
import '../theme/app_theme.dart';
import '../utils/arabic_normalize.dart';

/// The side menu: every feature of the app (`appFeatures`) in collapsible
/// sections, with a search box on top. Opened from the shell's «المزيد»
/// tab, Home's menu button, or a swipe from the side edge. Sections are
/// collapsed except the first, so the menu opens short; the search shows
/// matches from every section at once. On top: the person's pinned sections
/// (long-press any section to pin / unpin) and the last [DrawerPrefs.recentMax]
/// opened — the drawer is rebuilt on every open, so both are always fresh.
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _query = TextEditingController();
  final _prefs = DrawerPrefs();
  List<String> _pinned = const [];
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final pinned = await _prefs.pinned();
    final recent = await _prefs.recent();
    if (mounted) {
      setState(() {
        _pinned = pinned;
        _recent = recent;
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(AppFeature f) {
    _prefs.markOpened(f.id);
    Navigator.pop(context); // close the drawer first
    Navigator.push(context, MaterialPageRoute(builder: f.builder));
  }

  Future<void> _togglePin(AppFeature f, String lang) async {
    final pinnedNow = await _prefs.togglePin(f.id);
    await _loadShortcuts();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(basicText(pinnedNow ? 'drawer_pinned_done' : 'drawer_unpinned_done', lang).replaceAll('{name}', basicText(f.titleKey, lang))),
      ));
  }

  AppFeature? _byId(String id) => appFeatures.where((f) => f.id == id).firstOrNull;

  Widget _tile(AppFeature f, String lang) => _FeatureTile(
        f: f,
        lang: lang,
        pinned: _pinned.contains(f.id),
        onTap: () => _open(f),
        onLongPress: () => _togglePin(f, lang),
      );

  Widget _shortcutHeader(IconData icon, String text) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 2),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ]),
      );

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
                      : ListView(children: [for (final f in hits) _tile(f, lang)]))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _shortcutHeader(Icons.push_pin_outlined, basicText('drawer_pinned', lang)),
                        if (_pinned.isEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 6),
                            child: Text(basicText('drawer_pin_hint', lang), style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                          )
                        else
                          for (final id in _pinned)
                            if (_byId(id) case final f?) _tile(f, lang),
                        if (_recent.isNotEmpty) ...[
                          _shortcutHeader(Icons.history_rounded, basicText('drawer_recent', lang)),
                          for (final id in _recent)
                            if (_byId(id) case final f?) _tile(f, lang),
                        ],
                        const Divider(indent: 16, endIndent: 16),
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
                                for (final f in appFeatures.where((f) => f.group == g)) _tile(f, lang),
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
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _FeatureTile({required this.f, required this.lang, required this.pinned, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(f.icon, color: AppColors.primary, size: 22),
        title: Text(basicText(f.titleKey, lang), style: const TextStyle(fontSize: 14.5)),
        trailing: pinned ? const Icon(Icons.push_pin_rounded, size: 16, color: Color(0xFFD9A441)) : null,
        onTap: onTap,
        onLongPress: onLongPress,
      );
}
