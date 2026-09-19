import 'dart:io';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;

import 'tts_voice_registry.dart';

/// On-demand download/cache for the bundled TTS voice model + espeak-ng
/// phoneme data (~62MB total, dominated by `model.onnx` at ~63MB — the other
/// 8 files are KB-sized) that a "lite" app build ships without bundling.
/// Mirrors `QuranCorpusDownloadService`'s established pattern (same GitHub
/// Release hosting convention, same cache-first `File.exists()` check, same
/// never-throws-degrades-gracefully contract) — see
/// `lib/services/quran_corpus_download_service.dart`.
///
/// [TtsEngine._ensureVoiceExtracted] tries `rootBundle.load()` (the bundled
/// asset) first and falls back to this service only when the asset is
/// absent from the bundle — so the "full" build (voice bundled) never
/// touches the network, and the "lite" build (voice excluded from
/// pubspec.yaml assets) gets the exact same on-disk layout either way.
class TtsVoiceDownloadService {
  TtsVoiceDownloadService._();
  static final TtsVoiceDownloadService instance = TtsVoiceDownloadService._();

  static const _releaseBase = 'https://github.com/issmalahad-creator/TalibAlIlmApp/releases/download/tts-voice-v1';

  /// `(received, total)` for the in-flight `model.onnx` download (the file
  /// that dominates size and download time) keyed by voiceId. `total` is
  /// null when the server didn't send a content-length. Absent from the map
  /// when nothing is downloading for that voice — mirrors
  /// `QuranCorpusDownloadService.progressOf`, so the same progress-bar
  /// widget pattern can drive both.
  final Map<String, ValueNotifier<(int, int?)?>> _progress = {};

  ValueNotifier<(int, int?)?> progressOf(String voiceId) => _progress.putIfAbsent(voiceId, () => ValueNotifier(null));

  /// The same 9 files `TtsEngine._ensureVoiceExtracted` extracts from the
  /// asset bundle, as (relativePathUnderReleaseDir, destination) pairs —
  /// kept in sync with that extraction so a downloaded voice and a
  /// bundle-extracted voice produce byte-identical on-disk layouts.
  List<(String, File)> _filesFor(TtsVoiceOption voice, Directory voiceDir) {
    final espeakDir = Directory('${voiceDir.path}/espeak-ng-data');
    return [
      ('model.onnx', File('${voiceDir.path}/model.onnx')),
      ('tokens.txt', File('${voiceDir.path}/tokens.txt')),
      for (final f in voice.espeakDataFiles) ('espeak-ng-data/$f', File('${espeakDir.path}/$f')),
    ];
  }

  /// Downloads every file this voice needs into [voiceDir] (skipping any
  /// that already exist there), reporting real byte progress for
  /// `model.onnx` via [progressOf] since it's ~98% of the total size — the
  /// other 8 files are KB-sized and download near-instantly with no
  /// granular progress. Returns false (never throws) on any failure —
  /// network error, 404, timeout — so a missing voice degrades to "TTS
  /// unavailable" in the UI rather than crashing the reader. Partial
  /// downloads are deleted so a retry doesn't mistake a truncated file for
  /// a cached one.
  Future<bool> ensureVoiceDownloaded(TtsVoiceOption voice, Directory voiceDir) async {
    for (final (relativePath, dest) in _filesFor(voice, voiceDir)) {
      if (await dest.exists()) continue;
      final ok = relativePath == 'model.onnx'
          ? await _downloadWithProgress(voice.voiceId, relativePath, dest)
          : await _downloadPlain(voice.voiceId, relativePath, dest);
      if (!ok) return false;
    }
    return true;
  }

  Future<bool> _downloadPlain(String voiceId, String relativePath, File dest) async {
    final uri = Uri.parse('$_releaseBase/${voiceId.replaceAll(':', '_')}/$relativePath');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) return false;
      await dest.parent.create(recursive: true);
      await dest.writeAsBytes(resp.bodyBytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _downloadWithProgress(String voiceId, String relativePath, File dest) async {
    final uri = Uri.parse('$_releaseBase/${voiceId.replaceAll(':', '_')}/$relativePath');
    final notifier = progressOf(voiceId);
    final client = http.Client();
    try {
      final req = http.Request('GET', uri);
      final streamed = await client.send(req).timeout(const Duration(seconds: 120));
      if (streamed.statusCode != 200) return false;
      final total = streamed.contentLength;
      await dest.parent.create(recursive: true);
      final sink = dest.openWrite();
      var received = 0;
      notifier.value = (0, total);
      try {
        await for (final chunk in streamed.stream) {
          sink.add(chunk);
          received += chunk.length;
          notifier.value = (received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      return true;
    } catch (_) {
      if (await dest.exists()) await dest.delete();
      return false;
    } finally {
      notifier.value = null;
      client.close();
    }
  }
}
