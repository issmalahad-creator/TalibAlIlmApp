---
name: cloud-test-and-preview
description: >-
  Load at the start of any TalibAlIlmApp session that runs in a Linux cloud
  container (no emulator, no Windows toolchain) and needs to analyze, test,
  or SEE a UI change. Carries the exact Flutter version, the gitignored files
  the build expects and how to stand them in, the 6 tests that always fail
  here (environment, not code), and the technique that renders real
  screenshots of real screens (real fonts, real mushaf art, seeded DB) from a
  widget test — so a change is checked visually before Ismail's phone.
---

# Cloud test & preview — TalibAlIlmApp

Learned 2026-10-10 (reader R1). Read this instead of rediscovering it.

## 1. Toolchain (≈2 min, once per container)

`pubspec.lock` needs Dart 3.12.2 / Flutter ≥ 3.44 → **Flutter 3.44.9**:

```bash
mkdir -p /root/sdk && cd /root/sdk && curl -sS https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.9-stable.tar.xz | tar -xJ
git config --global --add safe.directory /root/sdk/flutter
cd <repo> && /root/sdk/flutter/bin/flutter pub get
```

`storage.googleapis.com` and `pub.dev` are reachable; **`api.turath.io` is
blocked** by the environment's network policy (so `tool/build_usul_tree.py`
can't run here — it fetches the Muqaddima; Ismail must allow the host).

## 2. Gitignored files the build needs — stand-ins, then remove

```bash
cp lib/config/app_config.example.dart lib/config/app_config.dart
mkdir -p assets/tts/packs assets/tts/espeak-ng-data/lang/sem
touch assets/tts/packs/.keep assets/tts/ar_JO-kareem-medium.onnx.json assets/tts/tokens.txt
for f in ar_dict intonations phondata phondata-manifest phonindex phontab lang/sem/ar; do touch assets/tts/espeak-ng-data/$f; done
```

All are gitignored (never staged). Delete them before finishing:
`rm -rf assets/tts lib/config/app_config.dart`.

## 3. Analyze / test

- `flutter analyze` — the only errors on a clean tree come from the missing
  real `app_config.dart` / TTS assets. Filter: `| grep "•" | grep -v "AppConfig\|app_config\|asset_does_not_exist"`.
- `flutter test` ≈ 6 min. **Baseline here: everything passes except 6**
  that need the network or a real Supabase config:
  `mosque_repository_test.dart` (2) and `turath_api_client_test.dart` (live, 4).
  Anything else red is real.
- **The suite rewrites 3 generated reports** — always
  `git checkout docs/quran/reports` after a run.
- **Never `dart format` a whole existing file** — most aren't formatter-clean;
  it turns a 30-line change into a 1,400-line diff. Format only new files.

## 4. See the UI without a phone — rendered screenshots

`preview_template.dart.txt` (this folder) is a working widget test that
renders `MushafSemanticReaderScreen` to PNG. Copy it into `test/zz_*.dart`,
run, look, then **move it out of `test/` before the full suite / commit**.

What makes it render for real (each one cost a failed attempt):
- **DB**: `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` + a
  throwaway `DatabaseHelper.databaseName`, then
  `MushafLayoutSync().ingestFromJson(<assets/mushaf/mushaf_layout.json.gz>)`.
- **Fonts**: tests draw boxes unless loaded: `FontLoader` for `Amiri`,
  `AmiriQuran` (assets/fonts) and `MaterialIcons`
  (`/root/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf`);
  `ThemeData(fontFamily: 'Amiri')`; wrap in RTL `Directionality`.
- **Prefs**: `SharedPreferences.setMockInitialValues({...})` sets the state
  to show (`mushaf_last_page`, `mushaf_view_vertical`, `mushaf_paper_tone`…).
- **Real async + animations**: SVG decode and DB run in isolates → alternate
  `t.runAsync(() => Future.delayed(250ms))` with `t.pump(150ms)` (a bare
  `pump()` doesn't advance the animation clock — sheets never open).
- **Audio plugin**: `audioplayers` throws `MissingPluginException`; mock
  `xyz.luan/audioplayers(.global)` method channels. The per-player event
  channel still logs and marks the test failed — the PNGs are still valid.
- **Capture**: wrap the app in a `RepaintBoundary`, `toImage(pixelRatio: 1.5)`
  inside `runAsync`, write PNG to the scratchpad; view with Read; combine with
  PIL to send one image to Ismail.
- Gestures: `t.startGesture` ×2 + `moveTo` = pinch; `t.fling(PageView)` = page
  turn; `t.longPressAt` = ayah menu.

## 5. Measuring the mushaf art (python)

`pip install svgelements`; `Group.union_bbox(shapes)` of a group's shapes
gives real ink bounds (`Group.bbox()` alone returns None). Page structure:
`md-page-outer` (headers, page number, margin hizb) then `md-page-inner` →
`md-line-01..15`. Pages 1–2 are the decorated opening (no headers).
