---
name: device-testing-adb
description: >-
  Load before verifying a Flutter change on the Android emulator/device for
  TalibAlIlmApp — building a debug APK, installing, launching, screenshotting,
  or driving the UI with `adb shell input`. Carries this machine's toolchain
  paths, the Git-Bash/binary pitfalls, screenshot coordinate scaling, and the
  known limits (adb can't type Arabic; emulator is flaky).
---

# Device / emulator testing on this machine

## Toolchain

```bash
export PATH="/c/src/flutter/bin:$PATH"
export ANDROID_HOME="C:\Users\ismail\AppData\Local\Android\Sdk"
ADB="$ANDROID_HOME/platform-tools/adb.exe"
```

- App id: `com.sunnahinstitute.talib_alilm`, activity `.MainActivity`.
- `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`
  (universal, works anywhere). `--split-per-abi` also emits
  `app-arm64-v8a-debug.apk` (Ismail's phone), `app-x86_64-debug.apk`
  (emulator), `app-armeabi-v7a-debug.apk`.
- Debug builds for testing; **release only when Ismail asks**.
- With the 604 bundled mushaf SVGs the APK is ~275–330 MB — builds take
  ~30–80 s, installs take a while. Normal.

## Run + screenshot

```bash
"$ADB" install -r build/app/outputs/flutter-apk/app-x86_64-debug.apk
"$ADB" shell am force-stop com.sunnahinstitute.talib_alilm
"$ADB" shell am start -n com.sunnahinstitute.talib_alilm/.MainActivity
# wait ~10-13 s for first frame, then:
"$ADB" exec-out screencap -p > "$SCRATCH/shot.png"
```

Put screenshots/scripts in the scratchpad dir (from the system prompt), not
`/tmp` — Git Bash on Windows mangles `/tmp` paths and binary redirects.

## Driving the UI

- `"$ADB" shell input tap X Y` — X,Y are **device** pixels (this emulator is
  1080×2400). The Read tool shows screenshots scaled to 900 wide and prints
  "Multiply coordinates by 1.20" — so `device = display × 1.20`.
- `"$ADB" shell input swipe X1 Y1 X2 Y2 MS`, `input keyevent KEYCODE_...`.
- **`adb shell input text` cannot type Arabic** on this Android — it throws
  NullPointerException. To test Arabic search / text entry you need Ismail
  on his real device, or paste via a different method. Do not claim an
  Arabic-input bug is reproduced/fixed from the emulator.
- Bottom-sheet/menu row positions shift between runs (DraggableScrollableSheet
  animation) — screenshot after each tap, don't chain blind taps.

## Emulator flakiness

The `Medium_Phone_API_35` AVD segfaults / fails to appear as a device
fairly often in this environment. If `adb devices` stays empty after ~3 min:
`adb kill-server`, `Stop-Process qemu-system-x86_64,emulator -Force`, retry
with `emulator -avd Medium_Phone_API_35 -no-snapshot -no-boot-anim -no-audio
-gpu host`. If it still won't come up, fall back to `flutter analyze` +
`flutter test` + APK build and hand the APK to Ismail to test on his phone
(the normal flow — "اجرب في هاتفي").

## `testWidgets` + sqflite_ffi = wrap DB calls in `runAsync`

`sqflite_common_ffi` uses real timers/isolate. Under the `testWidgets`
fake-async binding a bare `await db.query(...)` (in the test body OR reached
from a pumped widget's `initState`) **never completes → the whole test
hangs to the 10-min timeout**. Fixes: (1) do repo/sync setup in `setUpAll`
(real async); (2) in a `testWidgets` body wrap any direct DB call in
`await tester.runAsync(() async { … })`; (3) for a screen that queries in
`initState`, settle with an interleaved loop —
`for (…) { await tester.runAsync(() => Future.delayed(80ms)); await tester.pump(); }`
(~40 iters) — never `pumpAndSettle` (a spinner/AnimatedCrossFade makes it
spin forever). Pattern: `test/corpus_panels_test.dart`, `test/topic_index_test.dart`.

## Verification bar (Ismail's standing rule for Quran work)

`flutter test` passing is **not** proof the UX works. For a
hit-test/interaction change, verify on a real page (not just page 1): tap
words at line start / middle / end, near page top/bottom, on tashkeel'd and
long words, and confirm the resolved `(surah, ayah, word_index)` is exactly
right. Known pre-existing test failure: `test/widget_test.dart` "App
launches without throwing" (`databaseFactory not initialized`) — unrelated,
ignore it in pass/fail counts.
