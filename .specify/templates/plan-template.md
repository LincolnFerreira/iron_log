# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart ^3.8 / Flutter 3.8+ (client); TypeScript / NestJS (backend em `iron_log_back_end`)

**Primary Dependencies**: Riverpod, go_router, Drift, Dio, Firebase Auth; Prisma + PostgreSQL no backend

**Storage**: Drift (SQLite) local; PostgreSQL canônico via Prisma no backend

**Testing**: flutter_test (`test/`), Patrol + integration_test (`integration_test/`)

**Target Platform**: Android/iOS mobile-first (sem versão web)

**Project Type**: mobile-app + REST API (dois repositórios)

**Performance Goals**: UI responsiva em execução de treino; sync em background sem bloquear gravação local

**Constraints**: offline-first obrigatório; strings pt-BR inline; sem mídia de execução de exercícios

**Scale/Scope**: usuário individual; domínio rotina → sessão → workout → série

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify against `.specify/memory/constitution.md` (Iron Log v1.0.0+):

- [ ] **Offline-first**: escrita local Drift + `pendingSync`/`version`; sync via SyncManager ou outbox quando aplicável
- [ ] **Feature layers**: `data/domain/presentation` para lógica de negócio; providers injetáveis com override em `main.dart`
- [ ] **Riverpod only**: sem BLoC/provider em código novo
- [ ] **Core reuse**: HttpService, ApiEndpoints, AppTheme, AppSnackbar, componentes em `lib/core/components/`
- [ ] **Product scope**: sem vídeo/imagem de técnica, social, nutrição, wearables ou web
- [ ] **Domain model**: respeita Rotina → Sessão → WorkoutSession → SerieLog
- [ ] **Workout modes**: se touch em execução, documentar `WorkoutScreenMode` + `WorkoutMode` e ramificação start/finish
- [ ] **Tests**: plano indica unit/widget e/ou Patrol E2E para fluxos críticos

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
iron_log/                          # Flutter client (este repo)
├── lib/
│   ├── core/                      # api, database, sync, services, theme, routes
│   └── features/<feature>/        # data, domain, presentation
├── test/
└── integration_test/

iron_log_back_end/                 # NestJS API (repo irmão)
├── prisma/schema.prisma
└── src/<module>/                  # routine, session, workout, sync, auth, user
```

**Structure Decision**: Mobile + API. Implementação cliente em `lib/features/<feature>/`;
alterações de schema canônico no backend (`iron_log_back_end/prisma/schema.prisma`)
quando a feature exigir persistência servidor.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
