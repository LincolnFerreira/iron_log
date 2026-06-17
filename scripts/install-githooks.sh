#!/usr/bin/env bash
# Install versioned Git hooks for Iron Log (Conventional Commits).
set -e

REPO_ROOT="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "install-githooks: não é um repositório Git" >&2
  exit 1
fi

chmod +x .githooks/commit-msg .githooks/prepare-commit-msg 2>/dev/null || true
chmod +x .specify/extensions/git/scripts/bash/*.sh 2>/dev/null || true
chmod +x scripts/install-githooks.sh scripts/release-bump.sh test/shell/*.sh test/shell/lib/*.sh 2>/dev/null || true

git config core.hooksPath .githooks

echo "[OK] Git hooks instalados (core.hooksPath=.githooks)"
