#!/usr/bin/env bash
set -e
ENV_FILE=".env.prod"
if [ -f "$ENV_FILE" ]; then
  echo "Loading $ENV_FILE"
  # Export variables (simple parser; does not handle quoted values with spaces)
  export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

ARGS=(--release --pwa-strategy=offline-first --dart-define=FLAVOR=prod)
[ -n "$API_URL" ] && ARGS+=("--dart-define=API_URL=$API_URL")
[ -n "$FIREBASE_API_KEY" ] && ARGS+=("--dart-define=FIREBASE_API_KEY=$FIREBASE_API_KEY")
[ -n "$FIREBASE_APP_ID" ] && ARGS+=("--dart-define=FIREBASE_APP_ID=$FIREBASE_APP_ID")
[ -n "$FIREBASE_MEASUREMENT_ID" ] && ARGS+=("--dart-define=FIREBASE_MEASUREMENT_ID=$FIREBASE_MEASUREMENT_ID")
[ -n "$FIREBASE_PROJECT_ID" ] && ARGS+=("--dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID")

echo "Running: flutter build web ${ARGS[*]}"
flutter build web "${ARGS[@]}"
