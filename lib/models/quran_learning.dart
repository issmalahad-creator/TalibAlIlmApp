/// Phase 79 `79-ql` — Quran Learning Layer models.
///
/// Framework-free data for the bridge between the mushaf and organised
/// study: a knowledge fact + its source, a concept + its lesson, and the
/// student's learning-path state. See `docs/quran/QURAN_LEARNING_LAYER.md`
/// and `docs/QURAN_DATA_CONTRACTS.md`.
library;

import 'dart:convert';

/// Where a fact / lesson example attaches. Semantic, never a pixel.
class KnowledgeAnchor {
  final int surah;
  final int ayah;
  final int? wordStart; // 1-based word_index in the ayah
  final int? wordEnd; // inclusive
  final String scope; // ayah | word | word_range | char_range
  final String segmentation; // mushafdb-v1.01 | tanzil-space | qac | masaq

  const KnowledgeAnchor({
    required this.surah,
    required this.ayah,
    this.wordStart,
    this.wordEnd,
    this.scope = 'word',
    this.segmentation = 'mushafdb-v1.01',
  });

  bool covers(int wordIndex) =>
      wordStart != null && wordIndex >= wordStart! && wordIndex <= (wordEnd ?? wordStart!);

  factory KnowledgeAnchor.fromJson(Map<String, dynamic> j) => KnowledgeAnchor(
        surah: (j['surah'] as num).toInt(),
        ayah: (j['ayah'] as num).toInt(),
        wordStart: (j['word_start'] as num?)?.toInt(),
        wordEnd: (j['word_end'] as num?)?.toInt(),
        scope: j['scope'] as String? ?? 'word',
        segmentation: j['segmentation'] as String? ?? 'mushafdb-v1.01',
      );
}

/// Provenance. Nothing scholarly is shown without one.
class SourceReference {
  final String id;
  final String sourceType;
  final String name;
  final String? author;
  final String? book;
  final String? edition;
  final String? volume;
  final String? page;
  final String? reference;
  final String? url;
  final String license;
  final String licenseUse; // bundled_ok | link_only | study_only | unknown | api_stream_only
  final String? authority;
  final String? retrievedAt;
  final double confidence;
  final String classification; // VERIFIED | SOURCE_BACKED | PROJECT_SPECIFIC | INFERENCE | UNKNOWN
  final String? notes;

  const SourceReference({
    required this.id,
    required this.sourceType,
    required this.name,
    this.author,
    this.book,
    this.edition,
    this.volume,
    this.page,
    this.reference,
    this.url,
    required this.license,
    this.licenseUse = 'unknown',
    this.authority,
    this.retrievedAt,
    this.confidence = 0.0,
    this.classification = 'UNKNOWN',
    this.notes,
  });

  /// May a fact backed by this source be shown as a scholarly claim?
  bool get displayable =>
      classification == 'VERIFIED' || classification == 'SOURCE_BACKED' || classification == 'PROJECT_SPECIFIC';

  /// May a fetched copy be bundled / persisted?
  bool get bundleable => licenseUse == 'bundled_ok';

  String get badgeAr => switch (classification) {
        'VERIFIED' => 'موثّق',
        'SOURCE_BACKED' => 'مقبول',
        'PROJECT_SPECIFIC' => 'داخلي',
        _ => 'محل مراجعة',
      };

  factory SourceReference.fromJson(Map<String, dynamic> j) => SourceReference(
        id: j['id'] as String,
        sourceType: j['source_type'] as String? ?? 'unknown',
        name: j['name'] as String? ?? '',
        author: j['author'] as String?,
        book: j['book'] as String?,
        edition: j['edition'] as String?,
        volume: j['volume'] as String?,
        page: j['page'] as String?,
        reference: j['reference'] as String?,
        url: j['url'] as String?,
        license: j['license'] as String? ?? '',
        licenseUse: j['license_use'] as String? ?? 'unknown',
        authority: j['authority'] as String?,
        retrievedAt: j['retrieved_at'] as String?,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.0,
        classification: j['classification'] as String? ?? 'UNKNOWN',
        notes: j['notes'] as String?,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'source_type': sourceType,
        'name': name,
        'author': author,
        'book': book,
        'edition': edition,
        'volume': volume,
        'page': page,
        'reference': reference,
        'url': url,
        'license': license,
        'license_use': licenseUse,
        'authority': authority,
        'retrieved_at': retrievedAt,
        'confidence': confidence,
        'classification': classification,
        'notes': notes,
      };

  static SourceReference fromRow(Map<String, Object?> r) => SourceReference(
        id: r['id'] as String,
        sourceType: r['source_type'] as String? ?? 'unknown',
        name: r['name'] as String? ?? '',
        author: r['author'] as String?,
        book: r['book'] as String?,
        edition: r['edition'] as String?,
        volume: r['volume'] as String?,
        page: r['page'] as String?,
        reference: r['reference'] as String?,
        url: r['url'] as String?,
        license: r['license'] as String? ?? '',
        licenseUse: r['license_use'] as String? ?? 'unknown',
        authority: r['authority'] as String?,
        retrievedAt: r['retrieved_at'] as String?,
        confidence: (r['confidence'] as num?)?.toDouble() ?? 0.0,
        classification: r['classification'] as String? ?? 'UNKNOWN',
        notes: r['notes'] as String?,
      );
}

/// `local` = bundled · `online` = fetched now, not stored · `cached` =
/// fetched then stored per terms · `unavailable` = no provider could answer.
enum KnowledgeDataState { local, online, cached, unavailable }

KnowledgeDataState _dataStateFromKey(String? k) => switch (k) {
      'online' => KnowledgeDataState.online,
      'cached' => KnowledgeDataState.cached,
      'unavailable' => KnowledgeDataState.unavailable,
      _ => KnowledgeDataState.local,
    };

extension KnowledgeDataStateX on KnowledgeDataState {
  String get key => switch (this) {
        KnowledgeDataState.local => 'local',
        KnowledgeDataState.online => 'online',
        KnowledgeDataState.cached => 'cached',
        KnowledgeDataState.unavailable => 'unavailable',
      };
  String get labelAr => switch (this) {
        KnowledgeDataState.local => 'محلي',
        KnowledgeDataState.online => 'مباشر',
        KnowledgeDataState.cached => 'محفوظ مؤقتًا',
        KnowledgeDataState.unavailable => 'غير متاح',
      };
}

/// One verified scholarly fact. `payload` is domain-shaped free JSON
/// (ṣarf: root/lemma/pattern/…; naḥw: role/irab_text; tajwīd: rules[]).
class KnowledgeFact {
  final String id;
  final String domain; // sarf | nahw | tajweed | meaning | tafsir | ...
  final KnowledgeAnchor anchor;
  final Map<String, dynamic> payload;
  final String sourceRefId;
  final KnowledgeDataState dataState;
  final String mappingStatus; // mapped | unmapped

  const KnowledgeFact({
    required this.id,
    required this.domain,
    required this.anchor,
    required this.payload,
    required this.sourceRefId,
    this.dataState = KnowledgeDataState.local,
    this.mappingStatus = 'mapped',
  });

  /// Concept this fact links to (`payload.concept_id` or per-rule), if any.
  String? get conceptId {
    final c = payload['concept_id'];
    if (c is String) return c;
    final rules = payload['rules'];
    if (rules is List && rules.isNotEmpty && rules.first is Map) {
      final rc = (rules.first as Map)['concept_id'];
      if (rc is String) return rc;
    }
    return null;
  }

  factory KnowledgeFact.fromJson(Map<String, dynamic> j) => KnowledgeFact(
        id: j['id'] as String,
        domain: j['domain'] as String,
        anchor: KnowledgeAnchor.fromJson((j['anchor'] as Map).cast<String, dynamic>()),
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        sourceRefId: j['source_ref_id'] as String,
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'domain': domain,
        'surah': anchor.surah,
        'ayah': anchor.ayah,
        'word_start': anchor.wordStart,
        'word_end': anchor.wordEnd,
        'scope': anchor.scope,
        'segmentation': anchor.segmentation,
        'mapping_status': mappingStatus,
        'payload_json': jsonEncode(payload),
        'source_ref_id': sourceRefId,
        'data_state': dataState.key,
      };

  static KnowledgeFact fromRow(Map<String, Object?> r) => KnowledgeFact(
        id: r['id'] as String,
        domain: r['domain'] as String,
        anchor: KnowledgeAnchor(
          surah: (r['surah'] as num).toInt(),
          ayah: (r['ayah'] as num).toInt(),
          wordStart: (r['word_start'] as num?)?.toInt(),
          wordEnd: (r['word_end'] as num?)?.toInt(),
          scope: r['scope'] as String? ?? 'word',
          segmentation: r['segmentation'] as String? ?? 'mushafdb-v1.01',
        ),
        payload: (jsonDecode(r['payload_json'] as String) as Map).cast<String, dynamic>(),
        sourceRefId: r['source_ref_id'] as String,
        dataState: _dataStateFromKey(r['data_state'] as String?),
        mappingStatus: r['mapping_status'] as String? ?? 'mapped',
      );
}

/// One ordered block of a lesson.
class LearningBlock {
  final String kind; // definition | explanation | example | quranic_example | application | note
  final String? textAr;
  final KnowledgeAnchor? quranRef;
  final String? sourceRefId;

  /// Where in [sourceRefId] the text is (e.g. «ص 11») — quotes are always
  /// attributed to the page.
  final String? locator;
  const LearningBlock({required this.kind, this.textAr, this.quranRef, this.sourceRefId, this.locator});

  factory LearningBlock.fromJson(Object? raw) {
    if (raw is List) {
      // compact ["kind","text","src"] form from prototype.json
      return LearningBlock(
        kind: raw.isNotEmpty ? raw[0] as String : 'note',
        textAr: raw.length > 1 ? raw[1] as String? : null,
        sourceRefId: raw.length > 2 ? raw[2] as String? : null,
        locator: raw.length > 3 ? raw[3] as String? : null,
      );
    }
    final j = (raw as Map).cast<String, dynamic>();
    return LearningBlock(
      kind: j['kind'] as String? ?? 'note',
      textAr: j['text_ar'] as String?,
      quranRef: j['quran_ref'] == null
          ? null
          : KnowledgeAnchor.fromJson((j['quran_ref'] as Map).cast<String, dynamic>()),
      sourceRefId: j['source_ref_id'] as String?,
      locator: j['locator'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'kind': kind,
        if (textAr != null) 'text_ar': textAr,
        if (sourceRefId != null) 'source_ref_id': sourceRefId,
        if (locator != null) 'locator': locator,
      };
}

/// A concept + its lesson. `status`: authored | stub | missing.
class LearningConcept {
  final String id;
  final String domain;
  final String titleAr;
  final String? shortDefAr;
  final List<LearningBlock> blocks;
  final List<String> sourceRefIds;
  final String status;

  const LearningConcept({
    required this.id,
    required this.domain,
    required this.titleAr,
    this.shortDefAr,
    this.blocks = const [],
    this.sourceRefIds = const [],
    this.status = 'authored',
  });

  factory LearningConcept.fromJson(Map<String, dynamic> j) => LearningConcept(
        id: j['id'] as String,
        domain: j['domain'] as String? ?? 'nahw',
        titleAr: j['title_ar'] as String? ?? '',
        shortDefAr: j['short_def_ar'] as String?,
        blocks: [for (final b in (j['blocks'] as List? ?? const [])) LearningBlock.fromJson(b)],
        sourceRefIds: [for (final s in (j['source_ref_ids'] as List? ?? const [])) s as String],
        status: j['status'] as String? ?? 'authored',
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'domain': domain,
        'title_ar': titleAr,
        'short_def_ar': shortDefAr,
        'blocks_json': jsonEncode([for (final b in blocks) b.toJson()]),
        'source_ref_ids_json': jsonEncode(sourceRefIds),
        'status': status,
      };

  static LearningConcept fromRow(Map<String, Object?> r) => LearningConcept(
        id: r['id'] as String,
        domain: r['domain'] as String? ?? 'nahw',
        titleAr: r['title_ar'] as String? ?? '',
        shortDefAr: r['short_def_ar'] as String?,
        blocks: [
          for (final b in (jsonDecode(r['blocks_json'] as String? ?? '[]') as List))
            LearningBlock.fromJson(b)
        ],
        sourceRefIds: [
          for (final s in (jsonDecode(r['source_ref_ids_json'] as String? ?? '[]') as List)) s as String
        ],
        status: r['status'] as String? ?? 'authored',
      );
}

/// A concept the student is learning, from a mushaf spot.
class LearningPathItem {
  final int id;
  final String conceptId;
  final int originSurah;
  final int originAyah;
  final int? originWordStart;
  final int? originWordEnd;
  final String state; // learning | applied | reviewing
  final String firstOpenedAt;
  final String lastTouchedAt;

  const LearningPathItem({
    required this.id,
    required this.conceptId,
    required this.originSurah,
    required this.originAyah,
    this.originWordStart,
    this.originWordEnd,
    this.state = 'learning',
    required this.firstOpenedAt,
    required this.lastTouchedAt,
  });

  static LearningPathItem fromRow(Map<String, Object?> r) => LearningPathItem(
        id: (r['id'] as num).toInt(),
        conceptId: r['concept_id'] as String,
        originSurah: (r['origin_surah'] as num).toInt(),
        originAyah: (r['origin_ayah'] as num).toInt(),
        originWordStart: (r['origin_word_start'] as num?)?.toInt(),
        originWordEnd: (r['origin_word_end'] as num?)?.toInt(),
        state: r['state'] as String? ?? 'learning',
        firstOpenedAt: r['first_opened_at'] as String? ?? '',
        lastTouchedAt: r['last_touched_at'] as String? ?? '',
      );
}

/// What the KnowledgeGateway returns for a word: facts per domain + the
/// worst dataState seen (so the UI can flag "some of this needs internet").
class KnowledgeResult {
  final Map<String, List<KnowledgeFact>> byDomain;
  final Map<String, SourceReference> sources;
  final KnowledgeDataState overallState;

  const KnowledgeResult({
    required this.byDomain,
    required this.sources,
    this.overallState = KnowledgeDataState.local,
  });

  bool get isEmpty => byDomain.values.every((l) => l.isEmpty);
  List<KnowledgeFact> facts(String domain) => byDomain[domain] ?? const [];
  SourceReference? sourceFor(KnowledgeFact f) => sources[f.sourceRefId];
}

/// Append-only study event verbs (no quiz verbs).
class StudyEventVerbs {
  static const openedLesson = 'opened_lesson';
  static const openedQuranExample = 'opened_quran_example';
  static const openedSource = 'opened_source';
  static const createdNote = 'created_note';
  static const linkedAyah = 'linked_ayah';
  static const returnedToAyah = 'returned_to_ayah';
  static const reviewedNote = 'reviewed_note';
  static const opened = 'opened';
  static const studied = 'studied';
  static const all = [
    openedLesson, openedQuranExample, openedSource, createdNote,
    linkedAyah, returnedToAyah, reviewedNote, opened, studied,
  ];
}
