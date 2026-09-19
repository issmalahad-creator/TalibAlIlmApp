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
STRIP_DIRS=(
  "assets/quran/corpus/translations"
  "assets/quran/corpus/tafsir"
  # Piper TTS voice model + espeak-ng phoneme data (~62 MB, audio-reader /
  # سماع الكتب feature) — present only once that branch is merged; the `if
  # -d` guards below make this a no-op until then. Ismail: audio listening
  # must still work in the lite build, via on-demand download of this same
  # directory the first time it's needed (same pattern as the Quran corpus
  # text) — not simply omitted from the feature set.
  "assets/tts"
)
BACKUP_DIR=".lite_build_backup"

cleanup() {
  for d in "${STRIP_DIRS[@]}"; do
    name="$(basename "$d")"
    if [ -d "$BACKUP_DIR/$name" ] && [ ! -d "$d" ]; then
      mv "$BACKUP_DIR/$name" "$d"
    fi
  done
  rmdir "$BACKUP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for d in "${STRIP_DIRS[@]}"; do
  if [ -d "$d" ]; then
    mv "$d" "$BACKUP_DIR/$(basename "$d")"
  fi
done

echo "Building lite APK ($MODE) — corpus text excluded, downloaded on demand..."
flutter build apk "$MODE" --flavor lite

echo "Done. Corpus assets restored (trap on exit)."
