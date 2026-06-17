#!/usr/bin/env bash
# Tests for suggest-conventional-message.sh (path classification + prepare mode)
set -e

ROOT="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=test/shell/lib/assert.sh
source "$ROOT/test/shell/lib/assert.sh"

SUGGEST="$ROOT/.specify/extensions/git/scripts/bash/suggest-conventional-message.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "=== suggest-conventional-message tests ==="

# Event mode basics
msg=$("$SUGGEST" --event after_specify)
assert_match '^docs\(specs\): add specification for ' "$msg" "after_specify"

msg=$("$SUGGEST" --event after_plan)
assert_match '^docs\(specs\): add plan for ' "$msg" "after_plan"

# prepare: skip on source=message
printf 'feat(test): existing\n' > "$tmpdir/msg"
cp "$tmpdir/msg" "$tmpdir/msg.bak"
bash "$SUGGEST" --prepare "$tmpdir/msg" message
assert_eq "$(cat "$tmpdir/msg.bak")" "$(cat "$tmpdir/msg")" "skip message source"

# prepare: skip when non-comment content exists
printf 'custom: message here\n' > "$tmpdir/msg2"
cp "$tmpdir/msg2" "$tmpdir/msg2.bak"
bash "$SUGGEST" --prepare "$tmpdir/msg2" ""
assert_eq "$(cat "$tmpdir/msg2.bak")" "$(cat "$tmpdir/msg2")" "skip existing content"

# prepare: specs-only staged (requires git repo)
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  test_file="$ROOT/specs/001-api-error-observability/.suggest-test-tmp"
  touch "$test_file"
  git -C "$ROOT" add "$test_file"
  printf '# comment\n' > "$tmpdir/prepare-specs"
  bash "$SUGGEST" --prepare "$tmpdir/prepare-specs" ""
  first_line=$(head -n 1 "$tmpdir/prepare-specs")
  assert_match '^docs\(specs\):' "$first_line" "specs suggestion"
  git -C "$ROOT" reset HEAD "$test_file" >/dev/null 2>&1 || true
  rm -f "$test_file"

  test_file="$ROOT/lib/core/.suggest-test-tmp"
  touch "$test_file"
  git -C "$ROOT" add "$test_file"
  printf '#\n' > "$tmpdir/prepare-lib"
  bash "$SUGGEST" --prepare "$tmpdir/prepare-lib" ""
  first_line=$(head -n 1 "$tmpdir/prepare-lib")
  assert_not_match '^feat' "$first_line" "no auto feat"
  assert_not_match '^fix' "$first_line" "no auto fix"
  git -C "$ROOT" reset HEAD "$test_file" >/dev/null 2>&1 || true
  rm -f "$test_file"
fi

echo "All suggest-conventional-message tests passed."
