#!/usr/bin/env bash
# Builds the "lite" APK flavor — everything except the Quran corpus text
# (translations/tafsir, ~330 MB) that `QuranCorpusDownloadService` fetches
# from the corpus-v1 GitHub Release on first use instead. Gradle flavors
# (android/app/build.gradle.kts) only control applicationId/label; they
# don't touch the Flutter asset bundle, so this script physically moves
# the corpus directories out of `assets/` before the build and restores
# them afterward — the same asset tree the "full" build ships unchanged.
#
# Usage: tool/build_lite_apk.sh [--release|--debug]  (default: --release)
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:---release}"
# The Piper TTS voice model + espeak-ng data (assets/tts, ~62 MB,
# audio-reader / سماع الكتب) is deliberately NOT in this list — Ismail
# 2026-09-19: "62mb قليل ادمجه في البرنامج" (62MB is little, bundle it in
# the app). Book listening must work fully offline, identically, in both
# flavors — only the Quran corpus text (~330 MB) is lite-excluded.
STRIP_DIRS=(
  "assets/quran/corpus/translations"
  "assets/quran/corpus/tafsir"
  # Content packs on GitHub packs-v1 (CONTENT_PACKS_ARCHITECTURE.md CP4/CP5).
  "assets/quran/corpus/packs"
  "assets/quran/tafsir_packs"
  "assets/tts/packs"
)
BACKUP_DIR=".lite_build_backup"

cleanup() {
  for d in "${STRIP_DIRS[@]}"; do
    name="${d//\//__}"  # full path: corpus/packs and tts/packs must not collide
    if [ -d "$BACKUP_DIR/$name" ] && [ ! -d "$d" ]; then
      mv "$BACKUP_DIR/$name" "$d"
    fi
  done
  rmdir "$BACKUP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Never rm -rf the backup: a previous run killed mid-build leaves the only
# copy of the stripped assets there. Restore it first instead.
cleanup
mkdir -p "$BACKUP_DIR"
for d in "${STRIP_DIRS[@]}"; do
  if [ -d "$d" ]; then
    mv "$d" "$BACKUP_DIR/${d//\//__}"
  fi
done

echo "Building lite APK ($MODE) — corpus text excluded, downloaded on demand..."
flutter build apk "$MODE" --flavor lite "${@:2}"

echo "Done. Corpus assets restored (trap on exit)."
