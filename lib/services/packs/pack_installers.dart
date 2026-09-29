import 'dart:io';

import '../../repositories/quran_corpus_sync.dart';
import '../quran_import_service.dart';
import '../tts/tts_engine.dart' show ttsAssetBundled, ttsVoiceDir;
import '../tts/tts_voice_registry.dart';
import 'content_pack_engine.dart';
import 'pack_manifest.dart';

/// `corpus.<name>` packs (CP4): the downloaded `.json.gz` is seeded into the
/// same tables the bundled asset fills in the full build, so every panel
/// reads it with no change.
class CorpusTableInstaller implements PackInstaller {
  final _sync = QuranCorpusSync();

  String _name(PackInfo p) => p.id.substring('corpus.'.length);

  @override
  Future<bool> isBundled(PackInfo pack) => QuranCorpusSync.isBundled(_name(pack));

  @override
  Future<void> install(PackInfo pack, List<File> files) async =>
      _sync.seedFromFile(_name(pack), await files.single.readAsBytes());

  @override
  Future<void> uninstall(PackInfo pack) => _sync.clearDataset(_name(pack));
}

/// `tafsir.<key>` packs (CP5): imported into `tafsir_entries` exactly like a
/// bundled edition, so the reader, compare and search see it at once.
class LegacyTafsirInstaller implements PackInstaller {
  final _import = QuranImportService();

  String _key(PackInfo p) => p.id.substring('tafsir.'.length);

  @override
  Future<bool> isBundled(PackInfo pack) => QuranImportService.isTafsirBundled(_key(pack));

  @override
  Future<void> install(PackInfo pack, List<File> files) async =>
      _import.importTafsirFromBytes(_key(pack), await files.single.readAsBytes());

  @override
  Future<void> uninstall(PackInfo pack) => _import.removeTafsirEdition(_key(pack));
}

/// `voice.<name>` packs (S7): the TTS model is moved — not copied — to the
/// voice's own folder as `model.onnx`, exactly where the bundled build
/// extracts it, so the engine reads it with no other change.
class VoiceModelInstaller implements PackInstaller {
  TtsVoiceOption? _voice(PackInfo p) {
    for (final v in TtsVoiceRegistry.availableVoices) {
      if (v.packId == p.id) return v;
    }
    return null;
  }

  @override
  Future<bool> isBundled(PackInfo pack) async {
    final v = _voice(pack);
    return v != null && await ttsAssetBundled(v.modelAssetPath);
  }

  @override
  Future<void> install(PackInfo pack, List<File> files) async {
    final v = _voice(pack);
    if (v == null) throw StateError('no voice for ${pack.id}');
    final dir = await ttsVoiceDir(v);
    await dir.create(recursive: true);
    final model = File('${dir.path}/model.onnx');
    if (await model.exists()) await model.delete();
    try {
      await files.single.rename(model.path);
    } on FileSystemException {
      // Different filesystem — copy, then free the download.
      await files.single.copy(model.path);
      await files.single.delete();
    }
    // Force the engine to re-check tokens/espeak next time.
    final version = File('${dir.path}/.asset_version');
    if (await version.exists()) await version.delete();
  }

  @override
  Future<void> uninstall(PackInfo pack) async {
    final v = _voice(pack);
    if (v == null) return;
    final dir = await ttsVoiceDir(v);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

void registerPackInstallers([ContentPackEngine? engine]) {
  (engine ?? ContentPackEngine.instance)
    ..registerInstaller('corpus_table', CorpusTableInstaller())
    ..registerInstaller('legacy_tafsir', LegacyTafsirInstaller())
    ..registerInstaller('voice_model', VoiceModelInstaller());
}
