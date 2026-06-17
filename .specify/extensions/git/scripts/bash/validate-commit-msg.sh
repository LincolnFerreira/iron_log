#!/usr/bin/env bash
# Validates Conventional Commits subject line (Iron Log).
# Usage: validate-commit-msg.sh <commit-msg-file>

set -e

MSG_FILE="${1:-}"
if [ -z "$MSG_FILE" ] || [ ! -f "$MSG_FILE" ]; then
  echo "validate-commit-msg: arquivo de mensagem ausente" >&2
  exit 1
fi

subject=$(head -n 1 "$MSG_FILE" | tr -d '\r')

if echo "$subject" | grep -Eq '^Merge '; then
  exit 0
fi
if echo "$subject" | grep -Eq '^Revert "'; then
  exit 0
fi

CONVENTIONAL_REGEX='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9._-]+\))?!?: .{3,}$'

if echo "$subject" | grep -Eq "$CONVENTIONAL_REGEX"; then
  exit 0
fi

cat >&2 <<'EOF'
Commit rejeitado: mensagem fora do padrão Conventional Commits.

Formato: type(scope): descrição
Tipos: feat, fix, docs, style, refactor, perf, test, build, ci, chore

Exemplo: fix(workout): corrige salto de campo ao focar
EOF
exit 1
