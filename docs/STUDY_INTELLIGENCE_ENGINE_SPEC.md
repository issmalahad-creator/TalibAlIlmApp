# Study Intelligence Engine — mathematical specification

**Status: SPEC ONLY. No implementation.** Approved before any code is
written (it is step 4 in the priority order in
`STUDY_INTELLIGENCE_VISION.md`). Current work stays on the `79-sa-D`
family; this engine is a **separate layer** that only reads a
`study_events` log and produces advisory, explainable outputs — wired to
nothing yet.

Hard invariant: **no AI, no LLM, no external service** anywhere in this
engine. Every output is a pure function of stored data + the constants in
§16. Every displayed number carries: **formula id + version, data source,
time window, confidence, and a plain-language reason**.

## What this spec adds beyond the vision doc

The vision listed the metrics. This spec makes them buildable and
un-gameable: a **causal DAG** (raw events → base indicators → composite
indicators → confidence → decisions), every result as an auditable
`ScoreExplanation` struct, statistical treatment for sparse/noisy data
(shrinkage priors, quality-weighted events, bounded composites), explicit
book-difficulty and book-length normalization, per-metric time decay, a
formula registry for traceable formula changes, and hand-checkable numeric
examples + test vectors.

---

## 1. The causal pipeline (the spine)

```
                 ┌─────────────────────────────────────────────┐
  raw            │ study_events  (append-only, quality-weighted)│
  ─────────────► │  + knowledge_edges  + study_items metadata   │
                 └───────────────┬─────────────────────────────┘
                                 ▼
              L1  BASE INDICATORS   (one event stream → one number, no other indicators)
                  Exposure · StudyTime · RereadCount · ReviewCount
                  RecallSuccesses/Attempts · DaysSinceLastReview
                  AnnotationDensity · EventTypeMix · ActiveDays · SessionQuality
                                 ▼
              L2  COMPOSITE INDICATORS   (functions of L1 only, all bounded [0,1])
                  Retention · KnowledgeStrength · DepthScore · ConsistencyScore
                  NeglectScore · MasteryScore · StudyCoverage · StudyEfficiency
                  + time intelligence: EstimatedCompletion · DailyRequiredLoad
                    · OverloadRisk · RecoveryTime · PlanFeasibility
                                 ▼
              L3  CONFIDENCE   (function of sample size, span, diversity, recency)
                                 ▼
              L4  DECISIONS     (bounded, gated by L3)
                  ReviewPriority(item) · NextBestItem(session) · NeglectAlerts
                  · BalanceReport · "insufficient data"
```

**Rule:** an L2 node may only read L1 nodes; an L3/L4 node may only read
L1+L2. No cycles. Every L2/L3/L4 output records `contributions[]` (which
inputs, their value, weight, and signed contribution) so a later formula
change is fully auditable — never a black box.

---

## 2. Core types

```
StudyItem
  id, kind (quran_ayah | quran_word | book_passage | highlight | note | hadith | lesson)
  anchor        // (surah,ayah[,word_range]) OR (book_id,page,char_range) OR (collection,number) OR lesson_id
  category_id?  // for books: turath cat_id; for ayah: surah/juz; for hadith: topic
  importance    // 0..1, see §11 (NOT user-set arbitrarily; derived from graph + category)
  difficulty    // 0..1, category prior + per-item overrides (§13.6)
  length_units  // normalized study units to "complete" this item (§13.7); null for atomic items

StudyEvent
  id, study_item_id, type, at (utc ms),
  duration_ms?,          // for read/review/session-scoped types
  payload?,              // e.g. recall grade, page number, word index
  source,                // 'reader' | 'recitation' | 'annotation' | 'memorization' | 'projection:<table>'
  idempotency_key,       // dedupe (source + natural key); UNIQUE
  quality               // 0..1, computed at ingest (§4.3); events never "count as 1"

Indicator  (L1/L2 result)
  key, item_or_scope, value, window, computed_at,
  input_snapshot,        // frozen copy of the raw counts it used
  formula_id, formula_version

ScoreExplanation  (every L2/L3/L4 output)
  value            // final number, bounded per its spec
  confidence       // 0..1 from L3
  window           // e.g. "last 60 days" / "all time"
  formula_id, formula_version
  contributions: [ { name, raw, normalized, weight, contribution (signed), direction ('↑'|'↓') } ]
  data_sources: [ event_type / table ids used ]
  reason           // rendered from contributions, e.g. "‎+ 37 يومًا منذ آخر مراجعة …"

Decision
  kind ('review' | 'continue' | 'related' | 'revise' | 'gather_data')
  target study_item_id?
  score, explanation: ScoreExplanation
  suppressed_reason?   // set instead of score when confidence < min_display_confidence
```

The UI never receives a bare number — it receives a `ScoreExplanation` and
renders `value` with a tap-through to `contributions` + `reason`.

---

## 3. Event model

### 3.1 Event types and the depth ladder

| type | depth weight `dw` | emitted when |
|---|---|---|
| `opened` | 0.10 | item screen shown ≥ `T_open_min` |
| `read` | 0.40 | a page/passage/ayah scrolled through, dwell ≥ `T_read_min` |
| `reread` | 0.60 | `read` on an item already `read` earlier than `T_reread_gap` ago |
| `highlight` | 0.70 | study annotation created |
| `note` | 0.85 | annotation note body added/edited (non-empty) |
| `review` | 0.90 | explicit review action (recitation test, review-mode open) |
| `memorize` | 0.95 | marked memorized / hifz station advance |
| `successful_recall` | 1.00 | review with grade ≥ pass |
| `failed_recall` | 0.30 (effort, not depth) | review with grade < pass |
| `completed` | — | item finished (sets progress = length_units) |

`dw` is used by DepthScore and as a tie-break in ranking. It is **not** a
reward the user sees.

### 3.2 Projection from existing tables (no new capture code needed at first)

| existing | → events |
|---|---|
| `recitation_sessions` / `recitation_mistakes` | `review`, then `successful_recall` or `failed_recall` per ayah; `duration` from session |
| `turath_annotations` (`created_at`) | `highlight`; `note` if `note_body` non-empty; `updated_at` change → `note` |
| `turath_last_read` + `quran_reading_minutes_log` | `read` / `opened`, `duration` from minutes log |
| `memorization_progress` station changes | `memorize`; `completed` on final station |
| Turath page cache hits during a reading session | `read` per page |

Projection runs once at migration + incrementally; each projected event
gets a deterministic `idempotency_key` so re-running is safe.

### 3.3 Quality gating (anti fake-session, anti-spam) — computed at ingest

`quality ∈ [0,1]` = product of independent gates, each ∈ [0,1]:

- `g_duration` — for timed events: `clamp01(duration_ms / T_expected(type,item))` capped at 1; a `read` of a 400-word page in 3 s → ~0.1.
- `g_pace` — plausible reading pace: `1` if `words_per_min ≤ P_max`, ramps to `0` above `2·P_max` (skimming/auto-scroll).
- `g_idle` — fraction of the session with foreground + input activity (from existing app-lifecycle signals); a backgrounded "session" → ~0.
- `g_rate` — burst cap: the k-th event of the same `(item,type)` within `W_burst` gets weight `1/√k` (diminishing), and events beyond `N_burst` in `W_burst` get `0`.
- `g_dup` — `0` if an event with the same `idempotency_key` already exists (row rejected), else `1`.

An event with `quality ≈ 0` is stored (for audit) but contributes nothing.
**Effective count** everywhere = `n_eff = Σ quality`, never `COUNT(*)`.

### 3.4 What is NOT an event

Passive things the app does (prefetch, cache warm, notification shown) never
create events. Only student-initiated, foreground, quality-passing actions.

---

## 4. Shared math (used by many indicators)

All constants are named and live in one file (§16).

### 4.1 Normalization helpers

- `clamp01(x) = max(0, min(1, x))`
- `sat(x, k)` — saturating / diminishing returns: `x / (x + k)`, ∈ [0,1), used for cumulative counts so grinding is sub-linear. `sat(k,k)=0.5`.
- `logistic(x; x0, s) = 1 / (1 + e^-((x-x0)/s))` — soft squash for unbounded quantities into [0,1].
- `rel(x, ref)` — relative-to-own-baseline: `logistic(x/ref; 1, S_rel)`; `x=ref → 0.5`. Used so "efficiency" etc. are compared to the student's own history, not an absolute.

### 4.2 Time decay

`decay(Δt_days; H) = 0.5 ^ (Δt_days / H)` — half every `H` days. Each metric
declares its own half-life `H` (§16); there is **no single global decay**.

- Retention: fast decay, `H_ret` modulated by spacing (§5.1).
- Coverage / "did read": **no decay** — you did read it; it stays counted.
- Consistency: rolling window, not decay.
- Neglect: *grows* with time (it is `1 - recency`, effectively).
- KnowledgeStrength: slow decay, `H_know`.

### 4.3 Sparse-data shrinkage (Beta–Binomial)

A rate from few trials is unreliable. For any success/attempt rate:

```
shrunk_rate = (successes + α0) / (attempts + α0 + β0)
```

with a category-specific prior `(α0, β0)` whose mean `α0/(α0+β0)` is the
typical rate for that category and whose weight `α0+β0` is `W_prior`
"virtual trials" (§16). Example: prior mean 0.65, weight 10 → `α0=6.5,
β0=3.5`. With 2 real reviews (1 success): `shrunk = (1+6.5)/(2+10) = 0.625`
— it barely moves from the prior, correctly.

### 4.4 Bounded composition (anti score-inflation)

Every L2 composite is either:
(a) a **weighted mean** of components each already ∈ [0,1], with weights
`≥ 0` summing to 1 → result ∈ [0,1] by construction; or
(b) a `logistic(...)` squash of a documented linear form.
Never an unbounded sum. The build asserts `0 ≤ value ≤ 1` for every L2/L4
node. Penalty terms are applied then re-clamped.

### 4.5 Confidence (see §9) multiplies **trust**, never the value

Confidence does not scale a metric's value; it gates whether the value is
shown strongly, shown tentatively, or replaced by "insufficient data".

---

## 5. L2 composite indicators

Each: **formula · inputs (L1) · range · window · decay · reason template.**

### 5.1 Retention(item)  ∈ [0,1] — predicted recall probability *right now*

```
base       = shrunk_rate(successful_recall, review_attempts)        // §4.3
H_ret_eff  = H_ret0 · (1 + a_spacing · n_eff(successful_recall))     // spacing effect
Retention  = clamp01( base · decay(days_since_last_review; H_ret_eff) )
```

- Inputs: `successful_recall`, `failed_recall`, `days_since_last_review`, category prior.
- If `review_attempts_eff < 1` → Retention is **undefined**, not 0 (confidence handles it).
- reason: `"احتُفظ ~{base}% أساسًا، ثم انخفض بمرور {Δt} يومًا (نصف عمر {H_ret_eff}ي) ⇒ {Retention}%"`.

### 5.2 KnowledgeStrength(scope)  ∈ [0,1] — depth of study of a topic/book/ayah, decayed

```
raw   = Σ_events  dw(type) · quality · decay(age_days; H_know)
KS    = sat(raw, K_know)                                            // diminishing, bounded
```

Scope can be an item, a book, or a category (sum over its items). reason
lists top contributing events.

### 5.3 DepthScore(item)  ∈ [0,1] — "studied" vs "just opened"

```
ladder_cov = (# distinct depth-ladder rungs touched with quality>Q_min) / RUNGS_TOTAL
avg_depth  = Σ dw(type)·quality·recency_w / Σ quality·recency_w      // recency_w = decay(age; H_depth)
DepthScore = w_lc · ladder_cov + w_ad · avg_depth                   // w_lc + w_ad = 1
```

Distinguishes `read once` (≈0.25) from `read + highlight + note + review`
(≈0.8). reason: `"فتحت + قرأت فقط — لا تظليل ولا ملاحظة ولا مراجعة"`.

### 5.4 ConsistencyScore(scope, D days)  ∈ [0,1]

```
active_days   = # days in [now-D, now] with ≥1 quality-passing event on scope
coverage      = active_days / D
burstiness    = stddev(daily_load) / (mean(daily_load) + ε)         // 0 = even, high = spiky
Consistency   = coverage · (1 - clamp01(burstiness / B_max))
```

reason: `"درست في {active_days} من {D} يومًا، وبتوزيع {even|متذبذب}"`.

### 5.5 NeglectScore(item within category)  ∈ [0,1] — ignored *relative to peers*

```
gap        = days_since_last_event(item)
peer_gap   = median days_since_last_event over the category's *started* items
Neglect    = clamp01( (gap - peer_gap) / (peer_gap + N_k) )
started    = has ≥1 event but progress < length_units
```

An item you never started is not "neglected" (it's just not begun — a
different signal). reason: `"لم تُفتح منذ {gap}ي، بينما متوسط بقية كتب {category} {peer_gap}ي"`.

### 5.6 MasteryScore(item)  ∈ [0,1]

```
Mastery = w1·Retention + w2·DepthScore + w3·min(1, progress/length_units) + w4·sat(n_eff(successful_recall), M_k)
          (Σ wi = 1; Retention term dropped & weights renormalized if Retention undefined)
```

### 5.7 StudyCoverage(book/plan)  ∈ [0,1] — richer than pages/total

```
progress_units = Σ over pages/passages  min(1, Σ_read_events_on_page quality)   // a page skimmed 5× ≠ 5
Coverage       = w_p·(progress_units / length_units)
               + w_r·sat(n_eff(reread), C_reread_k)
               + w_a·sat(annotation_count, C_anno_k)
               + w_v·sat(n_eff(review),  C_review_k)
               (Σ w = 1)
```

length_units uses **length + density normalization** (§13.7): a 555-page
dense uṣūl book has more units than a 90-page matn.

### 5.8 StudyEfficiency(scope)  ∈ [0,1] — progress per unit time, vs own baseline

```
rate      = Δprogress_units(window) / studytime_hours(window)         // guard: hours ≥ T_min_hours
Efficiency = rel(rate, own_median_rate(scope_or_category))            // §4.1
```

Undefined (not 0) if `studytime_hours < T_min_hours`.

### 5.9 Time intelligence (book / plan scope)

```
eff_daily_rate      = robust_mean(progress_units per active day, last W_rate days)   // trimmed mean
EstimatedCompletion = (length_units - progress_units) / eff_daily_rate               // days; ∞ if rate≈0
DailyRequiredLoad   = (length_units - progress_units) / days_until_deadline           // if a deadline/plan exists
SustainableLoad     = p75(daily_load, last W_sust days)
OverloadRisk        = clamp01( DailyRequiredLoad / (SustainableLoad + ε) )            // ≥1 ⇒ plan not feasible as-is
PlanFeasibility     = 1 - OverloadRisk
RecoveryTime        = (due_review_items_after_gap · avg_review_minutes) / daily_review_capacity_minutes
```

All carry confidence from rate stability (variance of the per-day rate).

---

## 6. L3 — Confidence

```
n_eff        = Σ quality over the events feeding this metric, in-window
span_factor  = clamp01( observed_span_days / SPAN_ref )              // few events over 1 day ⇒ low
diversity    = (# distinct event types present) / (# types the metric can use)
recency_f    = decay(days_since_last_relevant_event; H_conf)
Confidence   = (1 - e^(-n_eff / N_ref)) · (w_s·span_factor + w_d·diversity + w_r·recency_f)   // w_s+w_d+w_r = 1
```

Thresholds (§16): `< C_min_display (≈0.35)` → the metric/decision is
**not shown as a number**; the engine returns `kind='gather_data'` or a
label `"بيانات قليلة"`. `0.35–0.6` → shown as tentative ("تقديري"). `> 0.6`
→ shown normally. The engine is explicitly allowed and required to say
**"لا أملك بيانات كافية للحكم بعد."**

---

## 7. L4 — Decisions

### 7.1 ReviewPriority(item)  ∈ [0,1]

```
overdue      = clamp01( days_since_last_review / expected_interval(item) )   // expected_interval from spacing schedule
terms (each ∈ [0,1]):
  t_forget   = 1 - Retention                       weight w_f
  t_neglect  = NeglectScore                        weight w_n
  t_important= importance                          weight w_i
  t_overdue  = overdue                             weight w_o
  (w_f+w_n+w_i+w_o = 1)
penalty:
  p_recent   = P_recent · sat(n_eff(review in last W_recent days), 1)        // just reviewed ⇒ lower
ReviewPriority = clamp01( w_f·t_forget + w_n·t_neglect + w_i·t_important + w_o·t_overdue - p_recent )
```

Gated by Confidence. reason renders each term's contribution with sign, e.g.
```
Review Priority = 0.91
 + t_forget   0.59 × 0.40 = 0.236   (احتفاظ 41%)
 + t_neglect  0.78 × 0.25 = 0.195   (لم تُراجع منذ 37ي، متوسط القسم 14ي)
 + t_important 0.70 × 0.20 = 0.140
 + t_overdue  1.00 × 0.15 = 0.150   (الفاصل المتوقع 12ي، مضى 37ي)
 − p_recent   0.02                  (روجعت مرة هذا الأسبوع)
 = 0.699 …  (worked fully in §14)
```

### 7.2 NextBestItem(after a session) — recommendation engine, no AI

```
1. CANDIDATES  (bounded set, each with a candidate kind):
   - review:   items with ReviewPriority ≥ RP_gate, top K1
   - continue: items with 0 < progress < length_units, ordered by (freshness · DepthScore⁻¹), top K2
   - related:  via knowledge_edges from what was studied this session (same surah/juz, same category,
               cross_references), not already mastered, top K3
   - revise:   items with a failed_recall in last W_revise days, top K4
2. SCORE(candidate) = clamp01( Σ β_kind_term )  — per-kind bounded formula; e.g.
     review:   ReviewPriority
     continue: γ1·(1 - progress_ratio) + γ2·recency_of_start + γ3·DepthScore     (Σγ=1)
     related:  δ1·edge_strength + δ2·session_topic_match + δ3·(1 - KnowledgeStrength)
     revise:   1 - Retention  (of the failed item)
3. DIVERSITY: at most 1 candidate per (kind, category) in the final list; MMR-style
   re-rank with λ_div so the list isn't 5 reviews of the same surah.
4. GATE: if best candidate Confidence < C_min_display → return kind='gather_data'
   ("افتح كتابًا أو راجع آية لأتمكّن من الاقتراح") instead of a weak guess.
5. EXPLAIN: each shown candidate carries its ScoreExplanation.
```

### 7.3 BalanceReport(across categories) — the "decision, not a score" output

Computes, per category the student has started:
`time_share`, `item_count_started`, `item_count_stale (gap > STALE_days)`,
`avg DepthScore`, `avg Retention`. Emits **statements**, each a
`ScoreExplanation`, e.g.:

> قرأت 14 كتابًا في العقيدة، لكن **73%** من وقتك (آخر 60 يومًا) على 3 كتب،
> و**11** كتابًا بدأتها ولم تعد إليها منذ **45+** يومًا.
> ⇒ اقتراح المراجعة اليوم: «{top neglected started item}» (أولوية {RP}).

No AI phrasing — the sentence is a fixed template filled from the numbers.

---

## 8. Knowledge graph inputs

`knowledge_edges(from_kind, from_id, rel, to_kind, to_id, strength)` where
`rel ∈ {in_surah, in_juz, on_page, in_category, by_author, explains,
cross_ref, annotates}`. Derived from existing data (Quran surah/juz/page
tables, catalog `cat_id`/`author_id`, annotation anchors, Phase 5
`cross_references` when built). Used by:

- **importance(item)** = `w_c·category_importance + w_g·graph_centrality + w_u·user_signal`
  where `graph_centrality` = normalized degree in the edge graph (an ayah
  many hadith/books point at scores higher); `user_signal` =
  `sat(annotation_count_on_item, I_k)` (the student themself marked it).
  Not a free-text user slider.
- **related candidates** (§7.2 step 1) traverse edges 1–2 hops.
- **BalanceReport** groups by `in_category` / `by_author`.

---

## 9. Mushaf layer hooks (when MushafDatabase lands, priority 2/5)

Each `md-word` gives `(surah, ayah, word_index, page, line, hafs, imlaey)`.
This lets these become real `StudyItem`s / event scopes:

- `quran_word` items → per-word `failed_recall` from the recitation
  mistake log (`recitation_mistakes` already has surah/ayah; word index
  from alignment) → **word-level weak-spot map**.
- ayah annotations anchored by `(surah, ayah, word_range)` (see
  `STUDY_INTELLIGENCE_VISION.md` §1/§6) feed the same L1/L2 as book
  annotations.
- KnowledgeStrength can be computed per surah/juz/page.
- an edge `explains` between an ayah and its tafsir passages lets the
  engine relate hifz progress to tafsir study.

Nothing here changes L1–L4 math — it only adds scopes/items.

---

## 10. Weaknesses & mitigations (analysed before implementation)

| weakness | how it breaks a naïve engine | mitigation in this spec |
|---|---|---|
| **Sparse data** | 1 review ⇒ Retention 0% or 100% | Beta shrinkage §4.3; metric "undefined" not 0; Confidence gate §9 |
| **Selection / survivorship bias** | only finished books get scored, abandoned ones invisible | NeglectScore §5.5 explicitly targets *started, unfinished*; BalanceReport counts `item_count_stale` |
| **Score inflation** | cumulative sums grow forever ⇒ everything trends to "great" | all L2 bounded [0,1] by construction §4.4; cumulative inputs pass through `sat(x,k)` (diminishing) |
| **Event duplication** | double-fired events double the counts | `idempotency_key` UNIQUE §3; `g_dup` gate |
| **Fake / idle sessions** | leaving a book open overnight = huge StudyTime | `g_duration·g_pace·g_idle·g_rate` quality product §3.3; `n_eff` not `COUNT` everywhere |
| **Book difficulty variance** | 10 pages of uṣūl ≡ 10 pages of a thin matn | `difficulty` prior per category §13.6 folded into `length_units` and Efficiency baseline |
| **Book length variance** | Coverage = pages/total unfair across a 90-pg vs 555-pg book | `length_units` normalization §13.7 (pages × page-density × difficulty) |
| **Long absence** | student returns, everything looks "due", panic list of 400 | RecoveryTime §5.9; ReviewPriority capped and diversified; NextBestItem returns a *small* ranked set, not the backlog |
| **Recency bias** | last 3 days dominate every metric | explicit windows per metric §5; decay half-lives tuned per concept §16; Consistency uses full window |
| **Goodhart / gaming** | user spam-highlights to raise a score | outputs are *advisory decisions*, not points/XP the user chases; diminishing returns; quality gating; DepthScore needs the *ladder*, not volume |
| **Cold start** | new user, no history ⇒ engine silent or wrong | Confidence < `C_min` ⇒ `gather_data` decisions ("افتح كتابًا / راجع آية"); category priors give sane defaults |
| **Constant drift** | someone re-tunes a weight, all history shifts silently | formula registry §15: every formula has `id@version`; changing it bumps version, invalidates `indicator_cache`, and the UI can show which version produced a number |
| **Divide-by-zero / tiny denominators** | Efficiency, EstimatedCompletion explode | guards: `T_min_hours`, `eff_daily_rate ≈ 0 ⇒ EstimatedCompletion = ∞` shown as "غير محدد بعد" |

---

## 11. Anti-fake-number rules (enforced, not aspirational)

1. **No number without** `formula_id@version`, `data_sources`, `window`, `confidence`, `reason`. A metric object missing any of these is invalid and not rendered.
2. **Bounded by construction.** Build asserts `0 ≤ value ≤ 1` for every L2/L4 (time-intelligence day counts excepted, but those carry stability confidence).
3. **Confidence gate.** `confidence < C_min_display` ⇒ never shown as a number; shown as "بيانات قليلة" or turned into a `gather_data` action.
4. **No absolute praise.** No "أنت متقدم 87%". Statements are relative + explained ("73% من وقتك على 3 كتب من 14").
5. **Auditable composition.** Every composite stores `contributions[]`; the tap-through screen reconstructs the value from them (must equal `value` within ε).
6. **Formula registry.** `formula_registry(id, version, expression_text, params_json, changed_at)`. Changing a formula = new version row; `indicator_cache` rows carry the version that made them; recompute is explicit.
7. **One constants file.** All of §16 in `lib/study_engine/engine_config.dart` (when built); no magic numbers scattered.
8. **Deterministic + pure.** Given the same `study_events` + config, outputs are identical. A golden-vector test (§13) locks this.

---

## 12. Data model (SQLite, additive; migration number TBD when built)

```
study_items(id PK, kind, anchor_json, category_id, importance REAL, difficulty REAL,
            length_units REAL, created_at, updated_at)
study_events(id PK, study_item_id FK, type, at INTEGER, duration_ms INTEGER,
             payload_json, source, idempotency_key TEXT UNIQUE, quality REAL,
             INDEX(study_item_id, type, at), INDEX(at))
knowledge_edges(from_kind, from_id, rel, to_kind, to_id, strength REAL,
                PRIMARY KEY(from_kind, from_id, rel, to_kind, to_id))
indicator_cache(scope_kind, scope_id, key, value REAL, window TEXT,
                input_snapshot_json, formula_id, formula_version, computed_at,
                PRIMARY KEY(scope_kind, scope_id, key, window))
formula_registry(id, version, expression_text, params_json, changed_at,
                 PRIMARY KEY(id, version))
engine_run_log(id PK, ran_at, trigger, items_touched, notes)   -- for auditing recomputes
```

`study_items` / `study_events` **do not copy content** — `anchor_json`
points at `quran_ayat`, `turath_annotations`, `turath_catalog_books`, etc.
Existing tables project *into* `study_events` (§3.2); they are not replaced.

---

## 13. Constants that need real values before/at implementation

(Not final — chosen at design review with a few real data samples. Listed
so none is a hidden magic number.)

| group | constant | provisional | rationale |
|---|---|---|---|
| decay | `H_ret0` | 9 d | ~SM-2 first interval; half-life of unreviewed recall |
| decay | `a_spacing` | 0.8 | each successful review ~doubles the interval by 2–3 reviews in |
| decay | `H_know` | 120 d | study depth fades slowly |
| decay | `H_depth` | 45 d | "how deeply *lately*" |
| decay | `H_conf` | 30 d | stale data ⇒ low confidence |
| shrink | prior mean / weight `W_prior` | 0.65 / 10 | typical adult recall pass-rate; 10 virtual trials |
| consistency | window `D` | 21 d | 3 weeks catches weekly rhythm |
| consistency | `B_max` | 2.0 | burstiness above 2σ/μ ⇒ fully penalised |
| neglect | `N_k` | 7 d | softens the ratio for short peer gaps |
| confidence | `N_ref` | 8 | ~8 quality events ⇒ ~63% of the sample factor |
| confidence | `SPAN_ref` | 21 d | want events spread over ≥3 weeks |
| confidence | `C_min_display` | 0.35 | below ⇒ "بيانات قليلة" |
| review priority | `w_f, w_n, w_i, w_o` | 0.40, 0.25, 0.20, 0.15 | forgetting first, then neglect |
| review priority | `P_recent` | 0.15 | just-reviewed damping |
| depth | `w_lc, w_ad` | 0.5, 0.5 | ladder coverage vs recent avg depth |
| efficiency | `T_min_hours` | 0.5 h | below ⇒ undefined |
| quality | `P_max` (words/min) | 350 | above ⇒ skimming; `2·P_max` ⇒ 0 |
| quality | `N_burst`, `W_burst` | 6, 10 min | > 6 same events in 10 min ⇒ 0 |
| length | page-density factors | per category | uṣūl/ḥadīth-sharḥ ≈ 1.4, matn ≈ 0.7, etc. — from a small manual sample |
| difficulty | category difficulty prior | per cat_id | العقيدة/أصول الفقه higher; رقائق lower |

---

## 14. Worked numeric examples (verify by hand)

Using the provisional constants above.

### Example A — one ayah, review priority

Facts: 3 review attempts (2 `successful_recall`, 1 `failed_recall`), all
quality ≈ 1; total `successful_recall` events over time (incl. earlier
sessions) `n_eff = 5`; last review 37 days ago; expected interval 12 days;
`importance = 0.70`; 1 `review` in the last 7 days (`W_recent`).

```
shrunk base   = (2 + 6.5) / (3 + 10)              = 8.5 / 13      = 0.654
H_ret_eff     = 9 · (1 + 0.8·5)                   = 9 · 5         = 45 d
decay(37;45)  = 0.5^(37/45) = 0.5^0.822           = e^(-0.822·ln2)= e^-0.570 = 0.566
Retention     = 0.654 · 0.566                     = 0.370   → 37%

t_forget      = 1 - 0.370                          = 0.630
peer_gap (البقرة, this student) = 14 d ; gap = 37
Neglect       = clamp01( (37 - 14) / (14 + 7) )    = 23/21 = 1.095 → 1.000
overdue       = clamp01( 37 / 12 )                 = 1.000
p_recent      = 0.15 · sat(1, 1) = 0.15 · 0.5      = 0.075

ReviewPriority = 0.40·0.630 + 0.25·1.000 + 0.20·0.70 + 0.15·1.000 − 0.075
              = 0.252 + 0.250 + 0.140 + 0.150 − 0.075
              = 0.717
```

Confidence: `n_eff` for this metric ≈ 5 quality events over a 60-day span,
3 distinct types (review / success / fail), last relevant event 37 d ago.
```
sample_f   = 1 - e^(-5/8)          = 1 - 0.535 = 0.465
span_f     = clamp01(60/21)        = 1.000
diversity  = 3/4                   = 0.750
recency_f  = 0.5^(37/30)           = 0.5^1.233 = 0.425
Confidence = 0.465 · (0.4·1.000 + 0.3·0.750 + 0.3·0.425)
          = 0.465 · (0.400 + 0.225 + 0.128) = 0.465 · 0.753 = 0.350
```
`0.350 ≥ C_min_display (0.35)` — just shown, labelled **تقديري**. UI:

> **راجع «آية الكرسي» اليوم — الأولوية 0.72** (تقديري، ثقة 35%)
> + احتفاظ 37% · + مهملة (37ي مقابل 14ي للقسم) · + متأخرة (المتوقع 12ي)
> − روجعت مرة هذا الأسبوع

### Example B — a book, "return to this" candidate

`العقيدة الواسطية`: `length_units` = 90 pages × density 1.4 × difficulty
1.1 ≈ 138.6; `progress_units` = 40 (pages read, quality-summed); events:
mostly `read` + a few `opened`, **no `note`, no `review`**; last event 45
days ago; category median started-item gap = 12 d.

```
Coverage: w_p·(40/138.6) + w_r·sat(0, k) + w_a·sat(2, k) + w_v·sat(0, k)
        ≈ 0.6·0.289 + 0.15·0 + 0.15·(2/(2+3)) + 0.10·0
        = 0.173 + 0 + 0.060 + 0 = 0.233     → 23% covered
DepthScore: ladder rungs touched = {opened, read} = 2 / 7 → ladder_cov = 0.286
            avg_depth (recent, all read≈0.4)      ≈ 0.40
            = 0.5·0.286 + 0.5·0.40 = 0.343       → shallow, "قرأت فقط"
Neglect: (45 - 12) / (12 + 7) = 33/19 = 1.74 → 1.000
```
NextBestItem "continue" score: `γ1·(1 - 40/138.6) + γ2·recency_of_start +
γ3·DepthScore` with γ = (0.5, 0.2, 0.3), start ~60 d ago (recency ≈ 0.25):
`0.5·0.711 + 0.2·0.25 + 0.3·0.343 = 0.356 + 0.050 + 0.103 = 0.509`.
Appears in the list as: *"أكملت 23% فقط، ولم تعد إليها منذ 45 يومًا"*.

### Example C — cold start ⇒ engine declines

New user: 2 `opened` events, 1 day span, 1 type.
```
sample_f = 1 - e^(-2/8) = 0.221 ; span_f = 2/21 = 0.095 ; diversity = 1/4 = 0.25 ; recency ≈ 1
Confidence = 0.221 · (0.4·0.095 + 0.3·0.25 + 0.3·1.0) = 0.221 · (0.038+0.075+0.300) = 0.221·0.413 = 0.091
```
`0.091 < 0.35` ⇒ **no scores shown.** Decision: `kind='gather_data'` —
"افتح كتابًا واقرأ صفحة أو راجع آية، وسأبدأ التحليل بعد بضع جلسات."

---

## 15. Hand-checkable test vectors (locked once approved)

| id | input | expected (this spec + §13 constants) |
|---|---|---|
| decay-1 | `decay(9, 9)` | `0.5` |
| decay-2 | `decay(37, 45)` | `0.566` (±0.001) |
| shrink-1 | `shrunk(1, 2)` prior 0.65/10 | `0.625` |
| shrink-2 | `shrunk(2, 3)` prior 0.65/10 | `0.654` |
| sat-1 | `sat(2, 3)` | `0.4` |
| retention-A | Example A inputs | `0.370` (±0.002) |
| neglect-A | gap 37, peer 14, `N_k` 7 | `1.000` (clamped from 1.095) |
| rp-A | Example A | `0.717` (±0.003) |
| conf-A | Example A | `0.350` (±0.005) |
| conf-C | Example C | `0.091` (±0.005) → `gather_data` |
| bound-1 | any composite with adversarial huge inputs | `value ∈ [0,1]` |
| dup-1 | two events, same `idempotency_key` | second rejected, counts unchanged |
| idle-1 | `read` event, `duration_ms`=2000 on a 500-word page | `quality ≤ 0.1` |

These become the golden tests of the eventual implementation; every one is
computed above or trivially by calculator.

---

## 16. Implementation phasing (when we reach priority step 4 — not now)

1. `study_events` schema + projection from existing tables + `idempotency`/`quality` at ingest. Verify event counts against raw tables.
2. L1 base indicators + `indicator_cache` + golden vectors §15.
3. L2 composites, each behind its `formula_registry` id, all bounded-asserted.
4. L3 confidence + the `gather_data` behaviour.
5. L4 ReviewPriority + BalanceReport (statements only, no UI polish).
6. NextBestItem (candidates → score → diversity → gate → explain).
7. Only then any dashboard/UI, and only with the tap-through `contributions` view.
8. Mushaf word/ayah scopes once MushafDatabase architecture (priority 2) exists.

Until step 1 begins, the only requirement on current work (`79-sa-D`,
`D2`, `D-ayah`) is: keep annotations/notebook a decoupled view with stable
ids + timestamps, so they can emit `study_events` later without change.
