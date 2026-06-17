#!/usr/bin/env bash
# Bump pubspec.yaml SemVer from conventional commits since last tag.
# Usage: release-bump.sh [--dry-run]

set -e

REPO_ROOT="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
PUBSPEC="$REPO_ROOT/pubspec.yaml"
DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

if [ ! -f "$PUBSPEC" ]; then
  echo "release-bump: pubspec.yaml não encontrado" >&2
  exit 1
fi

last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$last_tag" ]; then
  range="${last_tag}..HEAD"
else
  range="HEAD"
fi

commits=$(git log "$range" --pretty=format:%s 2>/dev/null || true)

bump="patch"
if echo "$commits" | grep -Eq '^[a-z]+(\([^)]*\))?!:' || echo "$commits" | grep -q 'BREAKING CHANGE'; then
  bump="major"
elif echo "$commits" | grep -Eq '^feat(\(|:)'; then
  bump="minor"
fi

current=$(grep -E '^version:' "$PUBSPEC" | head -n 1 | sed -E 's/^version:[[:space:]]*//')
version_part=$(echo "$current" | cut -d'+' -f1)
build_part=$(echo "$current" | cut -d'+' -f2)
major=$(echo "$version_part" | cut -d. -f1)
minor=$(echo "$version_part" | cut -d. -f2)
patch=$(echo "$version_part" | cut -d. -f3)

case "$bump" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
esac

if [ -z "$build_part" ]; then
  build_part=1
else
  build_part=$((build_part + 1))
fi

new_version="${major}.${minor}.${patch}+${build_part}"

echo "Last tag: ${last_tag:-<none>}"
echo "Bump kind: $bump"
echo "Current:   $current"
echo "New:       $new_version"

if $DRY_RUN; then
  echo "[dry-run] pubspec.yaml not modified"
  exit 0
fi

if sed --version >/dev/null 2>&1; then
  sed -i "s/^version:.*/version: ${new_version}/" "$PUBSPEC"
else
  sed -i '' "s/^version:.*/version: ${new_version}/" "$PUBSPEC"
fi

echo "[OK] Updated pubspec.yaml to version: ${new_version}"
