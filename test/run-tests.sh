#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BIN="$ROOT_DIR/bin/codex-tmux-title"
FIXTURES="$ROOT_DIR/test/fixtures"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_eq() {
  name="$1"
  expected="$2"
  actual="$3"

  if [ "$expected" != "$actual" ]; then
    printf 'not ok - %s\nexpected: %s\nactual:   %s\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi

  printf 'ok - %s\n' "$name"
}

command -v jq >/dev/null 2>&1 || fail "jq is required"
command -v sqlite3 >/dev/null 2>&1 || fail "sqlite3 is required"

DB="$TMP_DIR/state.sqlite"
sqlite3 "$DB" \
  "create table threads (id text primary key, title text not null);
   insert into threads values ('019e1e2a-1feb-7060-aa12-95951d63649a', 'SQLite title wins');"

output="$(
  CODEX_STATE_DB="$DB" \
  CODEX_SESSION_INDEX="$FIXTURES/session_index.jsonl" \
  "$BIN" --print < "$FIXTURES/hook-stop.json"
)"
assert_eq "uses session index title first" "Build tmux naming hook" "$output"

CONTROL_DB="$TMP_DIR/control.sqlite"
sqlite3 "$CONTROL_DB" \
  "create table threads (id text primary key, title text not null);
   insert into threads values ('019e1e2a-1feb-7060-aa12-95951d63649a', char(27) || 'Bad' || char(7) || ' Title');"

output="$(
  CODEX_STATE_DB="$CONTROL_DB" \
  CODEX_SESSION_INDEX="$TMP_DIR/missing.jsonl" \
  "$BIN" --print < "$FIXTURES/hook-stop.json"
)"
assert_eq "uses sanitized sqlite title when session index is missing" "Bad Title" "$output"

output="$(
  CODEX_STATE_DB="$TMP_DIR/missing.sqlite" \
  CODEX_SESSION_INDEX="$FIXTURES/session_index.jsonl" \
  "$BIN" --print < "$FIXTURES/hook-stop.json"
)"
assert_eq "falls back to session index" "Build tmux naming hook" "$output"

output="$(
  CODEX_STATE_DB="$TMP_DIR/missing.sqlite" \
  CODEX_SESSION_INDEX="$TMP_DIR/missing.jsonl" \
  "$BIN" --print < "$FIXTURES/hook-stop.json"
)"
assert_eq "falls back to session id" "019e1e2a-1feb-7060-aa12-95951d63649a" "$output"

cat > "$TMP_DIR/no-session-id.json" <<'JSON'
{
  "cwd": "/Users/example/dev/project",
  "hook_event_name": "SessionStart"
}
JSON

output="$(
  CODEX_STATE_DB="$TMP_DIR/missing.sqlite" \
  CODEX_SESSION_INDEX="$TMP_DIR/missing.jsonl" \
  CODEX_THREAD_ID= \
  "$BIN" --print < "$TMP_DIR/no-session-id.json"
)"
assert_eq "does not fall back to cwd without session id" "" "$output"

output="$(
  CODEX_STATE_DB="$TMP_DIR/missing.sqlite" \
  CODEX_SESSION_INDEX="$FIXTURES/session_index.jsonl" \
  TMUX_PANE= \
  "$BIN" --dry-run < "$FIXTURES/hook-stop.json"
)"
assert_eq "dry run prints rename command" "tmux rename-window Build tmux naming hook" "$output"

output="$(
  CODEX_STATE_DB="$TMP_DIR/missing.sqlite" \
  CODEX_SESSION_INDEX="$FIXTURES/session_index.jsonl" \
  TMUX_PANE=%9 \
  "$BIN" --dry-run < "$FIXTURES/hook-stop.json"
)"
assert_eq "dry run targets current tmux pane when available" "tmux rename-window -t %9 Build tmux naming hook" "$output"
