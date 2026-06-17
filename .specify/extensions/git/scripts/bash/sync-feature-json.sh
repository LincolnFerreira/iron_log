#!/usr/bin/env bash
# Sync .specify/feature.json with current feature branch (NNN-short-name).
# Usage: sync-feature-json.sh

set -e

SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_find_project_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.specify" ] || [ -d "$dir/.git" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

REPO_ROOT="$(_find_project_root "$SCRIPT_DIR")" || REPO_ROOT="$(pwd)"
JSON="$REPO_ROOT/.specify/feature.json"
branch=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if ! echo "$branch" | grep -Eq '^[0-9]{3}-[a-z0-9-]+$'; then
  exit 0
fi

feature_dir="specs/${branch}"
if [ ! -d "$REPO_ROOT/$feature_dir" ]; then
  exit 0
fi

current=""
if [ -f "$JSON" ]; then
  current=$(grep -E '"feature_directory"' "$JSON" 2>/dev/null \
    | sed -E 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
    | head -n 1)
fi

if [ "$current" = "$feature_dir" ]; then
  exit 0
fi

mkdir -p "$REPO_ROOT/.specify"
printf '{\n  "feature_directory": "%s"\n}\n' "$feature_dir" > "$JSON"
echo "[specify] feature.json atualizado → ${feature_dir}" >&2
