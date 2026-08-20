# ADHKAR_AUDIO_SOURCES.md

License audit for Adhkar/Dua recitation audio — written 2026-08-16 after Ismail asked to apply the تحفيظ (listen/pause/repeat) pattern to Adhkar. Verified directly (`WebFetch`, not assumed) rather than trusting a pasted survey at face value.

## Verdict

**No fully-licensed, complete (298-item) Adhkar audio collection currently exists that this app can legally bundle or redistribute.** Every candidate source is either incomplete (doesn't cover Hisn al-Muslim's actual 298 items) or has an unclear/absent redistribution license. This is the same category of honest gap already documented for the original PDF book source and (until resolved) Quran Foundation audio — reported directly rather than worked around with an unverified source.

## Sources checked

| Source | Reciter/content | License | Commercial use | Redistribution | Verdict |
|---|---|---|---|---|---|
| Wikimedia Commons (Arabic audio files category) | Scattered individual recordings, not a Hisn al-Muslim set | CC0 where explicitly tagged per-file | Yes (CC0 items) | Yes (CC0 items) | 🟢 legally clean where it exists, but **doesn't cover the actual 298-item content need** — not a usable full collection |
| `abdurrahman.org/hisn-al-muslim` | Full Hisn al-Muslim MP3 set | **Verified directly**: site states only *"posted with implicit/explicit permission from content owners"* — no explicit redistribution grant for third-party apps | Unclear | Unclear/not granted | 🟡 do not use without written permission from the site/reciter |
| Archive.org copies of the same Hisn al-Muslim recording | Same content, mirrored | Hosting presence only, no explicit license found | Unclear | Unclear | 🟡 same status as above — a mirror doesn't create a license |
| SoundCloud (e.g. "Morning Adhkar") | Individual reciter uploads | All-rights-reserved (explicit, per platform) | No | No | 🔴 do not use |
| Bandcamp Hisnul Muslim album | Abu Bakr Ash-Shatri | Paid commercial album, no open license | No | No | 🔴 do not use |
| **House of Islam Developer API** (`api.thehouseofislam.com/dhikr`) | Dhikr endpoint, Basic (free) tier | Terms state *"provided free of charge, for personal and commercial use alike,"* attribution *"not required."* | Yes (explicit) | N/A — no audio to redistribute | 🔴 **resolved by direct testing 2026-08-17**: Ismail registered and shared a real API key; called the live `/dhikr` endpoint and inspected the actual response — every entry has `transliteration`/`english`/`arabic` text fields only, **no audio/mp3 field anywhere**. This is not an audio source. (Incidental find: it does give clean English transliteration+translation per dhikr, useful for a possible future multi-language Adhkar feature, unrelated to the audio question.) |

## Recommendation

**First, cheapest to check**: register for a House of Islam Developer API key (`developers.thehouseofislam.com`) and confirm directly whether the Dhikr/Dua endpoints actually include audio, and under what exact offline/redistribution terms — this is Ismail's action, not something resolvable from public docs alone, but it's a 5-minute signup rather than a negotiation.

**If that doesn't pan out**, the professional path — commissioning an original recording from one reciter with explicit written rights (app distribution, offline download, modification/encoding, Google Play/App Store, future platforms) — is the right long-term answer, matching how a licensed voice actor/reciter agreement would work for any real product. **This requires Ismail's own action** (finding and contracting a reciter) — not something this session can do. Once recordings exist, the target on-disk layout is ready to receive them:

```
adhkar_audio/
  {category_key}/
    {item_id}.mp3
```

matching the exact convention already used for Quran audio downloads (`quran_audio/{reciterId}/{surah}{ayah}.mp3`), so the download/caching code built for Quran (`QuranAudioDownloadService`'s pattern) is directly reusable once content exists.

## What's built now vs. deferred

Built (pure architecture, no content, zero licensing risk — see `lib/services/adhkar_audio/`):
- `AdhkarAudioProvider` abstraction, mirroring `QuranAudioProvider`
- A `LocalAdhkarAudioProvider` that reads from the `adhkar_audio/` folder convention above if files are ever placed there — currently `isConfigured` returns `false` (no default source), same "present but inert" pattern as `QuranFoundationProvider`

Deferred until real, licensed content exists:
- The actual playback engine/UI (listen → pause → repeat → next dhikr) — building this against zero real audio would be shipping something impossible to verify
- The 4 pedagogical modes (استمع فقط / استمع وكرر / حفظ / اختبار) suggested in the reference message — scoped down to just "استمع وكرر" (the one already proven valuable for Quran) whenever this is picked back up; the memorize/test modes are a separate, later decision
