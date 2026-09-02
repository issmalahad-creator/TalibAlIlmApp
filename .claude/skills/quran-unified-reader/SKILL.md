---
name: quran-unified-reader
description: >-
  Load before touching the unified Quran reader in TalibAlIlmApp — the mushaf
  page renderer, the tap→identity pipeline, the Word/Ayah Knowledge Surfaces,
  the KnowledgeGateway, night mode, the surah index, or anything that reads
  `MushafSemanticReaderScreen` / `MushafPageView` / `mushaf_*` geometry. It
  carries the runtime architecture (the 6 layers), the exact contracts each
  layer exposes, the 604-page SVG pipeline, and the P0 status + what is still
  unbuilt. Pair with `quran-engineering` (data/identity) and
  `quran-premium-3d-ui` (visual/motion).
---

# Quran Unified Reader — runtime architecture

`MushafSemanticReaderScreen` **is** the one Quran reader now (the old
`quran_reading_screen.dart` still exists but is slated for deletion in P2
after a Feature Parity Checklist — do not delete it early, do not wire new
features into it). Full status: `docs/quran/QURAN_UNIFIED_READER_P0_STATUS.md`.
Plan: `C:\Users\ismail\.claude\plans\jolly-wibbling-forest.md`.

## The 6 layers — keep them separate

```
Visual        assets/mushaf/pages_svg/NNN.svg.gz   (604 pages, gzip, ~75 MB)
   ↓          viewBox 0 0 382.68 547.09 == mushaf_* coords → NO transform
Geometry      mushaf_* tables (word boxes + aya marks, all 604 pages)
   ↓
Interaction   MushafPageLayout  (pure geometric hit-test)
   ↓
Selection     QuranSelection    (lib/models/quran_selection.dart — the ONE model)
   ↓
Knowledge     KnowledgeGateway  (lib/services/quran_learning/knowledge_gateway.dart)
   ↓
Presentation  Word / Ayah Knowledge Surface, IrabViewScreen, LearningLessonScreen
```

Rule: `MushafPageView` knows only geometry + what highlight to paint. It
never imports a repository, the gateway, or a feature screen. No knowledge
logic leaks down; no rendering choice leaks into the schema.

## MushafPageView contract (`lib/widgets/mushaf_page_view.dart`)

- **One** page-level `GestureDetector`. `handleTap`: `ayaMarkAtPoint` first
  (→ `onAyaMarkTap(MushafAyaMark)`), then `wordAtPoint` (→
  `onWordTap(MushafWord)`), else nothing. **No `nearestWord`, no distance
  threshold, no per-word GestureDetector.**
- `MushafPageLayout.ayaMarkAtPoint(x,y,{pad=2})` / `.wordAtPoint(x,y,{pad=1.5})`
  — box-containment only (`pad` is tolerance, not nearest search); marks
  with null box are skipped.
- Params: `selectedWord`, `selectedAyah`, `onWordTap`, `onAyaMarkTap`,
  `onWordLongPress`, `artInk`, `textColor`, `debugBoxes`. (No `onAyahTap`,
  no `highlightColor` — removed.)
- **`_contentBox(layout)`** fits the page's inked content to the viewport,
  kept horizontally centred about the viewBox centre (the stored
  `md-page-inner` rect is off-centre — do NOT fit to it) with ~½ line of
  headroom. The hit-test, the SVG, and the Selection Layer all use this
  exact `scale`/`dx`/`dy` — change one, change the mirror in
  `test/mushaf_page_view_test.dart`'s `_toWidget`.
- **`_PageArt`** (StatefulWidget, static `_cache`): loads
  `assets/mushaf/pages_svg/NNN.svg.gz` via `rootBundle.load` → `gzip.decode`
  → `utf8.decode` (MUST be utf8 — never `String.fromCharCodes`) →
  `SvgPicture.string(fit: BoxFit.fill)`. `artInk != null` →
  `ColorFilter.mode(ink, BlendMode.srcIn)` (the art is monochrome, so this
  re-inks the whole page — used for night mode). `mushafArtBundled(page)` =
  `1..604`. Text fallback (`_RenderedLine`) only if a file is missing.
- **Selection Layer** = `_SelectionOverlay` (AnimationController 180ms,
  `easeOutCubic`) + `_SelectionPainter`: word = gold `0xFFD9A441` fill 0.13
  + 1px stroke 0.30 + scale 0.96→1 about centre; ayah = per-line fill 0.07,
  no stroke. `CustomPaint` on top — never touches the SVG, never darkens
  glyph ink.

## QuranSelection (`lib/models/quran_selection.dart`)

Framework-free (`MushafBox` only). `QuranSelection.word(MushafWord)` /
`.ayah(MushafAyaMark)`. Fields: `page, surah, ayah, wordIndex?, type
(word|ayah), wordBox?, textUthmani?`. `sameAs()` for "return to the exact
spot". Every surface reads this — nothing recomputes identity.

## KnowledgeGateway

- `KnowledgeProvider` is now an `abstract class` with a concrete
  `factsForAyah(surah,ayah) async => const []` default → providers **extend**
  it (not `implements`) and override only what they have.
- `factsFor({surah,ayah,wordIndex})` (word) and `factsForAyah({surah,ayah})`
  (whole ayah) → `KnowledgeResult {byDomain, sources, overallState}`.
  **Display gate**: a fact is dropped unless its `SourceReference` is
  `displayable` (classification VERIFIED|SOURCE_BACKED|PROJECT_SPECIFIC). If
  a provider emits `source_ref_id` X, a `source_references` row X must be
  seeded or the fact never shows (this bit the tafsir editions — fixed by
  adding `src:tafsir:*` rows to `prototype.json` + bumping `version`).
- Providers: `QacGrammarProvider` (inert, `_enabled=false`),
  `LocalKnowledgeProvider` (`knowledge_facts`), `LocalTafsirProvider`
  (`tafsir_entries`, Arabic editions).
- `QuranLearningRepository` wraps both + concepts + learning-path +
  append-only `study_events` (`logEvent` drops any verb not in
  `StudyEventVerbs.all` — there are NO quiz verbs, by design).

## The Knowledge Surfaces (`lib/screens/quran_learning/knowledge_surface.dart`)

`showWordKnowledgeSurface` / `showAyahKnowledgeSurface` → `Future<Object?>`
(resolves `'applied'` when the student came back via «طبّق» — the reader
then keeps `_selWord` set instead of clearing). Both use
`showModalBottomSheet(barrierColor: black 0.10)` + `DraggableScrollableSheet`
(0.42–0.92) + `_SurfaceShell` (gold top border, `DepthShadows.modal`, grab
handle) + `_ScrollControllerScope` so the inner `ListView` drives drag.

- **Word**: header = word in `AmiriQuran`; Tier 1 (always) = إعراب /
  العلامة / لماذا / أبرز علاقة from the first `nahw` fact
  (`role_ar/sign_ar/irab_text/relations[0]{rel_ar,to_word}`); «التفاصيل» →
  صرف (`root/pos_ar/pattern/lemma/note`) / بقية العلاقات / تجويد
  (`rules[]{rule_ar,rule_family}`) / تفسير مرتبط; المصادر = one compact
  line; «تعلّم هذا» (→ `LearningLessonScreen` via `conceptId`, else
  `IrabViewScreen`) + «الإعراب التفاعلي».
- **Ayah**: header = the ayah text (`QuranReadingRepository.ayahAt`) +
  number; «ماذا أتعلم؟» chip line; segmented (تفسير/ترجمة/تجويد/علوم/مصادر);
  tafsir = edition chips + snippet + source + «التفسير كاملًا» →
  `AyahStudyScreen`; «أضف لدفتري» + «إعراب الآية».
- Missing data → `basicText('ql_no_data_element', lang)` — calm, centred,
  never an empty section, never a guess.
- Source line = `الاسم · {SourceReference.badgeAr}` (موثّق/مقبول/داخلي) —
  never the raw `license` string.

## 604-SVG bundling

`tool/` gzip each `MushafDatabase-.../SVG V1.01/NNN.svg` (git-ignored source)
→ `assets/mushaf/pages_svg/NNN.svg.gz`. `pubspec.yaml` lists the directory.
APK is ~275–330 MB — accepted for now (≤ 500 MB); shrinking (download pack)
is a future, decision-gated task, no re-architecture.

## What is NOT built yet (see the status doc for the full list)

P1: audio bar (`QuranAudioEngine` + sync `QuranSelection`), session timer,
journey countdown, recitation entries, the full «طريقة العرض» menu (only
night mode + surah index + go-to-page + notebook are wired). P2: delete the
old reader + rewire `home_screen.dart:167` / `wird_screen.dart:85` /
`companion_card.dart:52`. Polish: container-transform surface entrance;
full 13-lang for `ql_*` keys (ar+en now, ar fallback active); seed
knowledge beyond al-Fātiḥa + al-Ikhlāṣ (needs MASAQ file from Ismail);
البيان/الإعجاز track; VT-3 Tanzil↔MushafDatabase alignment.
