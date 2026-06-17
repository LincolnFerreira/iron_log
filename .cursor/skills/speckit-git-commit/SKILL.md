---
name: speckit-git-commit
description: Auto-commit changes after a Spec Kit command completes
compatibility: Requires spec-kit project structure with .specify/ directory
metadata:
  author: github-spec-kit
  source: git:commands/speckit.git.commit.md
---

# Auto-Commit Changes

Automatically stage and commit all changes after a Spec Kit command completes.

## Conventional Commits (Iron Log)

When `auto_commit.conventional: true` in `git-config.yml`, messages are generated via `suggest-conventional-message.sh` and validated before commit.

Examples:

- `docs(specs): add specification for 004-git-commit-hooks`
- `docs(specs): add plan for 004-git-commit-hooks`

**Agent rule**: When auto-commit is disabled, propose a conventional message before `git commit`. Install hooks: `./scripts/install-githooks.sh`

## Configuration

```yaml
auto_commit:
  conventional: true
  after_specify:
    enabled: true
  after_plan:
    enabled: true
```

## Execution

`.specify/extensions/git/scripts/bash/auto-commit.sh <event_name>`
