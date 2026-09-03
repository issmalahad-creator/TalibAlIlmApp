---
name: quran-premium-3d-ui
description: >-
  Load before building or changing ANY mushaf/learning UI in TalibAlIlmApp —
  the reader, the Selection Layer, the Word/Ayah Knowledge Surfaces, the
  tafsir experience, the lesson screen, or any panel that opens from a tapped
  word or ayah. It carries the project's premium visual + motion language:
  knowledge emerges from the mushaf (not beside it), luxury lives in
  motion/depth/hierarchy/type/space (not color or effects), the science stays
  primary and calm, progressive disclosure over tab bars, the mushaf is
  visually sacred (nothing over the glyph ink), and — the Quick-Card rule —
  the surface is a fast-read card, never a reader: short excerpts + one «للمزيد»
  button to the dedicated page, never long text or crammed content in the
  user's face. Full spec: docs/quran/QURAN_PREMIUM_UI.md.
---

# Quran Premium 3D UI Skill

The standard visual + motion language for every mushaf and Quran-learning
screen. **Read `docs/quran/QURAN_PREMIUM_UI.md` in full before writing UI
code.** This file is the operational front; the doc is the detail.

Also load **`quran-engineering`** for any mushaf feature — its rules about
the SVG, word/ayah identity, tashkīl, and "no guessing / لا توجد بيانات
موثقة" bind here too.

## The one idea

`القرآن → الكلمة → المعرفة → التعلّم → التطبيق → العودة للقرآن`.
Not `القرآن → another screen → separate info`. Every panel starts at the
tapped word's on-screen position and returns to it.

## The 4 surfaces (all carry `(page, surah, ayah, wordIndex)`)

`Mushaf Surface` → `Selection Layer` → `Knowledge Surface` → `Lesson Surface`.
State comes from **one central `QuranSelection`** model — no screen
recomputes word/ayah identity.

## Build on what exists — do NOT invent tokens

| need | use |
|---|---|
| shadows | `DepthShadows.soft / floating / modal(tint)` (`lib/theme/depth.dart`) |
| accent | `DepthPalette.quran.accent` = gold `0xFFD9A441` — the only mushaf color |
| durations/curves | `AppMotion.fast 180 / normal 350 / premium 600` + `entranceCurve`/`exitCurve`/`stateCurve` (`lib/theme/motion.dart`) |
| radii | `AppRadius.sm 12 / md 14 / lg 18 / xl 22 / pill` |
| panel entrance mechanics | pattern of `lib/widgets/premium_modal.dart` (BackdropFilter ≤ blur, layered shadow, gold-tint border, rise+scale) |
| text styles | `AppTextStyles` for UI; mushaf font (`AmiriQuran`/`DigitalKhattMadina`) for Quran tokens ONLY |
| strings | `basicText(key, lang)` — 13 languages, RTL/LTR aware |
| page bg | warm cream `0xFFFBF6EE` / gradient `0xFFF5F0E6→0xFFEFE6D8`; night `0xFF121212` bg + `0xFF1E1B17` panel |

## Motion (max ONE `premium` transition per user action)

word tap → highlight grow-in (`fast`, easeOutCubic, scale 0.96→1) ·
highlight → Knowledge Surface (`premium`, chip expands+rises from the word
rect, ~6% overshoot) · drag handle → resize follows finger · drag-down past
threshold → dismiss to chip (`normal`, easeIn) → end on a `fast` pulse on
the word · open lesson (`premium` shared-axis, ayah header persists) ·
«طبّق» → reverse to the exact word · segment / tafsir-edition switch
(`normal` cross-fade + 8px slide). reduced-motion → replace all with a
`normal` fade.

## Selection Layer (CustomPaint over MushafPageView, never touches the SVG)

- Word: rounded rect around `MushafWord.box` +1.5pt, fill gold **0.10–0.14**
  (never > 0.15 over ink), 1px gold stroke ~0.30.
- Ayah: calmer — per-line rects (`ayahBoxes`), fill gold **0.06–0.08**, no
  stroke.
- One selection shown at a time; stays visible while its panel is open;
  clears in sync with panel dismissal.

## Knowledge Surface

Not a plain bottom sheet. Emerges as a chip at the word rect → expands into
a draggable panel. Mushaf stays **≥ 50% visible** (initial height ~62%, drag
to ~92%, drag down dismisses). Scrim `0.08–0.12`; blur ≤ 3 sigma behind the
panel only. Surface `AppColors.surface`, top radius `xl`,
`DepthShadows.modal(gold)`, grab handle.

**Header = the word itself** in mushaf font (~28) + `سورة الآية · ترتيب N`.

**Body = progressive disclosure, NOT tabs-first:**
- Tier 1 (always, the "seconds" answer): الإعراب · العلامة الإعرابية ·
  لماذا؟ · أبرز علاقة نحوية.
- Tier 2 (one "التفاصيل" tap): الصرف · الجذر · الوزن · بقية العلاقات ·
  التجويد · التفسير المرتبط.
- Tier 3: المصادر (chips → full `SourceReference`).
- Pinned action: **«تعلّم هذا»**.
- A row appears only with sourced data; whole domain empty → one calm line
  «لا توجد بيانات موثقة لهذا العنصر حاليًا». Never an empty tab/section.

**Ayah Knowledge Surface:** header = the ayah + medallion; Tier 1 «ماذا
أتعلم من هذه الآية؟»; then a **segmented control** (التفسير · الترجمة ·
التجويد · العلوم · المصادر), default التفسير — not 6 crammed tabs.

## Quick-Card rule — the surface is NOT a reader (Ismail, 2026-09-03)

The mushaf + ayah are the draw; tafsīr/sources are an **optional depth layer
behind a button**, never a crowded wall of text. Design every element on one
of three tiers, don't mix them:

| tier | time | shows | where |
|---|---|---|---|
| 1 glance | 3–8 s | one idea (إعراب / علامة / لماذا) | Tier-1 block |
| 2 quick read | 20–40 s | ayah + brief note + **~40–60-word tafsīr excerpt** + short tadabbur | card body, **no long scroll** |
| 3 deep | open | full tafsīr · sources · prev/next · search | **dedicated page** (`AyahStudyScreen`) |

- **No long text in the surface.** Any corpus/tafsīr text → `excerpt(t,
  maxChars: 200–320)` ending in «…»; the rest lives behind **one wide,
  obvious «للمزيد» / «التفسير كاملًا» button** per tab → `AyahStudyScreen`.
- **No cramming** — not 20 facts / 5 tafsīrs / 15 sources in the user's
  face. Ask: *"the least that makes them pause and reflect?"*
- Corpus layers (سبب النزول · إعراب من الكتب · ناسخ · فوائد · متشابهات ·
  آثار …) = short excerpt inside a **collapsed** `_CorpusSection`, ≤ 3
  items, + «توسّع في صفحة الآية».
- Translation tab: the one-line verse translation, shown in full (already
  short).
- **Don't build a second reader** inside the surface or duplicate
  `AyahStudyScreen`. Tafsīr is a *source*, not the product.
- Success = grasped in seconds, read without long scroll — **not** how many
  books are bundled. Priority: `UX → Readability → content hierarchy →
  accuracy → sources → content expansion`.
- Helpers: `excerpt()`, `moreButton()`, `_CorpusSection(open:false)` in
  `lib/screens/quran_learning/corpus_panels.dart`. Full spec:
  `docs/quran/QURAN_PREMIUM_UI.md` §4 + §4-bis.

## Never

parallax/tilt on the page while reading · glow/particles/loud gradients ·
6-tab bar · white sheet that hides the mushaf · animation > 600ms or >1
`premium` per action · mushaf dimmed below 50% · `GestureDetector` per word
or `nearestWord`/`distance<threshold` · shrinking/hiding the science for
decoration · anything over glyph ink > 0.15 alpha or casting a shadow on it.

## Pre-flight checklist

1. State from the central `QuranSelection`, not recomputed?
2. Panel emerges from the tap position and returns to it? Mushaf ≥ 50% visible?
3. Tier 1 answers إعراب/علامة/لماذا/علاقة with zero taps?
4. Every section has a `SourceReference`? Missing = explicit line, not a gap?
5. One `premium` transition only? reduced-motion falls back to fade?
6. Every string via `basicText`? Direction correct for the language?
7. Nothing touches the SVG or dulls the ink/tashkīl?
8. Quick-Card: no long text in the surface (excerpt ≤ ~320 chars), one «للمزيد» button per tab → `AyahStudyScreen`, no cramming, instant return to the mushaf?
8. Reused `DepthShadows` / `AppMotion` / `AppRadius`, no scattered numbers?
