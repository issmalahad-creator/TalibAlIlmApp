#!/usr/bin/env bash
# Builds the four APKs into /dist/:
#   app-full-PUBLIC-<mode>.apk   app-lite-PUBLIC-<mode>.apk   (no API key)
#   app-full-PRIVATE-<mode>.apk  app-lite-PRIVATE-<mode>.apk  (key injected)
# The key never lives in source: it is read from the gitignored local file
# /.anthropic_key.local (one line, key only) and passed with --dart-define.
# Safety net: a PUBLIC apk containing "sk-ant-api03" is deleted and the
# script fails. Private builds are skipped (with a message) if the key file
# is missing or empty.
#
# Usage: tool/build_all_apks.sh [--debug|--release] [--public-only|--private-only]
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="--debug"; ONLY=""
for a in "$@"; do
  case "$a" in
    --debug|--release) MODE="$a" ;;
    --public-only|--private-only) ONLY="$a" ;;
  esac
done
WORD="${MODE#--}"
OUT="build/app/outputs/flutter-apk"
DIST="dist"; mkdir -p "$DIST"
KEY_FILE=".anthropic_key.local"
NEEDLE="sk-ant-api03"

count_key() { # apk -> number of key matches in kernel + dex (count only, never prints)
  local apk="$1" a b
  a=$(unzip -p "$apk" assets/flutter_assets/kernel_blob.bin 2>/dev/null | grep -c "$NEEDLE" || true)
  b=$(unzip -p "$apk" 'classes*.dex' 2>/dev/null | grep -c "$NEEDLE" || true)
  echo $((a + b))
}

build_one() { # flavor kind [extra flutter args...]
  local flavor="$1" kind="$2"; shift 2
  echo "=== building $flavor / $kind ==="
  bash "tool/build_${flavor}_apk.sh" "$MODE" "$@"
  local src="$OUT/app-$flavor-$WORD.apk" dst="$DIST/app-$flavor-$kind-$WORD.apk"
  cp -f "$src" "$dst"
  local n; n=$(count_key "$dst")
  if [ "$kind" = "PUBLIC" ] && [ "$n" -ne 0 ]; then
    rm -f "$dst"; echo "FATAL: $dst contained the API key ($n matches) — deleted." >&2; exit 1
  fi
  echo "$dst  key matches: $n"
}

if [ "$ONLY" != "--private-only" ]; then
  build_one full PUBLIC
  build_one lite PUBLIC
fi

if [ "$ONLY" != "--public-only" ]; then
  if [ -s "$KEY_FILE" ]; then
    KEY="$(tr -d '\r\n ' < "$KEY_FILE")"
    build_one full PRIVATE "--dart-define=ANTHROPIC_API_KEY=$KEY"
    build_one lite PRIVATE "--dart-define=ANTHROPIC_API_KEY=$KEY"
  else
    echo "SKIPPED private builds: $KEY_FILE is missing or empty (put the key there, one line)."
  fi
fi
echo "--- dist ---"; ls -la --time-style=long-iso "$DIST"
