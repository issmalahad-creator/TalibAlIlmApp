import 'package:shared_preferences/shared_preferences.dart';

import 'app_feature_registry.dart';

/// The side menu's per-person shortcuts: sections pinned with a long press,
/// and the last few opened. Ids are `AppFeature.id`; ids that no longer
/// exist (a feature renamed or removed) are dropped on read.
class DrawerPrefs {
  static const _pinnedKey = 'drawer_pinned';
  static const _recentKey = 'drawer_recent';
  static const recentMax = 3;

  static List<String> _known(List<String>? ids) {
    final valid = appFeatures.map((f) => f.id).toSet();
    return (ids ?? const []).where(valid.contains).toList();
  }

  Future<List<String>> pinned() async => _known((await SharedPreferences.getInstance()).getStringList(_pinnedKey));

  Future<List<String>> recent() async => _known((await SharedPreferences.getInstance()).getStringList(_recentKey));

  /// Pins or unpins [id]; returns whether it is pinned now.
  Future<bool> togglePin(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _known(prefs.getStringList(_pinnedKey));
    final pinnedNow = !list.remove(id);
    if (pinnedNow) list.add(id);
    await prefs.setStringList(_pinnedKey, list);
    return pinnedNow;
  }

  Future<void> markOpened(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, pushRecent(_known(prefs.getStringList(_recentKey)), id));
  }
}

/// Most recent first, no duplicates, at most [max].
List<String> pushRecent(List<String> recent, String id, {int max = DrawerPrefs.recentMax}) =>
    [id, ...recent.where((r) => r != id)].take(max).toList();
