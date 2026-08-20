import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tahfeez_session_config.dart';

/// Persists the last تحفيظ session's config + position so
/// `QuranAudioEngine.resumeSession()` can pick up where the student left
/// off after closing the app mid-session — Ismail's explicit
/// `resumeSession()` requirement.
class TahfeezSessionPrefs {
  static const _configKey = 'tahfeez_last_session_config';
  static const _surahKey = 'tahfeez_last_position_surah';
  static const _ayahKey = 'tahfeez_last_position_ayah';

  Future<void> save(TahfeezSessionConfig config, int currentSurah, int currentAyah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    await prefs.setInt(_surahKey, currentSurah);
    await prefs.setInt(_ayahKey, currentAyah);
  }

  Future<(TahfeezSessionConfig, int, int)?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw == null) return null;
    final config = TahfeezSessionConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final surah = prefs.getInt(_surahKey) ?? config.surahFrom;
    final ayah = prefs.getInt(_ayahKey) ?? config.ayahFrom;
    return (config, surah, ayah);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    await prefs.remove(_surahKey);
    await prefs.remove(_ayahKey);
  }
}
