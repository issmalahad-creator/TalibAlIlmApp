/// AKHLAQ training system — content model for a virtue slice
/// (`docs/akhlaq/` + `docs/akhlaq/alrifq/ar-rifq.json`).
///
/// **Arabic is the source of truth.** `text_ar` is never replaced; a
/// translation is a separate representation ([AkhlaqTranslation]). Plain,
/// immutable, framework-free — parsed once by `AkhlaqContent`.
library;

String _s(Object? v) => (v ?? '').toString();
List<String> _sl(Object? v) =>
    (v is List) ? v.map((e) => e.toString()).toList() : const [];

/// The virtue this slice trains (e.g. الرِّفق).
class AkhlaqVirtue {
  final String slug;
  final String titleAr;
  final String domain;
  final String opposite;
  final List<String> strengthenedBy;
  final List<String> leadsTo;
  final List<String> tensionWith;

  const AkhlaqVirtue({
    required this.slug,
    required this.titleAr,
    required this.domain,
    required this.opposite,
    required this.strengthenedBy,
    required this.leadsTo,
    required this.tensionWith,
  });

  factory AkhlaqVirtue.fromJson(Map<String, dynamic> j) => AkhlaqVirtue(
        slug: _s(j['slug']),
        titleAr: _s(j['title_ar']),
        domain: _s(j['domain']),
        opposite: _s(j['opposite']),
        strengthenedBy: _sl(j['strengthened_by']),
        leadsTo: _sl(j['leads_to']),
        tensionWith: _sl(j['tension_with']),
      );
}

class AkhlaqSubskill {
  final String slug;
  final String titleAr;
  const AkhlaqSubskill({required this.slug, required this.titleAr});
  factory AkhlaqSubskill.fromJson(Map<String, dynamic> j) =>
      AkhlaqSubskill(slug: _s(j['slug']), titleAr: _s(j['title_ar']));
}

/// A textual proof. `sourceStatus`: `source_confirmed` (text reached +
/// book/edition/locator fixed + marfūʿ takhrij/grading present in the
/// source) · `source_located` · `source_uncertain`. Not a human-review
/// flag — see `AKHLAQ_EVIDENCE_MODEL §3`.
class AkhlaqEvidence {
  final String id;
  final String sourceType; // quran | hadith_marfu | qawl_alim | ...
  final int sourceTier;
  final String contentClass;
  final String book;
  final String author;
  final String edition;
  final String chapter;
  final String vol;
  final String page;
  final String hadithId;
  final String narrator;
  final String textAr;
  final String authentication;
  final String grader;
  final String grading;
  final String takhrij;
  final String sourceStatus;
  final List<String> principleRefs;
  final String note;

  const AkhlaqEvidence({
    required this.id,
    required this.sourceType,
    required this.sourceTier,
    required this.contentClass,
    required this.book,
    required this.author,
    required this.edition,
    required this.chapter,
    required this.vol,
    required this.page,
    required this.hadithId,
    required this.narrator,
    required this.textAr,
    required this.authentication,
    required this.grader,
    required this.grading,
    required this.takhrij,
    required this.sourceStatus,
    required this.principleRefs,
    required this.note,
  });

  bool get isMarfu => sourceType == 'hadith_marfu';
  bool get isQuran => sourceType == 'quran';
  bool get isConfirmed => sourceStatus == 'source_confirmed';

  factory AkhlaqEvidence.fromJson(Map<String, dynamic> j) => AkhlaqEvidence(
        id: _s(j['id']),
        sourceType: _s(j['source_type']),
        sourceTier: (j['source_tier'] as num?)?.toInt() ?? 0,
        contentClass: _s(j['content_class']),
        book: _s(j['book']),
        author: _s(j['author']),
        edition: _s(j['edition']),
        chapter: _s(j['chapter']),
        vol: _s(j['vol']),
        page: _s(j['page']),
        hadithId: _s(j['hadith_id']),
        narrator: _s(j['narrator']),
        textAr: _s(j['text_ar']),
        authentication: _s(j['authentication']),
        grader: _s(j['grader']),
        grading: _s(j['grading']),
        takhrij: _s(j['takhrij']),
        sourceStatus: _s(j['source_status']),
        principleRefs: _sl(j['principle_refs']),
        note: _s(j['note']),
      );
}

/// A pedagogical principle — `interpretationBy` is always
/// "منهج التطبيق التربوي"; it is **never** attributed to a scholar and
/// creates no ruling.
class AkhlaqPrinciple {
  final String id;
  final String subskill;
  final String statementAr;
  final String interpretationBy;
  final List<String> evidence;

  const AkhlaqPrinciple({
    required this.id,
    required this.subskill,
    required this.statementAr,
    required this.interpretationBy,
    required this.evidence,
  });

  factory AkhlaqPrinciple.fromJson(Map<String, dynamic> j) => AkhlaqPrinciple(
        id: _s(j['id']),
        subskill: _s(j['subskill']),
        statementAr: _s(j['statement_ar']),
        interpretationBy: _s(j['interpretation_by']),
        evidence: _sl(j['evidence']),
      );
}

/// An observable behavioural indicator. `basis` is an evidence id or the
/// literal `TARBAWI` (pedagogical, tagged, unattributed).
class AkhlaqBehavior {
  final String id;
  final String subskill;
  final String textAr;
  final String basis;
  const AkhlaqBehavior({
    required this.id,
    required this.subskill,
    required this.textAr,
    required this.basis,
  });
  bool get isTarbawi => basis == 'TARBAWI';
  factory AkhlaqBehavior.fromJson(Map<String, dynamic> j) => AkhlaqBehavior(
        id: _s(j['id']),
        subskill: _s(j['subskill']),
        textAr: _s(j['text_ar']),
        basis: _s(j['basis']),
      );
}

/// One response option in a scenario. `dimensions` maps a response
/// dimension → +1/-1. `verdict`: `aqrab` | `maqbul` | `baid` (internal —
/// never shown as a score).
class AkhlaqOption {
  final String key; // 'A' | 'B' | 'C' | 'D'
  final String textAr;
  final Map<String, int> dimensions;
  final String verdict;
  final String whyAr;
  final List<String> evidence;

  const AkhlaqOption({
    required this.key,
    required this.textAr,
    required this.dimensions,
    required this.verdict,
    required this.whyAr,
    required this.evidence,
  });

  factory AkhlaqOption.fromJson(Map<String, dynamic> j) => AkhlaqOption(
        key: _s(j['ord']),
        textAr: _s(j['text_ar']),
        dimensions: {
          for (final e in (j['dimensions'] as Map? ?? const {}).entries)
            e.key.toString(): (e.value as num).toInt(),
        },
        verdict: _s(j['verdict']),
        whyAr: _s(j['why_ar']),
        evidence: _sl(j['evidence']),
      );
}

class AkhlaqScenario {
  final String id;
  final int difficulty; // 1..8 — context difficulty, NOT a moral score
  final String setting;
  final List<String> subskills;
  final List<String> pressure;
  final bool composite;
  final String stemAr;
  final List<AkhlaqOption> options;
  final String probeAr;
  final String feedbackAr;
  final String reflectionAr;

  const AkhlaqScenario({
    required this.id,
    required this.difficulty,
    required this.setting,
    required this.subskills,
    required this.pressure,
    required this.composite,
    required this.stemAr,
    required this.options,
    required this.probeAr,
    required this.feedbackAr,
    required this.reflectionAr,
  });

  AkhlaqOption? optionByKey(String key) {
    for (final o in options) {
      if (o.key == key) return o;
    }
    return null;
  }

  factory AkhlaqScenario.fromJson(Map<String, dynamic> j) => AkhlaqScenario(
        id: _s(j['id']),
        difficulty: (j['difficulty'] as num?)?.toInt() ?? 1,
        setting: _s(j['setting']),
        subskills: _sl(j['subskills']),
        pressure: _sl(j['pressure']),
        composite: j['composite'] == true,
        stemAr: _s(j['stem_ar']),
        options: [
          for (final o in (j['options'] as List? ?? const []))
            AkhlaqOption.fromJson(o as Map<String, dynamic>),
        ],
        probeAr: _s(j['probe_ar']),
        feedbackAr: _s(j['feedback_ar']),
        reflectionAr: _s(j['reflection_ar']),
      );
}

class AkhlaqStage {
  final int stage; // 1..7
  final String titleAr;
  final List<String> subskills;
  final String outcomeAr;
  final List<String> scenarios;

  const AkhlaqStage({
    required this.stage,
    required this.titleAr,
    required this.subskills,
    required this.outcomeAr,
    required this.scenarios,
  });

  factory AkhlaqStage.fromJson(Map<String, dynamic> j) => AkhlaqStage(
        stage: (j['stage'] as num?)?.toInt() ?? 0,
        titleAr: _s(j['title_ar']),
        subskills: _sl(j['subskills']),
        outcomeAr: _s(j['outcome_ar']),
        scenarios: _sl(j['scenarios']),
      );
}

/// One translation row. `translationType`: literal | pedagogical |
/// quran_meaning | term_gloss. `translationStatus`: generated |
/// machine_assisted | human_reviewed | approved | pending.
class AkhlaqTranslation {
  final String refKind;
  final String refId;
  final String layer;
  final String lang;
  final String translationType;
  final String text;
  final String translator;
  final String translationStatus;
  final String notes;

  const AkhlaqTranslation({
    required this.refKind,
    required this.refId,
    required this.layer,
    required this.lang,
    required this.translationType,
    required this.text,
    required this.translator,
    required this.translationStatus,
    required this.notes,
  });

  /// Show a translation to an end user only when it actually carries text
  /// and has cleared at least automated generation.
  bool get isShowable =>
      text.trim().isNotEmpty &&
      (translationStatus == 'generated' ||
          translationStatus == 'human_reviewed' ||
          translationStatus == 'approved');

  factory AkhlaqTranslation.fromJson(Map<String, dynamic> j) => AkhlaqTranslation(
        refKind: _s(j['ref_kind']),
        refId: _s(j['ref_id']),
        layer: _s(j['layer']),
        lang: _s(j['lang']),
        translationType: _s(j['translation_type']),
        text: _s(j['text']),
        translator: _s(j['translator']),
        translationStatus: _s(j['translation_status']),
        notes: _s(j['notes']),
      );
}

/// The whole parsed slice.
class AkhlaqSlice {
  final String slice;
  final AkhlaqVirtue virtue;
  final List<AkhlaqEvidence> evidence;
  final List<AkhlaqPrinciple> principles;
  final List<AkhlaqSubskill> subskills;
  final List<AkhlaqBehavior> behaviors;
  final List<AkhlaqScenario> scenarios;
  final List<AkhlaqStage> curriculum;
  final Map<String, dynamic> spacedRepetition;
  final List<AkhlaqTranslation> translations;

  const AkhlaqSlice({
    required this.slice,
    required this.virtue,
    required this.evidence,
    required this.principles,
    required this.subskills,
    required this.behaviors,
    required this.scenarios,
    required this.curriculum,
    required this.spacedRepetition,
    required this.translations,
  });

  factory AkhlaqSlice.fromJson(Map<String, dynamic> j) => AkhlaqSlice(
        slice: _s(j['slice']),
        virtue: AkhlaqVirtue.fromJson(
            (j['virtue'] as Map).cast<String, dynamic>()),
        evidence: [
          for (final e in (j['evidence'] as List))
            AkhlaqEvidence.fromJson((e as Map).cast<String, dynamic>()),
        ],
        principles: [
          for (final p in (j['principles'] as List))
            AkhlaqPrinciple.fromJson((p as Map).cast<String, dynamic>()),
        ],
        subskills: [
          for (final s in (j['subskills'] as List))
            AkhlaqSubskill.fromJson((s as Map).cast<String, dynamic>()),
        ],
        behaviors: [
          for (final b in (j['behaviors'] as List))
            AkhlaqBehavior.fromJson((b as Map).cast<String, dynamic>()),
        ],
        scenarios: [
          for (final s in (j['scenarios'] as List))
            AkhlaqScenario.fromJson((s as Map).cast<String, dynamic>()),
        ],
        curriculum: [
          for (final c in (j['curriculum'] as List))
            AkhlaqStage.fromJson((c as Map).cast<String, dynamic>()),
        ],
        spacedRepetition:
            (j['spaced_repetition'] as Map?)?.cast<String, dynamic>() ??
                const {},
        translations: [
          for (final t in (j['translations'] as List))
            AkhlaqTranslation.fromJson((t as Map).cast<String, dynamic>()),
        ],
      );

  AkhlaqScenario? scenarioById(String id) {
    for (final s in scenarios) {
      if (s.id == id) return s;
    }
    return null;
  }

  AkhlaqEvidence? evidenceById(String id) {
    for (final e in evidence) {
      if (e.id == id) return e;
    }
    return null;
  }

  AkhlaqSubskill? subskillBySlug(String slug) {
    for (final s in subskills) {
      if (s.slug == slug) return s;
    }
    return null;
  }
}

// ── persisted user state (SQLite v61) — never seeded ─────────────────────

/// One training attempt on a scenario. `quality` is derived from the
/// chosen option's verdict (aqrab=5, maqbul=3, baid=1).
class AkhlaqAttempt {
  final int id;
  final String subskill;
  final String scenarioId;
  final String chosenKey; // 'A' | 'B' | ...
  final String verdict;
  final int quality;
  final int difficulty;
  final Map<String, int> dimScore; // dimension -> net for the chosen option
  final int answeredAt; // epoch ms

  const AkhlaqAttempt({
    this.id = 0,
    required this.subskill,
    required this.scenarioId,
    required this.chosenKey,
    required this.verdict,
    required this.quality,
    required this.difficulty,
    required this.dimScore,
    required this.answeredAt,
  });
}

/// Spaced-repetition state for one (user × subskill). `track` cycles
/// K (knowledge recall) → S (scenario) → R (reflection).
class AkhlaqSrState {
  final String subskill;
  final String track; // 'K' | 'S' | 'R'
  final int intervalDays;
  final double ease;
  final int difficulty; // current scenario difficulty 1..8
  final String dueDate; // YYYY-MM-DD
  final int lastQuality;

  const AkhlaqSrState({
    required this.subskill,
    this.track = 'S',
    this.intervalDays = 1,
    this.ease = 2.3,
    this.difficulty = 1,
    this.dueDate = '',
    this.lastQuality = 0,
  });

  AkhlaqSrState copyWith({
    String? track,
    int? intervalDays,
    double? ease,
    int? difficulty,
    String? dueDate,
    int? lastQuality,
  }) =>
      AkhlaqSrState(
        subskill: subskill,
        track: track ?? this.track,
        intervalDays: intervalDays ?? this.intervalDays,
        ease: ease ?? this.ease,
        difficulty: difficulty ?? this.difficulty,
        dueDate: dueDate ?? this.dueDate,
        lastQuality: lastQuality ?? this.lastQuality,
      );
}

/// A derived, non-judgemental training indicator for one subskill.
/// **Never** a verdict on the person (`AKHLAQ_SYSTEM_PHILOSOPHY §6/§7`).
class AkhlaqProgress {
  final String subskill;
  final double trend; // 0..1 — response-selection quality trend
  final int attempts;
  final String band; // beginner | practising | stable | mastery | review
  final String? weakDimension;

  const AkhlaqProgress({
    required this.subskill,
    required this.trend,
    required this.attempts,
    required this.band,
    this.weakDimension,
  });
}
