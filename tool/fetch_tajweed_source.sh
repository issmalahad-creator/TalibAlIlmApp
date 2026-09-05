#!/usr/bin/env sh
# tool/fetch_tajweed_source.sh  —  Phase G-t1 · fetch the pinned tajwīd inputs.
#
# Downloads, from a PINNED commit, the two files tool/build_tajweed_rules.py
# consumes:
#
#   1. output/tajweed.hafs.uthmani-pause-sajdah.json   (cpfair/quran-tajweed)
#      Per-ayah tajwīd rule spans as half-open Unicode codepoint offsets.
#      Rule DATA licence: CC BY 4.0 — Chris Pearce (cpfair). ~5.6 MB.
#
#   2. quran-uthmani.txt   (the exact base text those offsets index into)
#      Tanzil.net "Text (with aya numbers)" Uthmani, the copy attached to
#      cpfair issue #… ca. 2017-04-06 — the README is explicit that a
#      different text file makes every offset wrong. ~1.4 MB.
#      Text licence: Tanzil.net terms of use. Build-time only; NOT shipped.
#
# Output → tool/vendor/quran-tajweed/  (gitignored, per .gitignore /tool/vendor/).
# The committed artefact is assets/quran/corpus/tajweed.json.gz.
#
#   sh tool/fetch_tajweed_source.sh          # skip files already present + sized
#   sh tool/fetch_tajweed_source.sh --force  # re-download

set -eu

SHA="496f71cd191da00fa2a37ded79dbbddb033bb0ad"   # cpfair/quran-tajweed HEAD, 2021-10-12
DEST="tool/vendor/quran-tajweed"

RULES_URL="https://raw.githubusercontent.com/cpfair/quran-tajweed/${SHA}/output/tajweed.hafs.uthmani-pause-sajdah.json"
RULES_OUT="${DEST}/tajweed.hafs.uthmani-pause-sajdah.json"
RULES_MIN=5000000        # ~5.6 MB expected — reject an obvious truncation

BASE_URL="https://github.com/cpfair/quran-tajweed/files/7281388/quran-uthmani.txt"
BASE_OUT="${DEST}/quran-uthmani.txt"
BASE_EXACT=1376504       # byte-exact; the README pins this specific file

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

mkdir -p "$DEST"

fsize() { wc -c < "$1" 2>/dev/null | tr -d ' ' || echo 0; }

fetch() {
  url="$1"; out="$2"
  printf '  → %s\n' "$url"
  # --retry rides out this host's frequent slow starts; -f fails on 4xx/5xx.
  curl -fL --retry 5 --retry-delay 3 --max-time 900 -o "$out" "$url"
}

# 1. rule spans (pinned SHA)
if [ "$FORCE" -eq 0 ] && [ "$(fsize "$RULES_OUT")" -ge "$RULES_MIN" ]; then
  printf '  ✓ %s (%s bytes) — present\n' "$RULES_OUT" "$(fsize "$RULES_OUT")"
else
  fetch "$RULES_URL" "$RULES_OUT"
  got="$(fsize "$RULES_OUT")"
  [ "$got" -ge "$RULES_MIN" ] || { printf 'ERROR: %s only %s bytes (< %s) — truncated.\n' "$RULES_OUT" "$got" "$RULES_MIN" >&2; exit 1; }
  printf '  ✓ %s (%s bytes)\n' "$RULES_OUT" "$got"
fi

# 2. base text (byte-exact — a different file corrupts every offset)
if [ "$FORCE" -eq 0 ] && [ "$(fsize "$BASE_OUT")" -eq "$BASE_EXACT" ]; then
  printf '  ✓ %s (%s bytes) — present\n' "$BASE_OUT" "$BASE_EXACT"
else
  fetch "$BASE_URL" "$BASE_OUT"
  got="$(fsize "$BASE_OUT")"
  [ "$got" -eq "$BASE_EXACT" ] || { printf 'ERROR: %s is %s bytes, expected exactly %s. Re-run.\n' "$BASE_OUT" "$got" "$BASE_EXACT" >&2; exit 1; }
  printf '  ✓ %s (%s bytes)\n' "$BASE_OUT" "$got"
fi

printf '\nDone. Next:  py tool/build_tajweed_rules.py\n'
