# LICENSED_CONTENT_SOURCES.md

Sources of religious content confirmed to carry an explicit, direct, written permission from the original author/rights-holder — verified directly (`WebFetch` of the primary source itself), not inferred or taken from a third-party summary. Separate from `ADHKAR_AUDIO_SOURCES.md`, which tracks the still-unresolved Hisn al-Muslim audio search specifically.

## Why this file exists

Ismail's 2026-08-17 question ("هندسة معمارية أنفع فيه الناس لـ50 سنة القادمة، مجانية") plus the Al-Nabulsi example (a scholar who declared his work free, only to have intermediary platforms restrict/monetize it downstream — "خربوا عليه نيته") establishes a durability principle for this app: content is only safely free-forever when the permission comes from the **primary source itself**, is **explicit and dated**, and is **documented here** so it can be re-verified years later without redoing the research.

## Confirmed sources

| Source | Author | Content type | License statement | Verified | Conditions |
|---|---|---|---|---|---|
| [nabulsi.com/web/article/14329](https://nabulsi.com/web/article/14329) | Dr. Muhammad Ratib Al-Nabulsi | Lectures, tafsir, fiqh (audio + text) — **not** Hisn al-Muslim adhkar recitation | *"حقوق الطبع غير محفوظة، خذ ما شئت وانشر ما شئت"* ("Copyright is not reserved. Take what you wish and publish what you wish.") | ✅ Verified directly via `WebFetch` of the primary source, 2026-08-17 | None on attribution, alteration, or commercial use. Only exception: he will act against content falsely attributed to him that contradicts his actual teachings. |
| [commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg](https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg) | Adam-synagda (uploader, listed as "own work") | Adhan (call-to-prayer) audio recording | CC0 1.0 Universal — Public Domain Dedication ([creativecommons.org/publicdomain/zero/1.0](https://creativecommons.org/publicdomain/zero/1.0/)): *"waiving all of their rights to the work worldwide under copyright law... permitting anyone to copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission."* | ✅ Verified directly via `WebFetch` of the Commons file page, 2026-08-17. File downloaded, size confirmed byte-for-byte against the page's listed size (1,229,032 bytes) before bundling. | None whatsoever — CC0 requires no attribution, permits modification, permits commercial use, permits redistribution. Direct source file URL: `https://upload.wikimedia.org/wikipedia/commons/b/b0/Beautiful_adhan.ogg`. Format: Ogg Vorbis, stereo, 44100 Hz, ~2:34. Bundled as `assets/audio/adhan_beautiful.ogg` (in-app preview playback) and `android/app/src/main/res/raw/adhan_beautiful.ogg` (Android notification-channel sound — required native-resource path, a Flutter asset alone can't serve as a notification sound). |

## Not yet resolved

- Does nabulsi.com (or another official channel) offer these lectures as **downloadable audio files**, and in what format/size? Not yet checked — needed before this can feed an actual in-app audio library.
- This does not solve the Hisn al-Muslim Adhkar audio gap (`ADHKAR_AUDIO_SOURCES.md`) — Al-Nabulsi is a lecturer, not a reciter of that specific text.

## Durability principles this file exists to enforce

1. **Primary source over intermediary** — a license only counts here if it comes from the rights-holder's own site/statement, not a third-party mirror or app that merely hosts the content.
2. **Local-first, no server dependency** — once downloaded, content must keep working even if the original site disappears years later.
3. **Documented provenance** — every entry here is re-verifiable: exact URL, exact quote, exact date checked.
4. **Swappable providers, never a single point of failure** — matches the existing `AudioProvider`/`QuranAudioProvider` abstraction pattern; no feature should hard-depend on one source staying online forever.
