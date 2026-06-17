#!/usr/bin/env bash
# Tests for validate-commit-msg.sh
set -e

ROOT="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=test/shell/lib/assert.sh
source "$ROOT/test/shell/lib/assert.sh"

VALIDATOR="$ROOT/.specify/extensions/git/scripts/bash/validate-commit-msg.sh"
SUGGEST="$ROOT/.specify/extensions/git/scripts/bash/suggest-conventional-message.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

write_msg() {
  printf '%s\n' "$2" > "$tmpdir/$1"
}

echo "=== validate-commit-msg tests ==="

write_msg invalid1 "update stuff"
assert_exit 1 bash "$VALIDATOR" "$tmpdir/invalid1"

write_msg invalid2 "[Spec Kit] Add specification"
assert_exit 1 bash "$VALIDATOR" "$tmpdir/invalid2"

write_msg invalid3 "WIP"
assert_exit 1 bash "$VALIDATOR" "$tmpdir/invalid3"

write_msg invalid4 "fix: ab"
assert_exit 1 bash "$VALIDATOR" "$tmpdir/invalid4"

write_msg invalid5 "unknown: something here"
assert_exit 1 bash "$VALIDATOR" "$tmpdir/invalid5"

write_msg valid1 "feat(workout): adiciona entrada por voz"
assert_exit 0 bash "$VALIDATOR" "$tmpdir/valid1"

write_msg valid2 "fix(sync): corrige fila outbox"
assert_exit 0 bash "$VALIDATOR" "$tmpdir/valid2"

write_msg valid3 "docs(specs): add specification for git commit hooks"
assert_exit 0 bash "$VALIDATOR" "$tmpdir/valid3"

write_msg valid4 "chore: atualiza dependências menores"
assert_exit 0 bash "$VALIDATOR" "$tmpdir/valid4"

write_msg valid5 "feat!: remove API legada de rotinas"
assert_exit 0 bash "$VALIDATOR" "$tmpdir/valid5"

write_msg merge "Merge branch 'main' into feature"
assert_exit 0 bash "$VALIDATOR" "$tmpdir/merge"

write_msg revert 'Revert "feat: something"'
assert_exit 0 bash "$VALIDATOR" "$tmpdir/revert"

for event in after_specify after_plan after_tasks after_constitution; do
  msg=$("$SUGGEST" --event "$event")
  write_msg "event-$event" "$msg"
  assert_exit 0 bash "$VALIDATOR" "$tmpdir/event-$event" "event $event"
done

implement_msg=$("$SUGGEST" --event after_implement)
write_msg event-implement "$implement_msg"
assert_exit 0 bash "$VALIDATOR" "$tmpdir/event-implement"

echo "All validate-commit-msg tests passed."
