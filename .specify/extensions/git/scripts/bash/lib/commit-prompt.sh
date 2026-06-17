#!/usr/bin/env bash
# Interactive Conventional Commit prompt (stdin TTY only).

_commit_prompt_interactive() {
  local suggestion="$1"
  local confidence="${2:-low}"
  local paths_summary="${3:-}"

  if [ "$confidence" = "high" ] && [ "${IRON_LOG_COMMIT_INTERACTIVE:-}" != "force" ]; then
    echo "$suggestion"
    return 0
  fi

  if [ ! -t 0 ]; then
    echo "$suggestion"
    return 0
  fi

  echo "" >&2
  echo "━━━ Commit interativo ━━━" >&2
  if [ -n "$paths_summary" ]; then
    echo "Arquivos staged:" >&2
    echo "$paths_summary" | sed 's/^/  /' >&2
  fi
  echo "Sugestão: $suggestion" >&2
  echo "" >&2
  echo "Tipos: feat | fix | docs | chore | test | refactor | build | ci | style | perf" >&2
  read -r -p "Tipo (Enter = aceitar sugestão): " chosen_type </dev/tty

  if [ -z "$chosen_type" ]; then
    echo "$suggestion"
    return 0
  fi

  read -r -p "Escopo opcional (ex: workout, specs): " chosen_scope </dev/tty
  read -r -p "Descrição curta: " chosen_desc </dev/tty

  if [ -z "$chosen_desc" ]; then
    chosen_desc=$(echo "$suggestion" | sed -E 's/^[^(]+(\([^)]*\))?!?: //')
  fi

  if [ -n "$chosen_scope" ]; then
    echo "${chosen_type}(${chosen_scope}): ${chosen_desc}"
  else
    echo "${chosen_type}: ${chosen_desc}"
  fi
}
