#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

flutter_bin="$(command -v flutter || true)"
if [[ -z "$flutter_bin" ]]; then
  for candidate in \
    "$HOME/flutter/bin/flutter" \
    "/opt/flutter/bin/flutter" \
    "/usr/local/flutter/bin/flutter"; do
    if [[ -x "$candidate" ]]; then
      flutter_bin="$candidate"
      break
    fi
  done
fi

if [[ -z "$flutter_bin" || ! -x "$flutter_bin" ]]; then
  echo "Flutter SDK not found. Install Flutter and add it to PATH." >&2
  exit 1
fi

flutter_root="$(dirname "$flutter_bin")"
export PATH="$flutter_root:$PATH"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  for candidate in \
    "$HOME/Android/Sdk" \
    "/Users/$(whoami)/Library/Android/sdk" \
    "/opt/android-sdk"; do
    if [[ -d "$candidate" ]]; then
      export ANDROID_HOME="$candidate"
      export ANDROID_SDK_ROOT="$candidate"
      break
    fi
  done
fi

if [[ -n "${ANDROID_HOME:-}" ]]; then
  echo "Android SDK: ${ANDROID_HOME}"
else
  echo "Android SDK not detected automatically; set ANDROID_HOME / ANDROID_SDK_ROOT before Android builds."
fi

echo "Running flutter pub get..."
flutter pub get

if [[ "${1:-}" == "--doctor" ]]; then
  flutter doctor
fi

if [[ "${1:-}" == "--analyze" ]]; then
  flutter analyze
fi

echo "Setup complete. If Android doctor times out, run: flutter doctor --android-licenses"
echo "Next steps:"
echo "  flutter analyze"
echo "  flutter build apk --debug --split-per-abi --flavor full"
