import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talib_alilm_app/services/quran_corpus_download_service.dart';

/// The lite build strips `assets/quran/corpus/{translations,tafsir}` and
/// downloads a book the first time it's opened. Every book the full build
/// bundles must be reachable that way: the `corpus-v1` release, or — for
/// books added after it was published — the pinned repo commit behind the
/// raw/jsDelivr fallbacks. This checks that commit really holds each one.
void main() {
  test('fallback sources point at the pinned commit, per category', () {
    final s = QuranCorpusDownloadService.sourcesFor('tafsir', 18);
    expect(s.first.toString(), endsWith('/releases/download/corpus-v1/18.json.gz'));
    expect(s[1].path, contains('/assets/quran/corpus/tafsir/18.json.gz'));
    expect(s[2].host, 'cdn.jsdelivr.net');
  });

  test('every bundled book exists, identical, in the pinned commit', () {
    final commit = QuranCorpusDownloadService.sourcesFor('tafsir', 1)[1].pathSegments[2];
    final probe = Process.runSync('git', ['cat-file', '-e', '$commit^{commit}']);
    if (probe.exitCode != 0) {
      markTestSkipped('pinned commit not in this clone (shallow checkout)');
      return;
    }
    final missing = <String>[];
    for (final cat in ['translations', 'tafsir']) {
      for (final f in Directory('assets/quran/corpus/$cat').listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        final r = Process.runSync('git', ['cat-file', '-s', '$commit:assets/quran/corpus/$cat/$name']);
        if (r.exitCode != 0 || int.parse((r.stdout as String).trim()) != f.lengthSync()) missing.add('$cat/$name');
      }
    }
    expect(missing, isEmpty, reason: 'move _pinnedCommit to a commit that has them');
  });
}
