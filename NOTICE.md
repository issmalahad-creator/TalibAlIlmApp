# NOTICE — data licensing (separate from the code license)

The `LICENSE` file in this repository covers the **application source
code** only (Dart/Flutter code, build scripts, tooling, and original
documentation). It does **not** cover the Quran-related data bundled with
or downloaded by the app. That data comes from third-party sources, each
under its own license, and those licenses remain in force regardless of
how the application code itself is licensed.

## Quran text, mushaf layout, morphology, tajwīd

Full source-by-source detail (URL, version, exact license terms, what may
and may not be assumed) is maintained in **`docs/quran/SOURCES.md`** and
**`docs/QURAN_SOURCES_AND_LICENSES.md`** — treat those files, not this one,
as the authoritative record. Key points:

- **Tanzil** Quran text — Tanzil's own terms (verbatim copies, no
  modification of the text itself, source attribution).
- **MushafDatabase** (mushaf page layout/art, V1.01) — released by its
  author as *ṣadaqah jāriyah*; bundled as-is, unmodified, with credit.
- **Quranic Arabic Corpus (QAC)** morphology/syntax — copy and distribute
  **verbatim** only, **no modification**, must credit "Quranic Arabic
  Corpus" with a link to https://corpus.quran.com. Effectively GPL-like:
  study/reference use, not a basis for a relicensed derivative.
- **MASAQ** (morphology/syntax v5) — CC BY 4.0: share, adapt, and
  commercial use all permitted, with attribution to Sawalha et al. (2024).
- **cpfair/quran-tajweed** (tajwīd rule spans) — CC BY 4.0, attribution
  required.

## Tafsir and translations (Quranpedia dumps)

The tafsir and translation editions distributed via this project's GitHub
Releases (for the app's on-demand "download once, cache forever" feature)
are sourced from Quranpedia dumps. Quranpedia's general license permits
free in-app use, and specifically requires **attribution plus the dump
version** whenever the dataset is **re-published as a downloadable
database** — exactly what a GitHub Release is. That attribution +
dump-version record is included alongside the released files themselves
(see the Release notes / an accompanying `SOURCES.json` in the release
assets).

**Translations are a stricter case**: each translation's text is the
intellectual property of its individual author/publisher, separate from
Quranpedia's general tafsir/corpus license. Before any public
redistribution, every bundled translation and tafsir edition was reviewed
individually for redistribution risk. As a result, the following editions
are **excluded** from the public GitHub Release (they remain usable
in-app only where already bundled, never re-published standalone):

- Dr. Mustafa Khattab — *The Clear Quran* (both edition IDs)
- Mufti Muhammad Taqi Usmani's translation
- Abul Ala Maududi's translation-with-tafsir edition
- Adil Salahi's translation
- Al-Sha'rawi's tafsir

All other bundled translations and tafsir editions are included in the
public Release, each carrying its own author/publisher attribution as
shown in-app and in the Release's source manifest.

## What this means for reuse

If you fork or redistribute this project:

- The **code** may be reused under `LICENSE` (see its terms, including the
  ṣadaqah jāriyah attribution requirement).
- The **data** — text, layout, morphology, tajwīd, tafsir, translations —
  must be re-cleared against its own original source and license before
  you redistribute it further. Do not assume the code license extends to
  it, and do not re-add the 5 excluded editions above to any public,
  redistributable release without independently securing rights to do so.
