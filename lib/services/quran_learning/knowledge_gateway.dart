import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import '../../data/tajweed_rules_ref.dart';
import '../../db/database_helper.dart';
import '../../models/quran_learning.dart';

/// Phase 79 `79-ql` — AD‑1 (`docs/quran/QURAN_LIVE_DATA_ARCHITECTURE.md`):
/// **one gateway, many providers.** The UI calls [KnowledgeGateway.factsFor]
/// and never a concrete source. Each provider resolves LOCAL (bundled),
/// ONLINE (fetched, not stored) or HYBRID (fetched + cached per terms). No
/// provider is a dependency — one failing never fails the panel; a domain
/// with nothing returns empty (the UI shows "لا توجد بيانات موثقة").
abstract class KnowledgeProvider {
  /// Domains this provider can answer for.
  Set<String> get domains;

  /// Facts for one word. Best-effort. Return `[]` on any failure — never throw.
  Future<List<KnowledgeFact>> factsFor(int surah, int ayah, int wordIndex);

  /// Facts for a whole ayah (the Ayah Knowledge Surface). Default: none —
  /// a provider overrides this only if it has ayah-level material. Same
  /// best-effort contract.
  Future<List<KnowledgeFact>> factsForAyah(int surah, int ayah) async => const [];
}

class KnowledgeGateway {
  KnowledgeGateway._();
  static final KnowledgeGateway instance = KnowledgeGateway._();

  final List<KnowledgeProvider> _providers = [
    // P0: Quranic grammar. QAC is the first grammar provider (Ismail
    // 2026-08-30). It is registered ONLINE and consulted only when the
    // LOCAL grammar has no fact — but stays disabled until a real endpoint
    // + online-use licence are confirmed (see QURAN_SOURCES_AND_LICENSES.md
    // §A1, QURAN_LIVE_DATA_ARCHITECTURE.md L-MORPH/L-SYNTAX). Same pattern
    // as QuranFoundationProvider in the audio stack.
    QacGrammarProvider(),
    LocalKnowledgeProvider(),
    CorpusTajweedProvider(),
    LocalTafsirProvider(),
    // more ONLINE/HYBRID providers (meaning, audio, …) register here with
    // no change to callers.
  ];

  /// All facts for a word, grouped by domain, plus the sources they cite,
  /// plus the worst dataState seen (so the UI can flag partial-online).
  Future<KnowledgeResult> factsFor({
    required int surah,
    required int ayah,
    required int wordIndex,
    Set<String>? domains,
  }) async {
    final byDomain = <String, List<KnowledgeFact>>{};
    var worst = KnowledgeDataState.local;

    for (final p in _providers) {
      if (domains != null && p.domains.intersection(domains).isEmpty) continue;
      try {
        for (final f in await p.factsFor(surah, ayah, wordIndex)) {
          if (f.mappingStatus != 'mapped') continue; // not renderable on the page
          (byDomain[f.domain] ??= <KnowledgeFact>[]).add(f);
          if (f.dataState.index > worst.index) worst = f.dataState;
        }
      } catch (e) {
        debugPrint('KnowledgeGateway: provider ${p.runtimeType} failed ($e) — skipped.');
      }
    }

    final sources = <String, SourceReference>{};
    final ids = {
      for (final list in byDomain.values)
        for (final f in list) f.sourceRefId
    };
    if (ids.isNotEmpty) {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('source_references',
          where: 'id IN (${List.filled(ids.length, '?').join(',')})', whereArgs: ids.toList());
      for (final r in rows) {
        final s = SourceReference.fromRow(r);
        sources[s.id] = s;
      }
    }

    // Display gate: drop any fact whose source can't be shown as a claim.
    byDomain.updateAll((_, list) =>
        list.where((f) => sources[f.sourceRefId]?.displayable ?? false).toList());
    byDomain.removeWhere((_, list) => list.isEmpty);

    return KnowledgeResult(
      byDomain: byDomain,
      sources: sources,
      overallState: byDomain.isEmpty ? KnowledgeDataState.unavailable : worst,
    );
  }

  /// Which domains have any fact for this word (for the launcher panel).
  Future<Set<String>> availableDomains(int surah, int ayah, int wordIndex) async {
    final r = await factsFor(surah: surah, ayah: ayah, wordIndex: wordIndex);
    return r.byDomain.keys.toSet();
  }

  /// All facts for a whole ayah, grouped by domain — feeds the Ayah
  /// Knowledge Surface. Same display gate + source loading as [factsFor].
  Future<KnowledgeResult> factsForAyah({
    required int surah,
    required int ayah,
    Set<String>? domains,
  }) async {
    final byDomain = <String, List<KnowledgeFact>>{};
    var worst = KnowledgeDataState.local;

    for (final p in _providers) {
      if (domains != null && p.domains.intersection(domains).isEmpty) continue;
      try {
        for (final f in await p.factsForAyah(surah, ayah)) {
          if (f.mappingStatus != 'mapped') continue;
          (byDomain[f.domain] ??= <KnowledgeFact>[]).add(f);
          if (f.dataState.index > worst.index) worst = f.dataState;
        }
      } catch (e) {
        debugPrint('KnowledgeGateway.factsForAyah: ${p.runtimeType} failed ($e) — skipped.');
      }
    }

    final sources = <String, SourceReference>{};
    final ids = {
      for (final list in byDomain.values)
        for (final f in list) f.sourceRefId
    };
    if (ids.isNotEmpty) {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('source_references',
          where: 'id IN (${List.filled(ids.length, '?').join(',')})',
          whereArgs: ids.toList());
      for (final r in rows) {
        final s = SourceReference.fromRow(r);
        sources[s.id] = s;
      }
    }

    byDomain.updateAll((_, list) =>
        list.where((f) => sources[f.sourceRefId]?.displayable ?? false).toList());
    byDomain.removeWhere((_, list) => list.isEmpty);

    return KnowledgeResult(
      byDomain: byDomain,
      sources: sources,
      overallState: byDomain.isEmpty ? KnowledgeDataState.unavailable : worst,
    );
  }
}

/// ONLINE provider — **Quranic Arabic Corpus** as the first Quranic-grammar
/// provider (Ismail's P0). QAC's morphology is complete; its dependency
/// treebank (iʿrāb) is partial and still being extended upstream — an
/// online provider fits it well.
///
/// **Deliberately inert in this build** (`_enabled = false`): there is no
/// documented public REST endpoint for QAC iʿrāb that a shipped app may
/// call, and online use/redistribution terms are not yet verified for that
/// path (bundling the *downloaded* dataset IS permitted — verbatim,
/// attribution + link — and that is how the Prototype's ṣarf layer is
/// already sourced). When a real endpoint + terms are confirmed, wire the
/// fetch here (via our proxy) → `KnowledgeFact(dataState: online|cached)`;
/// callers do not change.
class QacGrammarProvider extends KnowledgeProvider {
  static const bool _enabled = false;

  @override
  Set<String> get domains => const {'sarf', 'nahw'};

  @override
  Future<List<KnowledgeFact>> factsFor(int surah, int ayah, int wordIndex) async {
    if (!_enabled) return const [];
    // TODO(79-ql): fetch grammar for (surah:ayah:wordIndex) from the QAC
    // proxy, map its segmentation → mushafdb-v1.01, return facts with
    // source_ref_id 'src:qac' and dataState online/cached. Never throw.
    return const [];
  }
}

/// LOCAL provider — the bundled `knowledge_facts` seeded by
/// `QuranLearningSync` (ṣarf / naḥw for the Prototype slice).
///
/// `tajweed` moved to [CorpusTajweedProvider] in Phase G-t1 (all 6236 ayāt,
/// from `quran_tajweed`, instead of the 11 Prototype ayāt here) — dropped
/// from `domains` so the two never double-render the same word.
class LocalKnowledgeProvider extends KnowledgeProvider {
  @override
  Set<String> get domains => const {'sarf', 'nahw', 'meaning'};

  @override
  Future<List<KnowledgeFact>> factsFor(int surah, int ayah, int wordIndex) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'knowledge_facts',
      where: 'surah = ? AND ayah = ? AND word_start <= ? AND word_end >= ?',
      whereArgs: [surah, ayah, wordIndex, wordIndex],
      orderBy: 'domain ASC, id ASC',
    );
    return [for (final r in rows) KnowledgeFact.fromRow(r)];
  }

  @override
  Future<List<KnowledgeFact>> factsForAyah(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'knowledge_facts',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      orderBy: 'domain ASC, word_start ASC, id ASC',
    );
    return [for (final r in rows) KnowledgeFact.fromRow(r)];
  }
}

/// LOCAL provider — tajwīd rules for **all 6236 ayāt** from `quran_tajweed`
/// (Phase G-t1, migration v56), seeded by `QuranCorpusSync` from
/// `assets/quran/corpus/tajweed.json.gz` (cpfair/quran-tajweed, rule data
/// CC BY 4.0). One fact per word that carries ≥1 rule; `payload['rules']` is
/// the list the knowledge surface already renders — label / family / concept
/// are resolved from [kTajweedRules], not stored.
class CorpusTajweedProvider extends KnowledgeProvider {
  @override
  Set<String> get domains => const {'tajweed'};

  @override
  Future<List<KnowledgeFact>> factsFor(int surah, int ayah, int wordIndex) async {
    final byWord = await _byWord(surah, ayah);
    final f = byWord[wordIndex];
    return f == null ? const [] : [f];
  }

  @override
  Future<List<KnowledgeFact>> factsForAyah(int surah, int ayah) async {
    final byWord = await _byWord(surah, ayah);
    final ws = byWord.keys.toList()..sort();
    return [for (final w in ws) byWord[w]!];
  }

  /// `word_index -> one tajweed KnowledgeFact` for the ayah (empty if none).
  Future<Map<int, KnowledgeFact>> _byWord(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('quran_tajweed',
        columns: ['data'],
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah],
        limit: 1);
    if (rows.isEmpty) return const {};
    List<dynamic> spans;
    try {
      spans = jsonDecode(rows.first['data'] as String) as List<dynamic>;
    } catch (_) {
      return const {};
    }

    // group spans → per word, distinct rule ids in canonical family order
    final rawByWord = <int, Set<String>>{};
    for (final s in spans) {
      if (s is! Map) continue;
      final w = (s['w'] as num?)?.toInt();
      final r = s['r'] as String?;
      if (w == null || r == null) continue;
      (rawByWord[w] ??= <String>{}).add(r);
    }

    final out = <int, KnowledgeFact>{};
    rawByWord.forEach((w, ids) {
      final ordered = [for (final id in kTajweedRules.keys) if (ids.contains(id)) id];
      if (ordered.isEmpty) return;
      final rules = [
        for (final id in ordered)
          {
            'rule_id': id,
            'rule_ar': kTajweedRules[id]!.ruleAr,
            'rule_category': kTajweedRules[id]!.categoryKey,
            'concept_id': kTajweedRules[id]!.conceptId,
          }
      ];
      out[w] = KnowledgeFact(
        id: 'tajweed:$surah:$ayah:$w',
        domain: 'tajweed',
        anchor: KnowledgeAnchor(
            surah: surah, ayah: ayah, wordStart: w, wordEnd: w, scope: 'word'),
        payload: {'rules': rules},
        sourceRefId: 'src:cpfair-tajweed',
        dataState: KnowledgeDataState.local,
      );
    });
    return out;
  }
}

/// LOCAL provider — surfaces the first line of each bundled tafsīr edition
/// for the ayah as a `tafsir` fact (verbatim; full text opens `AyahStudyScreen`).
class LocalTafsirProvider extends KnowledgeProvider {
  @override
  Set<String> get domains => const {'tafsir'};

  static const _editionNamesAr = {
    'ibn_kathir_full': 'تفسير ابن كثير',
    'saadi': 'تفسير السعدي',
    'muyassar': 'التفسير الميسّر',
    'almukhtasar': 'المختصر في التفسير',
    'ibn_ashur': 'التحرير والتنوير (ابن عاشور)',
  };

  @override
  Future<List<KnowledgeFact>> factsFor(int surah, int ayah, int wordIndex) async {
    // tafsīr is an ayah-level fact; only surface it on word 1 to avoid noise.
    if (wordIndex != 1) return const [];
    return _tafsirFacts(surah, ayah);
  }

  @override
  Future<List<KnowledgeFact>> factsForAyah(int surah, int ayah) =>
      _tafsirFacts(surah, ayah);

  Future<List<KnowledgeFact>> _tafsirFacts(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'tafsir_entries',
      columns: ['source', 'text'],
      where: 'surah = ? AND ayah_from <= ? AND ayah_to >= ? AND text <> \'\'',
      whereArgs: [surah, ayah, ayah],
    );
    final out = <KnowledgeFact>[];
    for (final r in rows) {
      final src = r['source'] as String? ?? '';
      final nameAr = _editionNamesAr[src];
      if (nameAr == null) continue; // Arabic editions only, in the panel
      final text = (r['text'] as String? ?? '').trim();
      final snippet = text.length > 240 ? '${text.substring(0, 240)}…' : text;
      out.add(KnowledgeFact(
        id: 'tafsir:$src:$surah:$ayah',
        domain: 'tafsir',
        anchor: KnowledgeAnchor(surah: surah, ayah: ayah, scope: 'ayah'),
        payload: {'edition': src, 'name_ar': nameAr, 'snippet': snippet, 'has_full': true},
        sourceRefId: 'src:tafsir:$src',
        dataState: KnowledgeDataState.local,
      ));
    }
    return out;
  }
}
