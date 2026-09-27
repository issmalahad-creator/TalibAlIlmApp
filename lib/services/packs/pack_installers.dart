import 'dart:io';

import '../../repositories/quran_corpus_sync.dart';
import '../quran_import_service.dart';
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

void registerPackInstallers([ContentPackEngine? engine]) {
  (engine ?? ContentPackEngine.instance)
    ..registerInstaller('corpus_table', CorpusTableInstaller())
    ..registerInstaller('legacy_tafsir', LegacyTafsirInstaller());
}
