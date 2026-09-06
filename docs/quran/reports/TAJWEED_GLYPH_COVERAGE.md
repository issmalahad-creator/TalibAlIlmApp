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
- **SKIPPED** — rule lands only inside a multi-letter ligature
  with no diacritic anchor; stays black on the page, shown in
  the knowledge surface + on tap: **14281**  (20.4%)

True per-letter colouring on the remaining spans needs a
different art source / an in-app Arabic-shaping renderer (v3).

## Per rule

| rule | direct | skipped | direct % |
|---|---|---|---|
| `hamzat_wasl` | 12207 | 1045 | 92% |
| `madd_2` | 7141 | 1887 | 79% |
| `ikhfa` | 6190 | 2352 | 72% |
| `idghaam_ghunnah` | 5690 | 2176 | 72% |
| `ghunnah` | 4825 | 121 | 98% |
| `madd_246` | 770 | 3773 | 17% |
| `silent` | 3962 | 212 | 95% |
| `qalqalah` | 3487 | 347 | 91% |
| `madd_munfasil` | 2829 | 343 | 89% |
| `lam_shamsiyyah` | 2703 | 30 | 99% |
| `idghaam_no_ghunnah` | 1470 | 600 | 71% |
| `madd_muttasil` | 1997 | 0 | 100% |
| `idghaam_shafawi` | 836 | 828 | 50% |
| `iqlab` | 1051 | 2 | 100% |
| `ikhfa_shafawi` | 499 | 493 | 50% |
| `madd_6` | 132 | 16 | 89% |
| `idghaam_mutajanisayn` | 15 | 43 | 26% |
| `idghaam_mutaqaribayn` | 0 | 13 | 0% |

## Skipped examples (30)

These rules land inside a whole-word ligature with no mark to
anchor to — not coloured on the page in v1:

- 1:1 w3 — «ٱلرَّحۡمَٰنِ» (madd_2)
- 1:1 w4 — «ٱلرَّحِيمِ» (madd_246)
- 1:2 w4 — «ٱلۡعَٰلَمِينَ» (madd_246)
- 1:3 w2 — «ٱلرَّحِيمِ» (madd_246)
- 1:4 w3 — «ٱلدِّينِ» (madd_246)
- 1:5 w5 — «نَسۡتَعِينُ» (madd_246)
- 1:6 w2 — «ٱلصِّرَٰطَ» (madd_2)
- 1:6 w3 — «ٱلۡمُسۡتَقِيمَ» (madd_246)
- 2:1 w1 — «الٓمٓ» (madd_6)
- 2:2 w9 — «لِّلۡمُتَّقِينَ» (madd_246)
- 2:3 w3 — «بِٱلۡغَيۡبِ» (hamzat_wasl)
- 2:3 w6 — «ٱلصَّلَوٰةَ» (silent)
- 2:3 w10 — «يُنفِقُونَ» (madd_246)
- 2:4 w10 — «مِن» (ikhfa)
- 2:4 w13 — «بِٱلۡأٓخِرَةِ» (hamzat_wasl)
- 2:4 w15 — «يُوقِنُونَ» (madd_246)
- 2:6 w11 — «يُؤۡمِنُونَ» (madd_246)
- 2:7 w17 — «عَظِيمٞ» (madd_246)
- 2:8 w4 — «مَن» (idghaam_ghunnah)
- 2:8 w7 — «بِٱللَّهِ» (hamzat_wasl)
- 2:8 w9 — «بِٱلۡيَوۡمِ» (hamzat_wasl)
- 2:8 w13 — «هُم» (ikhfa_shafawi)
- 2:8 w14 — «بِمُؤۡمِنِينَ» (madd_246)
- 2:10 w2 — «قُلُوبِهِم» (idghaam_shafawi)
- 2:17 w9 — «حَوۡلَهُۥ» (madd_2)
- 2:17 w16 — «ظُلُمَٰتٖ» (idghaam_no_ghunnah)
- 2:18 w3 — «عُمۡيٞ» (ikhfa)
- 2:18 w6 — «يَرۡجِعُونَ» (madd_246)
- 2:19 w2 — «كَصَيِّبٖ» (idghaam_ghunnah)
- 2:19 w6 — «ظُلُمَٰتٞ» (idghaam_ghunnah)
