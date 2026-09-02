# Quran Learning — Data Contracts

**Status: DESIGN ONLY. No code.** These are the stable shapes every layer of
`QURAN_LEARNING_ARCHITECTURE.md` agrees on. Field names are the contract;
storage (SQLite tables, JSON assets) is an implementation choice made in the
roadmap.

Conventions:
- `id` fields are **stable, opaque strings** — never a row-position or a
  hash of mutable content. Format: `<kind>:<source>:<localkey>` where useful
  (e.g. `morph:masaq:2:255:1`).
- Every field that carries a scholarly claim ends with `source_ref_id`
  (→ `SourceReference`). No sourced field without it.
- All anchors use the **semantic** identity; geometry is resolved on demand
  via the Mushaf Semantic Layer, never stored here.
- `null` / absent = "no verified data", which the UI renders as
  *"لا توجد بيانات موثقة"* — never as a guess.

---

## KnowledgeAnchor  (embedded value, not its own table)

The universal "where does this fact attach" shape. Every study fact has one.

```
KnowledgeAnchor {
  surah:        int            // 1..114                       required
  ayah:         int            // 1..N                          required
  word_start:   int?           // 1-based word_index in ayah    optional
  word_end:     int?           // inclusive; == word_start for one word
  char_start:   int?           // codepoint offset within the concatenated
  char_end:     int?           //   word range's text_uthmani; only if the
                               //   source annotates sub-word spans
  scope:        enum { ayah, word, word_range, char_range }
  segmentation: string         // which word-index scheme the *_start/_end use,
                               //   e.g. "mushafdb-v1.01" | "masaq" | "qac"
                               //   | "tanzil-space"  — REQUIRED whenever word_* set
}
```

Rules:
- `scope=ayah` → `word_*`/`char_*` all null.
- If `segmentation` ≠ `mushafdb-v1.01`, a mapping to our `mushaf_words.word_index`
  must exist (see `QURAN_DATA_VALIDATION.md` §M) before the fact is shown on
  the page; until then the fact is stored but flagged `unmapped`.
- `char_*` are only populated from sources that genuinely annotate character
  spans (e.g. tajwīd datasets); never computed by us to "look precise".

---

## 1. SourceReference

The provenance record. **Nothing scholarly ships without one.**

```
SourceReference {
  id:            string            // "src:masaq:v2"
  source_type:   enum { primary_text, morphology_dataset, syntax_dataset,
                        tajweed_dataset, tafsir_edition, hadith_collection,
                        grammar_reference, dictionary, audio_recitation,
                        app_curated_lesson }
  name:          string            // "MASAQ — Morphologically-Analyzed and
                                   //  Syntactically-Annotated Quran Dataset"
  author:        string?           // dataset authors / muṣannif
  book:          string?           // for classical refs: كتاب
  edition:       string?           // طبعة / dataset version, e.g. "v2 (2024)"
  volume:        string?           // مجلد
  page:          string?           // صفحة (range allowed)
  reference:     string?           // free-form citation the student can verify
  url:           string?
  license:       string            // SPDX id or exact licence name — REQUIRED
  license_use:   enum { bundled_ok, link_only, study_only, unknown }
  authority:     enum { classical_scholarly, academic_peer_reviewed,
                        institutional, community, unverified }
  retrieved_at:  string            // ISO date we captured/verified it
  confidence:    number            // 0.0–1.0, see QURAN_DATA_VALIDATION.md §C
  classification: enum { VERIFIED, SOURCE_BACKED, PROJECT_SPECIFIC,
                         INFERENCE, UNKNOWN }
  notes:         string?           // "syntax coverage partial (~11k words)"
}
```

Rules:
- `license_use = study_only` → the data may inform design but **must not be
  bundled or shipped**. `link_only` → we show a link, not the content.
- `classification ∈ {INFERENCE, UNKNOWN}` → **may not** back any displayed
  scholarly claim (A6). It can annotate gaps.
- `confidence` is a stored property of the *source×claim*, not computed by AI.

---

## 2. QuranWord   (Layer 03 — the spine; derived, not authored)

Read model assembled from `mushaf_words` (+ `quran_ayat` for the ayah text).
Immutable Quran Layer.

```
QuranWord {
  // identity
  surah:        int
  ayah:         int
  word_index:   int              // 1-based in ayah (MushafDatabase segmentation)
  // orthography  (Quran Layer — never modified)
  text_uthmani: string           // data-hafs
  text_imlaey:  string           // data-imlaey
  // position  (resolved from Mushaf Semantic Layer)
  page:         int
  line:         int
  word_order:   int              // reading order on the page
  bbox:         { x, y, w, h }   // viewBox 382.68×547.09
  word_type:    enum { text, juz_star, sajda_mehrab }
  // attachments  (lazy; each is its own contract, joined by anchor)
  morphology?:  Morphology
  syntax?:      SyntaxNode
  tajweed?:     TajweedRule[]     // spans that touch this word
  study_links?: KnowledgeEdge[]   // root siblings, concept illustrations, notes
}
```

`QuranWord` **has no `SourceReference`** — it is Quran Layer data (Tanzil +
MushafDatabase), already validated by `MushafLayoutSync` against canonical
counts. Its *attachments* carry the provenance.

---

## 3. Morphology   (Layer 04 — ṣarf, per word)

```
Morphology {
  id:            string                 // "morph:<seg>:<s>:<a>:<w>"
  anchor:        KnowledgeAnchor         // scope=word
  // core
  root:          string?                // "ع ل م"  (space-separated radicals)
  lemma:         string?                // "عَلِمَ"
  stem:          string?
  pos:           string                 // closed tagset: V, N, PN, ADJ, PRON,
                                        //   DEM, REL, PREP, CONJ, PART, …
  pos_ar:        string                 // "فعل" / "اسم" / "حرف" …
  // verbal features (null for non-verbs)
  aspect:        enum { perfect, imperfect, imperative }?   // ماضٍ/مضارع/أمر
  mood:          enum { indicative, subjunctive, jussive }?
  voice:         enum { active, passive }?
  form:          string?                // Roman numeral I–X / "فَعَّلَ" etc.
  // nominal features (null for non-nominals)
  case:          enum { nominative, accusative, genitive }? // مرفوع/منصوب/مجرور
  state:         enum { definite, indefinite, construct }?
  // shared
  person:        enum { 1, 2, 3 }?
  number:        enum { singular, dual, plural }?
  gender:        enum { masculine, feminine }?
  pattern:       string?                // الوزن الصرفي، e.g. "يَفْعُلُونَ"
  segments:      MorphSegment[]         // prefix/stem/suffix breakdown
  source_ref_id: string                // REQUIRED
  cross_refs:    { source_ref_id, agrees: bool, note }[]   // other datasets
}

MorphSegment {
  text:   string           // the morpheme surface form
  type:   enum { prefix, stem, suffix }
  tag:    string           // e.g. "PRON:3MP", "DET", "P" (preposition)
  gloss_ar: string?
}
```

Rules:
- The **root → other Quranic words** relation is **not** stored here; it is
  a `KnowledgeEdge` (Layer 10) so it stays queryable and sourced.
- Two datasets disagreeing on POS/root → both kept in `cross_refs`; the
  primary is the higher-`authority` / higher-`confidence` one; if equal →
  `CONFLICT` (validation doc §K), UI shows both, labelled.

---

## 4. SyntaxNode   (Layer 05 — one per word, its iʿrāb role)

```
SyntaxNode {
  id:            string                // "syn:<seg>:<s>:<a>:<w>"
  anchor:        KnowledgeAnchor        // scope=word (or word_range for
                                        //   multi-word units like مضاف+مضاف إليه
                                        //   treated as a phrase node)
  role:          string                // closed vocab, see §6 — e.g. "khabar_inna"
  role_ar:       string                // "خبر إنّ"
  irab_text:     string?               // the source's full iʿrāb sentence for
                                       //   this word, verbatim, e.g.
                                       //   "غفورٌ: خبر إنّ مرفوع وعلامة رفعه الضمة"
  governor_id:   string?               // SyntaxNode.id this word depends on
  phrase_id:     string?               // if part of a larger phrase node
  concept_id:    string?               // → LearningConcept for role (Layer 09)
  source_ref_id: string                // REQUIRED
  cross_refs:    { source_ref_id, role, note }[]
}
```

## 5. SyntaxRelation   (Layer 05 — a typed edge in the iʿrāb graph)

```
SyntaxRelation {
  id:            string                // "rel:<seg>:<s>:<a>:<from>-<to>"
  ayah:          { surah, ayah }
  from_node_id:  string                // dependent
  to_node_id:    string                // governor / head
  type:          string                // closed vocab §6
  type_ar:       string
  direction:     enum { from_depends_on_to }   // always; Arabic dep grammar
  label_ar:      string?               // display label on the edge
  concept_id:    string?               // → LearningConcept for this relation type
  source_ref_id: string                // REQUIRED
}
```

Rendering an edge = resolve `from`/`to` nodes → their `word_index` →
Mushaf Semantic Layer → highlight both `bbox`es on the page.

---

## 6. Closed vocabularies

### SyntaxRelation / SyntaxNode role types (extend only when a source needs it)

```
fael (فاعل) · naib_fael (نائب فاعل) · maful_bihi (مفعول به) ·
maful_mutlaq (مفعول مطلق) · maful_lahu (مفعول لأجله) · maful_maahu (مفعول معه) ·
maful_fihi / dharf (ظرف/مفعول فيه) · mubtada (مبتدأ) · khabar (خبر) ·
ism_inna (اسم إنّ/أخواتها) · khabar_inna (خبر إنّ/أخواتها) ·
ism_kana (اسم كان/أخواتها) · khabar_kana (خبر كان/أخواتها) ·
mudaf (مضاف) · mudaf_ilayh (مضاف إليه) · sifa/naat (صفة/نعت) · manut (منعوت/موصوف) ·
badal (بدل) · mubdal_minhu (مُبدَل منه) · atf (معطوف) · matuf_alayh (معطوف عليه) ·
harf_atf (حرف عطف) · jar (حرف جر) · majrur (اسم مجرور) · jar_majrur (جار ومجرور) ·
mutaalliq (مُتعلَّق) · hal (حال) · sahib_hal (صاحب الحال) · tamyiz (تمييز) ·
munada (منادى) · mustathna (مستثنى) · adawat_shart (أداة شرط) · fil_shart / jawab_shart ·
tawkid (توكيد) · muakkad (مؤكَّد) · silah (صلة الموصول) · aid (عائد) ·
jumla_ismiyya / jumla_filiyya (relation of a clause to its position)
```
Each has a `LearningConcept` (Layer 09). `role_ar`/`type_ar` are the display
strings.

### Tajwīd rule ids (extend only from a source)

```
family: noon_sakinah_tanween  → izhar · idgham_ghunnah · idgham_no_ghunnah ·
                                 iqlab · ikhfa
family: meem_sakinah          → ikhfa_shafawi · idgham_shafawi · izhar_shafawi
family: madd                  → tabee (طبيعي) · muttasil · munfasil · lazim ·
                                 aarid_sukoon · badal · leen · silah
family: laam                  → lam_shamsiyyah · lam_qamariyyah · lam_lafz_jalalah_tafkheem/tarqeeq
family: other                 → qalqalah · ghunnah · tafkheem · tarqeeq ·
                                 hamzat_wasl · sakt · idgham_mutamathilain /
                                 mutajanisain / mutaqaribain
family: waqf                  → (see docs/quran/QURAN_TERMINOLOGY.md — glyph-position
                                 data only; meaning needs a rules table + tradition)
```

---

## 7. TajweedRule   (Layer 06)

```
TajweedRule {
  id:            string                // "tj:<source>:<s>:<a>:<start>-<end>:<rule>"
  anchor:        KnowledgeAnchor        // scope ∈ char_range | word | word_range
  rule_id:       string                // from the closed list §6 — NEVER a colour
  rule_family:   string
  rule_ar:       string                // "إخفاء"
  cause_ar:      string?               // "نون ساكنة يليها حرف الذال"  (from source)
  letters:       string[]              // the letters the rule turns on
  articulation_ar: string?             // how to pronounce it  (from source)
  concept_id:    string?               // → LearningConcept for the family
  audio_ref_id:  string?               // SourceReference to a verified clip of
                                       //   exactly this spot, if available
  source_ref_id: string                // REQUIRED
}
```

Colour is **not** in the contract — the app maps `rule_id → colour` from a
user-selectable palette (`docs/quran/KNOWLEDGE.md` R‑14).

---

## 8. TafsirEntry   (Layer 07 — wraps existing `tafsir_entries`)

```
TafsirEntry {
  id:            string                // "tf:<edition>:<s>:<a_from>-<a_to>"
  anchor:        KnowledgeAnchor        // scope=ayah (or ayah range → store from/to)
  ayah_from:     { surah, ayah }
  ayah_to:       { surah, ayah }
  edition_id:    string                // "ibn_kathir" | "saadi" | "muyassar" |
                                       //   "ibn_ashur" | "almukhtasar" | <lang>
  kind:          enum { tafsir, translation_meaning }
  text:          string                // verbatim; sanitised of markup for display
  asbab_nuzul_excerpt: string?
  source_ref_id: string                // REQUIRED (per edition)
}
```

Never summarised or paraphrased by the app. Multiple editions shown side by
side, each attributed. (Mirrors the `quran.ai` MCP grounding discipline.)

---

## 9. LearningConcept   (Layer 09 — the thing a student chooses to "learn")

```
LearningConcept {
  id:            string                // "concept:nahw:khabar_inna"
  domain:        enum { nahw, sarf, tajweed, balagha, tafsir_method, meaning }
  title_ar:      string                // "خبر إنّ"
  short_def_ar:  string                // one-line, sourced
  blocks:        LearningBlock[]       // ordered: definition → explanation →
                                       //   examples → quranic_examples → application
  prerequisites: string[]              // other concept ids
  related:       string[]
  source_ref_ids: string[]             // REQUIRED — at least one
  status:        enum { authored, stub, missing }
}

LearningBlock {
  kind:   enum { definition, explanation, example, quranic_example, application, note }
  text_ar: string?
  quran_ref: KnowledgeAnchor?          // for quranic_example / application blocks
  source_ref_id: string               // REQUIRED for definition/explanation/example
}
```

- `status=missing` → the concept exists as a link target (from a
  `SyntaxRelation.concept_id` etc.) but has no lesson yet → UI shows the raw
  sourced fact + "درس هذا المفهوم غير متوفر بعد".
- `blocks` are **authored from cited grammar/tajwīd references**, never
  AI-generated. Each carries a `source_ref_id`.

## 10. LearningPathItem / StudyEntry   (Layer 08 — extends the Ayah Notebook)

Builds on the existing `ayah_study_entries` (already shipped: `id`, `surah`,
`ayah`, `word_start`, `word_end`, `entry_type`, `body`, `stance`, source
fields, `status`, timestamps). Two uses:

```
StudyEntry  (= an ayah_study_entries row; the student's own writing)
  entry_type ∈ { personal, tafsir, meaning, benefit, linguistic, fiqh,
                 aqeedah, tarbawi, hadith, comparison, question, link,
                 lesson_summary, review,
                 + NEW: concept_note }        // a note tied to a LearningConcept
  concept_id?: string                          // NEW optional column
  // everything else unchanged

LearningPathItem  (NEW sibling table — a concept the student is learning,
                   originating from a mushaf spot)
{
  id:            string
  concept_id:    string                        // → LearningConcept
  origin:        KnowledgeAnchor                // where "تعلّم هذا" was tapped
  state:         enum { learning, applied, reviewing }
  first_opened_at, last_touched_at: ISO
  note_entry_ids: string[]                      // ayah_study_entries the student wrote
}
```

No schema break: `concept_note` is a new `entry_type` value, `concept_id` a
new nullable column, `learning_path_items` a new table. `ayah_study_entries`
structure is otherwise untouched.

---

## 11. KnowledgeEdge   (Layer 10 — the graph; everything is a stored edge)

```
KnowledgeEdge {
  id:            string
  from_kind:     enum { word, ayah, root, lemma, pattern, concept, tajweed_rule,
                        tafsir_entry, study_entry, learning_path_item }
  from_id:       string                // e.g. "word:2:255:1" or "root:علم" or "concept:..."
  type:          string                // has_root · has_lemma · has_pattern ·
                                       //   syntactic_role · governs · illustrates ·
                                       //   explained_by · same_root_as ·
                                       //   tajweed_at · noted_by · learned_via ·
                                       //   related_concept · prerequisite_of
  to_kind:       enum { ... same set ... }
  to_id:         string
  source_ref_id: string?              // REQUIRED for scholarly edges
                                       //   (has_root, syntactic_role, tajweed_at,
                                       //    explained_by, illustrates); null OK
                                       //   for student-created edges (noted_by,
                                       //    learned_via)
  weight:        number?              // for ranking "other words from this root"
}
```

Rule (A / graph): **no edge is inferred at display time if a stored edge
exists.** "Words from the same root" = query `same_root_as` edges (built
once from Morphology + validated), not a live string match.

---

## 12. StudyEvent   (Layer 11 — append-only, feeds Layer 12)

```
StudyEvent {
  id:            string
  ts:            ISO-8601 UTC
  verb:          enum { opened, studied, noted, linked, applied, reviewed }
  // NO answered/correct/incorrect — this design has no quiz
  target_kind:   enum { word, ayah, concept, tajweed_rule, tafsir_entry,
                        learning_path_item, study_entry }
  target_id:     string
  anchor:        KnowledgeAnchor?     // the mushaf spot, when applicable
  layer:         enum { morphology, syntax, tajweed, tafsir, notebook, learning_path }
  dwell_ms:      int?                 // for 'studied'
  meta:          json?               // small, e.g. { scrolled_to_end: true }
}
```

Verb weights, decay, and how these roll up into Coverage / Retention /
Consistency / Depth / Neglect / ReviewPriority: **defined in
`docs/STUDY_INTELLIGENCE_ENGINE_SPEC.md`** — this contract only guarantees
the event shape. Principle (from Ismail): `opened` ≠ `studied` ≠ `reviewed`
≠ `applied`; they must weigh differently.

---

## 13. StudyItem  (Layer 12 bridge — what the math engine schedules)

```
StudyItem {
  id:            string
  kind:          enum { quran_ayah, quran_word, concept, tajweed_family, surah, juz, page }
  ref:           KnowledgeAnchor | { concept_id } | { surah } | { juz } | { page }
  created_at:    ISO
}
```

Every `LearningPathItem`, every studied concept, every tafsir-read ayah, and
every tajwīd family the student engaged with projects to a `StudyItem`. The
engine (`STUDY_INTELLIGENCE_ENGINE_SPEC.md`) does the rest — deterministic,
explainable, no AI.

---

## 14. Contract invariants (checked by validation, see `QURAN_DATA_VALIDATION.md`)

1. Every `Morphology`, `SyntaxNode`, `SyntaxRelation`, `TajweedRule`,
   `TafsirEntry`, `LearningConcept.block` row has a resolvable
   `source_ref_id`.
2. Every `KnowledgeAnchor` with `word_*` set has a `segmentation`, and if
   it's not `mushafdb-v1.01` there is a mapping row (or the fact is flagged
   `unmapped` and not shown on the page).
3. `surah ∈ 1..114`; `ayah ∈ 1..canonical_count(surah)`; `word_start ≤
   word_end`; `word_end ≤ max word_index for that ayah in its segmentation`.
4. `SyntaxRelation.from/to` reference existing `SyntaxNode`s in the same ayah.
5. No `SourceReference` with `classification ∈ {INFERENCE, UNKNOWN}` is
   referenced by a displayed scholarly field.
6. `license_use = study_only` sources are absent from any shipped asset.
7. `StudyEvent.verb` never ∈ {answered, correct, incorrect} (no quiz).
