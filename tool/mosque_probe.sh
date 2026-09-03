#!/usr/bin/env sh
# tool/mosque_probe.sh  —  Phase 74 · verify the «مساجدنا» Supabase backend.
#
# Reads the project URL + publishable key from the gitignored
# lib/config/app_config.dart and checks that the schema is applied and the
# pilot mosque is readable with the anon key (i.e. RLS is right).
#
#   sh tool/mosque_probe.sh
#
# Uses only the publishable key — no secrets. Prints PASS/FAIL per check.

CFG="lib/config/app_config.dart"
[ -f "$CFG" ] || { echo "FAIL: $CFG not found (copy from .example and fill in)"; exit 1; }

URL="$(grep -oE 'https://[a-z0-9]+\.supabase\.co' "$CFG" | head -1)"
KEY="$(grep -oE '(sb_publishable_[A-Za-z0-9_-]+|eyJ[A-Za-z0-9_.-]+)' "$CFG" | head -1)"

[ -n "$URL" ] || { echo "FAIL: no supabaseUrl in $CFG"; exit 1; }
[ -n "$KEY" ] || { echo "FAIL: no supabaseAnonKey in $CFG"; exit 1; }
echo "project: $URL"

probe() { # label  path  expect-substr
  code=$(curl -s -o /tmp/_mp.json -w '%{http_code}' \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
    "$URL/rest/v1/$2")
  if [ "$code" = "200" ] && grep -q "$3" /tmp/_mp.json 2>/dev/null; then
    echo "PASS  $1"
  else
    echo "FAIL  $1  (HTTP $code)  $(head -c 160 /tmp/_mp.json)"
    FAILED=1
  fi
}

FAILED=0
probe "schema applied + pilot mosque visible" \
      "mosques?select=id,name,status&id=eq.MOSQ_PILOT_0001" "MOSQ_PILOT_0001"
probe "sections readable"  "mosque_sections?select=type&mosque_id=eq.MOSQ_PILOT_0001&limit=1" "type"
probe "published content readable" \
      "mosque_content?select=id&mosque_id=eq.MOSQ_PILOT_0001&status=eq.published&limit=1" "MC_PILOT_"

# RLS negative check: admin tables must NOT be readable with the anon key
code=$(curl -s -o /tmp/_mp.json -w '%{http_code}' \
  -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
  "$URL/rest/v1/mosque_pending_changes?select=id&limit=1")
if [ "$code" = "200" ] && [ "$(tr -d '[:space:]' < /tmp/_mp.json)" = "[]" ] || [ "$code" != "200" ]; then
  echo "PASS  admin tables locked to anon (mosque_pending_changes → $code / empty)"
else
  echo "FAIL  mosque_pending_changes is readable with the anon key! (HTTP $code)"
  FAILED=1
fi

rm -f /tmp/_mp.json
[ "$FAILED" = "0" ] && { echo; echo "backend ready — MosqueRepository will read it live."; exit 0; }
echo; echo "run docs/mosque/supabase_schema.sql in the Supabase SQL Editor, then re-run."
exit 1
