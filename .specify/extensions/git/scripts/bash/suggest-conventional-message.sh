#!/usr/bin/env bash
# Suggest Conventional Commit messages (Spec Kit events or prepare-commit-msg).
#
# Usage:
#   suggest-conventional-message.sh --event <event_name>
#   suggest-conventional-message.sh --prepare <msg-file> <source> [sha]

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
cd "$REPO_ROOT"

_read_feature_dir() {
  local json="$REPO_ROOT/.specify/feature.json"
  if [ ! -f "$json" ]; then
    echo "specs/unknown"
    return
  fi
  grep -E '"feature_directory"' "$json" 2>/dev/null \
    | sed -E 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
    | head -n 1
}

_feature_slug() {
  basename "$(_read_feature_dir)"
}

_branch_scope() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "mixed")
  echo "$branch" | sed -E 's/^[0-9]+-//'
}

_staged_paths() {
  git diff --cached --name-only 2>/dev/null || true
}

_classify_paths() {
  local paths="$1"
  local has_specs=false has_test=false has_build=false has_ci=false
  local has_core=false has_feature=false has_cursor=false has_other=false
  local feature_scope=""

  while IFS= read -r path; do
    [ -z "$path" ] && continue
    case "$path" in
      specs/*|.specify/*) has_specs=true ;;
      test/*|integration_test/*) has_test=true ;;
      pubspec.yaml|android/*|ios/*) has_build=true ;;
      .github/*) has_ci=true ;;
      lib/core/*) has_core=true ;;
      lib/features/*/*)
        has_feature=true
        feature_scope=$(echo "$path" | sed -E 's|^lib/features/([^/]+)/.*|\1|')
        ;;
      .cursor/*) has_cursor=true ;;
      *) has_other=true ;;
    esac
  done <<EOF
$paths
EOF

  local type="chore"
  local scope=""
  local desc="atualiza arquivos do projeto"

  local count=0
  $has_specs && count=$((count + 1))
  $has_test && count=$((count + 1))
  $has_build && count=$((count + 1))
  $has_ci && count=$((count + 1))
  $has_core && count=$((count + 1))
  $has_feature && count=$((count + 1))
  $has_cursor && count=$((count + 1))
  $has_other && count=$((count + 1))

  if [ "$count" -gt 1 ]; then
    scope="$(_branch_scope)"
    echo "${type}|${scope}|${desc}"
    return
  fi

  if $has_specs; then
    echo "docs|specs|atualiza documentação de specs"
    return
  fi
  if $has_test; then
    scope=$(echo "$paths" | grep -E '^test/features/' | head -n 1 | sed -E 's|^test/features/([^/]+)/.*|\1|' || echo "test")
    echo "test|${scope}|adiciona ou atualiza testes"
    return
  fi
  if $has_build; then
    echo "build||atualiza configuração de build"
    return
  fi
  if $has_ci; then
    echo "ci||atualiza pipeline de CI"
    return
  fi
  if $has_core; then
    echo "chore|core|atualiza módulo core"
    return
  fi
  if $has_feature; then
    echo "chore|${feature_scope}|atualiza feature ${feature_scope}"
    return
  fi
  if $has_cursor; then
    echo "chore|speckit|atualiza configuração Spec Kit"
    return
  fi

  scope="$(_branch_scope)"
  echo "${type}|${scope}|${desc}"
}

_format_message() {
  local type="$1"
  local scope="$2"
  local desc="$3"
  if [ -n "$scope" ]; then
    echo "${type}(${scope}): ${desc}"
  else
    echo "${type}: ${desc}"
  fi
}

_suggest_for_event() {
  local event="$1"
  local feature="$(_feature_slug)"
  local scope="$(_branch_scope)"
  local paths="$(_staged_paths)"

  case "$event" in
    after_specify)
      echo "docs(specs): add specification for ${feature}"
      ;;
    after_clarify)
      echo "docs(specs): clarify specification for ${feature}"
      ;;
    after_plan)
      echo "docs(specs): add plan for ${feature}"
      ;;
    after_tasks)
      echo "docs(specs): add tasks for ${feature}"
      ;;
    after_checklist)
      echo "docs(specs): add checklist for ${feature}"
      ;;
    after_analyze)
      echo "docs(specs): add analysis for ${feature}"
      ;;
    after_constitution)
      echo "docs(constitution): update project constitution"
      ;;
    after_implement)
      local only_test=true only_specs=true has_lib=false
      if [ -n "$paths" ]; then
        while IFS= read -r p; do
          [ -z "$p" ] && continue
          case "$p" in
            test/*|integration_test/*) ;;
            *) only_test=false ;;
          esac
          case "$p" in
            specs/*|.specify/*) ;;
            *) only_specs=false ;;
          esac
          case "$p" in
            lib/*) has_lib=true ;;
          esac
        done <<EOF
$paths
EOF
      else
        only_test=false
        only_specs=false
      fi
      if $only_test; then
        echo "test(${scope}): add tests for ${feature}"
      elif $only_specs; then
        echo "docs(specs): update docs for ${feature}"
      elif $has_lib; then
        echo "feat(${scope}): implement ${feature}"
      else
        echo "chore(speckit): implementation progress for ${feature}"
      fi
      ;;
    before_*)
      local phase
      phase=$(echo "$event" | sed 's/^before_//')
      echo "chore(speckit): save progress before ${phase}"
      ;;
    after_*)
      local phase
      phase=$(echo "$event" | sed 's/^after_//')
      echo "chore(speckit): auto-commit after ${phase} for ${feature}"
      ;;
    *)
      echo "chore(speckit): auto-commit ${event}"
      ;;
  esac
}

_prepare_commit_msg() {
  local msg_file="$1"
  local source="$2"

  case "$source" in
    message|merge|squash|template)
      exit 0
      ;;
  esac

  if [ ! -f "$msg_file" ]; then
    exit 0
  fi

  local non_comment
  non_comment=$(grep -v '^#' "$msg_file" | grep -v '^[[:space:]]*$' || true)
  if [ -n "$non_comment" ]; then
    exit 0
  fi

  local paths="$(_staged_paths)"
  if [ -z "$paths" ]; then
    exit 0
  fi

  local classified type scope desc suggestion comments
  classified=$(_classify_paths "$paths")
  type=$(echo "$classified" | cut -d'|' -f1)
  scope=$(echo "$classified" | cut -d'|' -f2)
  desc=$(echo "$classified" | cut -d'|' -f3)
  suggestion=$(_format_message "$type" "$scope" "$desc")

  comments=$(grep '^#' "$msg_file" || true)

  {
    echo "$suggestion"
    echo ""
    if [ -n "$comments" ]; then
      echo "$comments"
    fi
  } > "$msg_file"
}

MODE="${1:-}"
case "$MODE" in
  --event)
    EVENT="${2:-}"
    if [ -z "$EVENT" ]; then
      echo "Usage: $0 --event <event_name>" >&2
      exit 1
    fi
    _suggest_for_event "$EVENT"
    ;;
  --prepare)
    _prepare_commit_msg "${2:-}" "${3:-}"
    ;;
  *)
    echo "Usage: $0 --event <name> | --prepare <msg-file> <source> [sha]" >&2
    exit 1
    ;;
esac
