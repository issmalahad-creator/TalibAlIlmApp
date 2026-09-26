---
name: database-migrations
description: >-
  Load before touching lib/db/database_helper.dart's schema (adding/changing a table
  or column, bumping the DB version) or before re-enabling any commented-out PRAGMA in
  it. Narrow, focused skill — the other TalibAlIlmApp skills (quran-engineering,
  quran-memory-engine, etc.) cover the domain logic; this one covers the raw SQLite
  schema-chain mechanics and one specific real incident, which none of them document.
---

# Raw SQLite schema chain — database_helper.dart

`lib/db/database_helper.dart` (~2,500 lines) is a singleton
(`DatabaseHelper.instance`) using plain `sqflite`/`sqflite_common_ffi`, no ORM,
`openDatabase(..., version: 67, onCreate:, onUpgrade:)` as of the last audit
(2026-09-17) — check the actual current `version:` before assuming 67 is still current.

## Adding a schema change

- `onCreate` replays every `_createV1Tables()` ... `_createVN Tables()` function in
  order for a fresh install — a new table needs its own `_createVN Tables()` added to
  that replay list, not just written once and forgotten.
- `onUpgrade` is a long if-cascade applying each version's diff to an EXISTING
  database. A new column on an existing table needs its own `if (oldVersion < N)`
  branch here, additive only (new nullable column, or a column with a safe default) —
  don't assume every real installed database is starting from v1; some users are
  mid-chain.
- Bump the `version:` argument to `openDatabase` when you add a new upgrade step, or
  it will never run on an upgrade.

## The disabled WAL PRAGMA — do not re-enable without real-device testing first

There is a commented-out `onConfigure` block near the top of the file (Arabic comment)
that would set `PRAGMA journal_mode=WAL`. It's disabled because enabling it **hung the
home screen on Ismail's real device** — found via actual on-device testing, not
theoretical. If WAL mode is ever needed again (e.g. for a concurrency reason), it must
be re-verified on a real device before shipping, not just in the emulator — see the
`device-testing-adb` skill for how to actually do that test.

## Known, currently-open, un-fixed related bug

Quran search returns zero results for some common words (e.g. "الظالمون") — prime
suspect is `lib/utils/arabic_normalize.dart`'s `normalizeArabicForSearch`, used by
`quran_search_repository.dart`'s `rawQuery` calls against a `text_normalized` column.
If you're touching search or normalization code, check `TODO.md`'s Known Issues section
for the current state of this before assuming it's fixed or unrelated to your change.

## Test harness gotcha

`test/widget_test.dart` and the wider suite use `sqflite_common_ffi` with manual
`sqfliteFfiInit()` + full plugin-channel mocking — this is a different DB engine path
than production `sqflite`. One test failure in this file is a long-standing, understood
test-harness limitation (not a real app bug) — see the `device-testing-adb` skill's
"Verification bar" section and don't spend time re-diagnosing it from scratch.
