#!/usr/bin/env sh
# tool/fetch_tashkeel_model.sh — the Arabic diacritizer before the reading voice
# (lib/services/tts/arabic_diacritizer.dart; study: docs/audio-reader/MY_VOICE_PLAN_2026-11-13.md §10).
#
#   Source : https://huggingface.co/ichkil/ichkil  (model v0.3.0, MIT)
#   Pinned : snapshot ff8783fff6f6986929d8986983279d2f307d7bed, sha256 checked
#   Output : assets/tts/packs/tashkeel-ichkil-v0.3.0.onnx  (22 MB, gitignored;
#            bundled in full, stripped from lite like the voice — LITE_STRIP)
#   The 3 KB config (assets/tts/tashkeel/ichkil_config.json) is committed.
#
#   sh tool/fetch_tashkeel_model.sh            # skips a file that already verifies
set -eu

REV="ff8783fff6f6986929d8986983279d2f307d7bed"
SHA256="9779e1aca89cebc77a9b92037b7d700c422cdf6c3774d4883f4652f641f3f705"
OUT="assets/tts/packs/tashkeel-ichkil-v0.3.0.onnx"

sum() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$1" | cut -d' ' -f1; }

mkdir -p "$(dirname "$OUT")"
if [ -f "$OUT" ] && [ "$(sum "$OUT")" = "$SHA256" ]; then
  echo "skip (verified): $OUT"
  exit 0
fi
echo "fetching: $OUT"
curl -fL -o "$OUT.part" "https://huggingface.co/ichkil/ichkil/resolve/${REV}/model.onnx"
if [ "$(sum "$OUT.part")" != "$SHA256" ]; then
  rm -f "$OUT.part"
  echo "ERROR: sha256 mismatch for the diacritizer model" >&2
  exit 1
fi
mv "$OUT.part" "$OUT"
echo "ok: $OUT"
