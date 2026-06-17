---
name: speckit-git-commit
description: Auto-commit changes after a Spec Kit command completes
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: git:commands/speckit.git.commit.md
---

# Auto-Commit Changes

Automatically stage and commit all changes after **selected** Spec Kit commands complete.

## Iron Log policy — o que auto-commita

| Evento | Auto-commit | Notas |
|--------|-------------|-------|
| `after_specify` | ✅ Sim | Spec/plan docs |
| `after_plan` | ✅ Sim | |
| `after_tasks` | ✅ Sim | |
| **`after_implement`** | **❌ Não** | **Commit manual pelo desenvolvedor** |
| Demais `after_*` | ❌ Não | Unless enabled in config |

**Agent rule (CRITICAL)**: NEVER run `auto-commit.sh after_implement` or `git commit` at the end of `/speckit-implement` unless the user **explicitly** asks. Implementation changes stay uncommitted until the user commits.

## Conventional Commits

When `auto_commit.conventional: true`:

- `interactive: true` — pergunta na CLI quando confiança baixa (stdin TTY)
- `amend_related: true` — amend no último commit se mesma feature (30 min)
- `sync-feature-json.sh` — atualiza `.specify/feature.json` a partir da branch

```yaml
auto_commit:
  conventional: true
  interactive: true
  amend_related: true
  after_implement:
    enabled: false   # MUST stay false — manual commit after implement
```

## Execution

`.specify/extensions/git/scripts/bash/auto-commit.sh <event_name>`

Only invoke when the matching event has `enabled: true` in `git-config.yml`.
