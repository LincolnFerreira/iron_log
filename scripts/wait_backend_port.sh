#!/usr/bin/env bash
# Aguarda o NestJS aceitar conexões (usado pelo compound do workspace).
set -euo pipefail

HOST="${1:-127.0.0.1}"
PORT="${2:-3000}"
MAX_SECONDS="${3:-120}"

for ((i = 1; i <= MAX_SECONDS; i++)); do
  code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 "http://${HOST}:${PORT}/" 2>/dev/null || echo "000")"
  if [[ "${code}" != "000" ]]; then
    echo "Backend OK em http://${HOST}:${PORT}/ (HTTP ${code}, ${i}s)"
    exit 0
  fi
  sleep 1
done

echo "Timeout: nenhum HTTP em http://${HOST}:${PORT}/ após ${MAX_SECONDS}s. Suba o Back antes ou use só 🖥️ LOCAL - Debug." >&2
exit 1
