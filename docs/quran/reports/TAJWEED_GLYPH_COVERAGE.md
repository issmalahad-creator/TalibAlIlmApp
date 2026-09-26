# Tajwīd glyph-colouring coverage — v1 (Phase G-t v2)

**Glyph-level Tajwīd rendering.** The colour is injected on the
exact `<path>` of a glyph. MushafDatabase draws 2–10-letter
ligatures as one `<path>` and has no per-letter path, so v1
colours only what it can colour **precisely** — every covered
diacritic (wasla, shadda, maddah, superscript-alef, tanwīn,
sukūn…) and every single-letter ligature. The `[cs, ce)` span
data stays codepoint-exact.

- rule spans on the page art: **70085**
- **DIRECT** — colour on the exact glyph path: **0**  (0.0%)
- **BAND** — المدّ only: a clip-path x-slice at the madd letter's position inside a whole-word ligature (never the whole word): **0**  (0.0%)
- **SKIPPED** — non-madd rule inside a whole-word ligature with no anchor; black on the page, shown in the knowledge surface + on tap: **70085**  (100.0%)

True per-letter colouring for the skipped spans needs a
different art source / an in-app Arabic-shaping renderer (v3).

## Per rule

| rule | direct | band | skipped |
|---|---|---|---|
| `hamzat_wasl` | 0 | 0 | 13252 |
| `madd_2` | 0 | 0 | 9028 |
| `ikhfa` | 0 | 0 | 8542 |
| `idghaam_ghunnah` | 0 | 0 | 7866 |
| `ghunnah` | 0 | 0 | 4946 |
| `madd_246` | 0 | 0 | 4543 |
| `silent` | 0 | 0 | 4174 |
| `qalqalah` | 0 | 0 | 3834 |
| `madd_munfasil` | 0 | 0 | 3172 |
| `lam_shamsiyyah` | 0 | 0 | 2733 |
| `idghaam_no_ghunnah` | 0 | 0 | 2070 |
| `madd_muttasil` | 0 | 0 | 1997 |
| `idghaam_shafawi` | 0 | 0 | 1664 |
| `iqlab` | 0 | 0 | 1053 |
| `ikhfa_shafawi` | 0 | 0 | 992 |
| `madd_6` | 0 | 0 | 148 |
| `idghaam_mutajanisayn` | 0 | 0 | 58 |
| `idghaam_mutaqaribayn` | 0 | 0 | 13 |

## Skipped examples (0)

These rules land inside a whole-word ligature with no mark to
anchor to — not coloured on the page in v1:

