#!/usr/bin/env bash
# E2E Flutter via Patrol (login Google nativo).
#
# Pré-requisitos:
#   dart pub global activate patrol_cli
#   backend local: cd iron_log_back_end && npm run start:dev
#   export E2E_GOOGLE_ACCOUNT=seu@gmail.com  (opcional, senão 1ª conta)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PATROL="${PATROL_CMD:-patrol}"
if ! command -v "$PATROL" >/dev/null 2>&1; then
  PATROL="$HOME/AppData/Local/Pub/Cache/bin/patrol.bat"
fi

TARGET="${1:-integration_test/workout_techniques_e2e_test.dart}"

ARGS=(
  test
  --target "$TARGET"
  --device emulator-5554
  --no-uninstall
)

if [[ -n "${E2E_GOOGLE_ACCOUNT:-}" ]]; then
  ARGS+=(--dart-define="E2E_GOOGLE_ACCOUNT=${E2E_GOOGLE_ACCOUNT}")
fi

echo "▶ Patrol: $TARGET"
"$PATROL" "${ARGS[@]}"
