#!/usr/bin/env bash
# Builds the "full" APK flavor — everything bundled (today's existing
# behaviour and applicationId), no download-on-demand ever needed. The
# counterpart to tool/build_lite_apk.sh; kept as its own script so the
# --flavor flag isn't something every contributor has to remember.
#
# Usage: tool/build_full_apk.sh [--release|--debug]  (default: --release)
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:---release}"
flutter build apk "$MODE" --flavor full
