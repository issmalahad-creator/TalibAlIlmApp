#!/usr/bin/env sh
# tool/check_secrets.sh  —  Phase 74 / S0 · keep secrets out of git.
#
# Blocks credential shapes that must never be committed:
#   - Postgres / Supabase connection strings with an inline password
#   - service_role keys, *_SERVICE_ROLE_KEY, DB-password assignments
#   - PEM private keys · Telegram bot tokens · AWS key ids
#   - the gitignored real lib/config/app_config.dart being force-staged
#
# The publishable Supabase **anon** key and the project **URL** are meant to
# ship in the client (RLS gates the data) — allowed.
#
#   sh tool/check_secrets.sh            # scan the staged diff (pre-commit)
#   sh tool/check_secrets.sh --all      # scan the whole tracked tree
#
# Exit 1 (with file:line) on a hit; 0 when clean.
# Enable the hook once:   git config core.hooksPath .githooks
# Bypass one commit only if certain:   git commit --no-verify

MODE="${1:-staged}"

# One combined regex. Keep each alternative anchored enough to avoid noise.
# The password segment excludes <> so doc placeholders like `<pw>` don't hit.
RE='postgres(ql)?://[A-Za-z0-9._%+-]+:[^@<>[:space:]"'"'"']{4,}@'
RE="$RE"'|(db\.[a-z0-9]{16,}\.supabase\.co|pooler\.supabase\.com)[^[:space:]]*:[0-9]{4,5}'
RE="$RE"'|SERVICE_ROLE_KEY|SUPABASE_SERVICE_ROLE|"role"[[:space:]]*:[[:space:]]*"service_role"'
RE="$RE"'|(DB_PASSWORD|DATABASE_PASSWORD|PG_?PASSWORD|SUPABASE_DB_PASSWORD)[[:space:]]*[:=]'
RE="$RE"'|(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{8,}["'"'"']'
RE="$RE"'|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
RE="$RE"'|[0-9]{8,10}:AA[A-Za-z0-9_-]{30,}'
RE="$RE"'|AKIA[0-9A-Z]{16}'
RE="$RE"'|sb_secret_[A-Za-z0-9_-]{10,}'
RE="$RE"'|sbp_[a-f0-9]{40}'

# Paths never scanned: this guard, the placeholder template, binaries/assets.
EXCLUDES=":(exclude)tool/check_secrets.sh
:(exclude)*app_config.example.dart
:(exclude)assets/**
:(exclude)*.gz
:(exclude)*.png
:(exclude)*.jpg
:(exclude)*.jpeg
:(exclude)*.svg
:(exclude)*.pdf
:(exclude)*.zip
:(exclude)*.ttf
:(exclude)*.otf
:(exclude)*.jsonl"

hit=0

if [ "$MODE" = "--all" ]; then
  # shellcheck disable=SC2086
  out="$(git grep -nIE "$RE" -- . $EXCLUDES 2>/dev/null)"
  [ -n "$out" ] && hit=1
else
  staged="$(git diff --cached --name-only --diff-filter=AM)"
  if printf '%s\n' "$staged" | grep -qx 'lib/config/app_config.dart'; then
    printf '[check_secrets] BLOCKED — the real lib/config/app_config.dart is\n'
    printf 'staged. It must stay gitignored (URL + publishable anon key only).\n'
    exit 1
  fi
  # scan only the ADDED lines of the staged diff
  # shellcheck disable=SC2086
  out="$(git diff --cached --unified=0 --diff-filter=AM -- . $EXCLUDES \
    | awk '
        /^\+\+\+ /      { f=$2; sub(/^b\//,"",f); ln=0; next }
        /^@@ /          { if (match($0,/\+[0-9]+/)) ln=substr($0,RSTART+1,RLENGTH-1)+0; next }
        /^\+/           { print f ":" ln "\t" substr($0,2); ln++ ; next }
      ' \
    | grep -E "	.*($RE)" )"
  [ -n "$out" ] && hit=1
fi

if [ "$hit" -ne 0 ]; then
  printf '\n[check_secrets] BLOCKED — possible secret(s) in %s changes:\n\n' "$MODE"
  printf '%s\n' "$out" | cut -c1-160
  printf '\nMove the value to the gitignored lib/config/app_config.dart (URL +\n'
  printf 'publishable anon key only) or a server-side env. Never commit a DB\n'
  printf 'password or a service_role key.\n'
  exit 1
fi

printf '[check_secrets] ok — no secrets in %s changes\n' "$MODE"
exit 0
