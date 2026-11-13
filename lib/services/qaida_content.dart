import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/qaida.dart';

/// Loads the Qaida lessons (a 14 KB JSON, parsed on first open of the
/// Qaida — never at startup) and knows which sounds are recorded.
///
/// A sound "exists" only if its file is in the app bundle; until Ismail's
/// recordings are imported (`tool/qaida/import_recording.py`) a lesson
/// shows honestly that its sounds are not recorded yet.
class QaidaContent {
  QaidaContent._();
  static final QaidaContent instance = QaidaContent._();

  static const lessonsAsset = 'assets/qaida/qaida_lessons.json';

  List<QaidaLesson>? _lessons;
  Set<String>? _recorded;

  Future<List<QaidaLesson>> lessons({AssetBundle? bundle}) async {
    if (_lessons != null) return _lessons!;
    final raw = await (bundle ?? rootBundle).loadString(lessonsAsset);
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return _lessons = [for (final l in (j['lessons'] as List)) QaidaLesson.fromJson(l as Map<String, dynamic>)];
  }

  /// Audio ids that have a recorded file in the bundle.
  Future<Set<String>> recordedAudioIds({AssetBundle? bundle}) async {
    if (_recorded != null) return _recorded!;
    const prefix = 'assets/qaida/audio/';
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle ?? rootBundle);
      return _recorded = {
        for (final a in manifest.listAssets())
          if (a.startsWith(prefix) && a.endsWith('.m4a')) a.substring(prefix.length, a.length - 4),
      };
    } catch (_) {
      return _recorded = const {};
    }
  }

  /// For tests.
  void resetForTest() {
    _lessons = null;
    _recorded = null;
  }
}
