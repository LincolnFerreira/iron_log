#!/usr/bin/env bash
# Architecture guardrails for Iron Log (feature 006).
# Usage: ./scripts/check_architecture.sh [base_ref]
# Default base_ref: main

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE_REF="${1:-main}"
FAIL=0

echo "== Architecture checks (iron_log) =="
echo "Repo: $ROOT"
echo ""

warn() { echo "WARN: $*"; }
fail() { echo "FAIL: $*"; FAIL=1; }
ok() { echo "OK: $*"; }

# 1. No provider / flutter_bloc imports in lib/
if rg -q "package:provider/|package:flutter_bloc/" lib/ 2>/dev/null; then
  fail "lib/ imports package:provider or flutter_bloc"
  rg "package:provider/|package:flutter_bloc/" lib/ || true
else
  ok "no provider/bloc imports in lib/"
fi

# 2. No legacy endpoints.dart
if rg -q "api/endpoints\.dart" lib/ test/ 2>/dev/null; then
  fail "imports of deprecated lib/core/api/endpoints.dart remain"
  rg "api/endpoints\.dart" lib/ test/ || true
else
  ok "no endpoints.dart imports"
fi

# 3. New StateNotifier in diff vs base (if git available)
if git rev-parse --git-dir >/dev/null 2>&1; then
  if git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    NEW_SN=$(git diff "$BASE_REF"...HEAD -- lib/ \
      | rg "^\+.*extends StateNotifier" || true)
    if [ -n "$NEW_SN" ]; then
      fail "new StateNotifier classes in diff vs $BASE_REF"
      echo "$NEW_SN"
    else
      ok "no new StateNotifier in branch diff (lib/)"
    fi
  else
    warn "base ref $BASE_REF not found — skipping StateNotifier diff check"
  fi
else
  warn "not a git repo — skipping diff checks"
fi

# 4. Legacy folders at feature root (not under presentation/)
LEGACY_DIRS=""
while IFS= read -r -d '' dir; do
  LEGACY_DIRS="${LEGACY_DIRS}${dir}"$'\n'
done < <(find lib/features -type d \( -path '*/state' -o -path '*/bloc' -o -path '*/components' \) \
  ! -path '*/presentation/*' -print0 2>/dev/null || true)

if [ -n "$(echo "$LEGACY_DIRS" | tr -d '[:space:]')" ]; then
  fail "legacy state/, bloc/, or components/ folders outside presentation/:"
  echo "$LEGACY_DIRS" | sed '/^$/d'
else
  ok "no legacy state/bloc/components folders at feature root"
fi

# 5. Nested presentation/components/components (double atomic tree)
NESTED=$(find lib/features -type d -path '*/presentation/components/components' 2>/dev/null || true)
if [ -n "$NESTED" ]; then
  fail "nested presentation/components/components/ — flatten to single atomic tree"
  echo "$NESTED"
else
  ok "no nested presentation/components/components"
fi

# 6. Forbidden new folders in diff (heuristic)
if git rev-parse --git-dir >/dev/null 2>&1 && git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  BAD_DIRS=$(git diff --name-only "$BASE_REF"...HEAD -- lib/features/ \
    | rg "/state/|/bloc/" || true)
  if [ -n "$BAD_DIRS" ]; then
    warn "diff touches legacy state/ or bloc/ paths (migrate to presentation/providers):"
    echo "$BAD_DIRS"
  fi
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "All critical checks passed."
  exit 0
else
  echo "One or more critical checks failed."
  exit 1
fi
