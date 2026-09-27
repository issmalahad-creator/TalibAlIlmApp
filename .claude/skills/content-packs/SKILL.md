---
name: content-packs
description: Ship heavy/optional content (tafsir, translations, corpus datasets, books, voices, lesson media) as downloadable content packs on GitHub Releases instead of inside the APK — publish with tool/publish_packs.py, install via ContentPackEngine + a PackInstaller, show the pro download UI. Use whenever a feature adds data over ~200 KB, or asks "should this be bundled?", or touches downloads, the «التنزيلات والمساحة» screen, or the lite build.
---

# Content packs — «التطبيق خفيف، والمحتوى يأتي عند الحاجة»

Design reference: `docs/architecture/CONTENT_PACKS_ARCHITECTURE.md`. Size rules:
skill `lightweight-feature-rules` §3. This skill is the **how**.

## 1. Decide: bundle or pack?

| Data | Where |
|---|---|
| < ~200 KB, needed on day one offline | bundled asset |
| Core Quran text + mushaf art | bundled in both flavors |
| Everything heavy or optional (tafsir, translations, corpus datasets, books, voices, audio lessons) | **content pack** — bundled in `full`, downloaded in `lite` |
| PDFs / scans / anything not already public in this repo | **never** (repo + releases are public) |

A feature asks `ContentPackEngine.instance.isUsable('<id>')` — **never** "am I lite?".

## 2. Add a new pack — the 6 steps

1. **Put the file in a pack folder**, one line in `pubspec.yaml` for the folder
   (never list pack files one by one — the lite build strips whole folders):
   `assets/quran/corpus/packs/`, `assets/quran/tafsir_packs/`, or a new
   `assets/<area>/packs/`. A new folder → add it to `LITE_STRIP` in
   `tool/build_apk.py` **and** `STRIP_DIRS` in `tool/build_lite_apk.sh`.
2. **Declare it** in `tool/publish_packs.py` `candidates()`: stable dotted id
   (`<kind>.<name>`), `kind` (tafsir · translation · corpus · voice · …),
   titles/summary in `ar` + `en` at least, `installer` name.
3. **Write the installer** in `lib/services/packs/pack_installers.dart`
   (`PackInstaller`): `isBundled` (read `AssetManifest`, never load the
   file), `install(pack, files)` (seed the SAME tables/paths the bundled
   asset fills — consumers must not change), `uninstall` (delete exactly
   that). Register it in `registerPackInstallers()`.
4. **Make boot skip it when absent**: boot sync/import must `continue` when
   the asset isn't bundled (see `QuranCorpusSync.packDatasets`,
   `QuranImportService._assetBundled`) — never throw, never block.
5. **Publish**: `python tool/publish_packs.py` (dry run, compares with what
   is really on GitHub) → `python tool/publish_packs.py --publish`. Changed
   bytes = new version + new file name automatically; published files are
   never replaced. Commit the updated `assets/packs/packs_manifest.json`.
6. **UI**: where the content is missing, show `PackStatusView(pack: …)`
   (download button with size → sheet → live progress → content). Never an
   empty panel, never "no data" for "not downloaded".

## 3. Engine rules (don't re-invent)

- Downloads go through `ContentPackEngine` → `PackDownloader`: `.part` +
  `Range` resume, SHA-256 before an atomic rename, one at a time, queue
  persisted, Wi-Fi-only waiting, never throws (every failure is a
  `PackFailed(reason)` with a translated sentence).
- The question is `askDownloadSheet` / `showPackDownloadSheet`: book name +
  author, size, current network (mobile data shows the MB cost), "works
  offline after". Never a bare `AlertDialog`.
- Only from a screen the user opened. Resume of a queued download at boot is
  the one exception: `BootTasks.contentPacks`, `afterHome`, Wi-Fi only.
- Strings via `basicText()` in 13 languages (`pk_*`, `downloads_*`,
  `group_<kind>` — a new kind needs its `group_<kind>` key and a place in
  `DownloadsScreen._groups`).

## 4. Verify — every time

- `flutter test test/content_pack_engine_test.dart` + the feature's tests.
- `python tool/build_apk.py --flavor lite --abi arm64-v8a` — the build
  **fails if a stripped file leaks into the APK**; note the MB delta.
- If a build is interrupted: `python -c "import sys; sys.path.insert(0,'tool'); import build_apk; build_apk.restore_lite_backup()"`
  then `git status` must show no `D assets/...`.
- On the phone (lite): the feature shows the download button with the right
  size → sheet → progress (pause/resume) → content appears in place; delete
  from «التنزيلات والمساحة» frees the space and the button returns.

## 5. Red flags

- A pack file listed individually in `pubspec.yaml`.
- `if (isLite)` anywhere in feature code.
- Loading a multi-MB asset just to check it exists.
- An installer that writes to a different table than the bundled path uses.
- Re-uploading a changed file under the same name.
- Publishing anything whose licence isn't recorded in `QURAN_SOURCES_AND_LICENSES.md`.
