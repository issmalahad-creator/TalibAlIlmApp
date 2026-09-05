# Tajwīd glyph-colouring coverage — v1 (Phase G-t v2)

**Glyph-level Tajwīd rendering with documented ligature fallback.**
The `[cs, ce)` rule spans (`quran_tajweed`) stay codepoint-exact;
this measures how the *renderer* places the colour on MushafDatabase
art, which draws 2–10-letter ligatures as one `<path>`.

- rule spans on the page art: **67846** placed (+ 2239 skipped)
- **DIRECT** (colour on the exact diacritic / single-letter glyph path): **55804**  (82.3%)
- **BAND** (clip-path x-slice inside a multi-letter ligature — never the whole path): **12042**  (17.7%)
- **SKIPPED** on the page (shown in the knowledge surface + on tap): **2239**

## Per rule

| rule | direct | band | skipped |
|---|---|---|---|
| `hamzat_wasl` | 12207 | 1045 | 0 |
| `ikhfa` | 6190 | 2346 | 6 |
| `idghaam_ghunnah` | 5690 | 2169 | 7 |
| `madd_2` | 7141 | 54 | 1833 |
| `ghunnah` | 4825 | 113 | 8 |
| `madd_246` | 770 | 3773 | 0 |
| `silent` | 3962 | 182 | 30 |
| `qalqalah` | 3487 | 340 | 7 |
| `madd_munfasil` | 2829 | 0 | 343 |
| `lam_shamsiyyah` | 2703 | 30 | 0 |
| `idghaam_no_ghunnah` | 1470 | 599 | 1 |
| `madd_muttasil` | 1997 | 0 | 0 |
| `idghaam_shafawi` | 836 | 826 | 2 |
| `iqlab` | 1051 | 1 | 1 |
| `ikhfa_shafawi` | 499 | 493 | 0 |
| `madd_6` | 132 | 16 | 0 |
| `idghaam_mutajanisayn` | 15 | 42 | 1 |
| `idghaam_mutaqaribayn` | 0 | 13 | 0 |

## Band examples (30)

The colour is clipped to an x-slice of these word-ligatures — a region of the word, never the whole word:

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
- 2:17 w16 — «ظُلُمَٰتٖ» (idghaam_no_ghunnah)
- 2:18 w3 — «عُمۡيٞ» (ikhfa)
- 2:18 w6 — «يَرۡجِعُونَ» (madd_246)
- 2:19 w2 — «كَصَيِّبٖ» (idghaam_ghunnah)
- 2:19 w6 — «ظُلُمَٰتٞ» (idghaam_ghunnah)
- 2:19 w8 — «رَعۡدٞ» (idghaam_ghunnah)
