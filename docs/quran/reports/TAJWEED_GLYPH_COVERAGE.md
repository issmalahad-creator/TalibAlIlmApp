# Tajwīd glyph-colouring coverage — v1 (Phase G-t v2)

**Glyph-level Tajwīd rendering.** The colour is injected on the
exact `<path>` of a glyph. MushafDatabase draws 2–10-letter
ligatures as one `<path>` and has no per-letter path, so v1
colours only what it can colour **precisely** — every covered
diacritic (wasla, shadda, maddah, superscript-alef, tanwīn,
sukūn…) and every single-letter ligature. The `[cs, ce)` span
data stays codepoint-exact.

- rule spans on the page art: **70085**
- **DIRECT** — colour on the exact glyph path: **55804**  (79.6%)
- **BAND** — المدّ only: a clip-path x-slice at the madd letter's position inside a whole-word ligature (never the whole word): **3843**  (5.5%)
- **SKIPPED** — non-madd rule inside a whole-word ligature with no anchor; black on the page, shown in the knowledge surface + on tap: **10438**  (14.9%)

True per-letter colouring for the skipped spans needs a
different art source / an in-app Arabic-shaping renderer (v3).

## Per rule

| rule | direct | band | skipped |
|---|---|---|---|
| `hamzat_wasl` | 12207 | 0 | 1045 |
| `madd_2` | 7141 | 54 | 1833 |
| `ikhfa` | 6190 | 0 | 2352 |
| `idghaam_ghunnah` | 5690 | 0 | 2176 |
| `ghunnah` | 4825 | 0 | 121 |
| `madd_246` | 770 | 3773 | 0 |
| `silent` | 3962 | 0 | 212 |
| `qalqalah` | 3487 | 0 | 347 |
| `madd_munfasil` | 2829 | 0 | 343 |
| `lam_shamsiyyah` | 2703 | 0 | 30 |
| `idghaam_no_ghunnah` | 1470 | 0 | 600 |
| `madd_muttasil` | 1997 | 0 | 0 |
| `idghaam_shafawi` | 836 | 0 | 828 |
| `iqlab` | 1051 | 0 | 2 |
| `ikhfa_shafawi` | 499 | 0 | 493 |
| `madd_6` | 132 | 16 | 0 |
| `idghaam_mutajanisayn` | 15 | 0 | 43 |
| `idghaam_mutaqaribayn` | 0 | 0 | 13 |

## Skipped examples (30)

These rules land inside a whole-word ligature with no mark to
anchor to — not coloured on the page in v1:

- 2:3 w3 — «بِٱلۡغَيۡبِ» (hamzat_wasl)
- 2:3 w6 — «ٱلصَّلَوٰةَ» (silent)
- 2:4 w10 — «مِن» (ikhfa)
- 2:4 w13 — «بِٱلۡأٓخِرَةِ» (hamzat_wasl)
- 2:5 w4 — «مِّن» (idghaam_no_ghunnah)
- 2:8 w4 — «مَن» (idghaam_ghunnah)
- 2:8 w7 — «بِٱللَّهِ» (hamzat_wasl)
- 2:8 w9 — «بِٱلۡيَوۡمِ» (hamzat_wasl)
- 2:8 w13 — «هُم» (ikhfa_shafawi)
- 2:10 w2 — «قُلُوبِهِم» (idghaam_shafawi)
- 2:12 w6 — «لَٰكِن» (idghaam_no_ghunnah)
- 2:13 w20 — «لَٰكِن» (idghaam_no_ghunnah)
- 2:16 w5 — «بِٱلۡهُدَىٰ» (hamzat_wasl)
- 2:17 w16 — «ظُلُمَٰتٖ» (idghaam_no_ghunnah)
- 2:18 w3 — «عُمۡيٞ» (ikhfa)
- 2:19 w2 — «كَصَيِّبٖ» (idghaam_ghunnah)
- 2:19 w6 — «ظُلُمَٰتٞ» (idghaam_ghunnah)
- 2:19 w8 — «رَعۡدٞ» (idghaam_ghunnah)
- 2:19 w14 — «ءَاذَانِهِم» (idghaam_shafawi)
- 2:19 w23 — «بِٱلۡكَٰفِرِينَ» (hamzat_wasl)
- 2:20 w8 — «لَهُم» (idghaam_shafawi)
- 2:25 w10 — «جَنَّٰتٖ» (ikhfa)
- 2:25 w12 — «مِن» (ikhfa)
- 2:25 w19 — «مِن» (ikhfa)
- 2:25 w26 — «مِن» (ikhfa)
- 2:25 w32 — «مُتَشَٰبِهٗا» (idghaam_ghunnah)
- 2:26 w8 — «مَثَلٗا» (idghaam_ghunnah)
- 2:26 w10 — «بَعُوضَةٗ» (ikhfa)
- 2:26 w20 — «مِن» (idghaam_no_ghunnah)
- 2:30 w7 — «جَاعِلٞ» (ikhfa)
