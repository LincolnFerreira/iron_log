# Implementation Plan: Academia e Estação da Máquina

**Branch**: `011-gym-machine-stations` | **Date**: 2026-10-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-gym-machine-stations/spec.md`

**Note**: A rotina continua com um movimento por exercício. Academia e estação existem só na execução (e na edição do treino já feito). Histórico “última vez” e sugestão de carga passam a filtrar pela estação quando ela está selecionada.

## Summary

Acrescentar duas entidades do usuário — academia (`Gym`) e estação do movimento (`ExerciseStation`) — e gravar a escolha no treino executado: `WorkoutSession.gymId` e `SerieLog.stationId` (o mesmo id em todas as séries daquele movimento). O chip de estação aparece só em máquina, cabo e Smith, nos modos de execução, retroativo e edição. Barra, haltere e o editor de rotina não mudam.

Sem estação, última vez e sugestão continuam iguais a hoje. Com estação, as duas consultas ignoram outras máquinas. Treinos antigos ficam sem estação e não são reatribuídos.

## Technical Context

**Language/Version**: Dart ^3.8 / Flutter 3.8+ (app); TypeScript ^5.7 / NestJS 11 (API)

**Primary Dependencies**: flutter_riverpod 3 + riverpod_annotation, go_router, Drift, Dio (`HttpService`); Prisma 6 + PostgreSQL; class-validator; Firebase Auth nos dois lados

**Storage**: PostgreSQL canônico em `iron_log_back_end/prisma/schema.prisma`; espelho Drift em `lib/core/database/` (schema atual v7 → v8). Sem tabela nova de plano (`SessionExercise` intacta).

**Testing**: Jest em `iron_log_back_end/src/**/*.spec.ts` para filtro de última vez, sugestão e gravação da estação em todas as séries; `flutter_test` + `getTestProviderOverrides()` para o portão de equipamento, pré-seleção e rascunho; smoke manual nos três modos de treino

**Target Platform**: Android / iOS (mobile-first, pt-BR)

**Project Type**: App mobile + API REST. Spec e plano ficam em `iron_log`; schema e regras de carga ficam em `iron_log_back_end`.

**Performance Goals**: Escolher estação recente em até dois toques. Lista do picker limitada a 3 estações. Última vez e sugestão continuam uma consulta por movimento, agora com filtro opcional.

**Constraints**: Offline-first (Drift antes da rede; `version` + `pendingSync` + `syncedAt`). Academia e estação sincronizam antes do treino que as referencia. Payload de treino só ganha campos opcionais. Sem catálogo de marcas, fator de polia, segunda linha na rotina, nem duas estações no mesmo movimento do mesmo treino. `WorkoutSessionScreen` permanece legado e fora desta feature.

**Scale/Scope**: Um módulo novo de contexto de treino no app; extensão de `workout_day` (card, rascunho, edição); dois módulos pequenos na API; query params aditivos em `/workout/.../last-sets` e `/suggestion`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Offline-first | PASS | Gym, ExerciseStation, WorkoutSession e SerieLog gravam local primeiro. Troca de estação + séries na mesma transação Drift. Sync de academia/estação antes do `WorkoutOutbox`. |
| II. Feature layers | PASS | Catálogo pessoal em `features/training_place/` (`domain` / `data` / `presentation`). `workout_day` só consome. Sem HTTP na UI. |
| III. Riverpod | PASS | Estado novo com `@riverpod` + `Notifier`/`AsyncNotifier`. UI dá `watch` no estado e `read` no repositório. Sem `StateNotifier`. |
| IV. Core compartilhado | PASS | Endpoints novos só em `api_endpoints.dart`. HTTP via `HttpService`. Erro via `HttpErrorHandler` + `AppSnackbar` em `ref.listen`. |
| V. Escopo de produto | PASS | Continua Rotina → Sessão → WorkoutSession → SerieLog. Estação não entra no plano. Sem vídeo, social, nutrição ou web. |
| VI. Testes | PASS | Jest no filtro de carga; widget/unit no portão de equipamento e no rascunho. Smoke sem rede no quickstart. |

**Post-design re-check**: PASS — contratos mantêm o plano intacto, ids gerados no cliente e campos opcionais. Nenhuma violação nova.

## Project Structure

### Documentation (this feature)

```text
specs/011-gym-machine-stations/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── training-place-api.md
├── checklists/
│   └── requirements.md
└── tasks.md                 # gerado (/speckit-tasks)
```

### Source Code (áreas tocadas)

```text
iron_log/
├── lib/features/training_place/          # novo: Gym + ExerciseStation
│   ├── domain/
│   ├── data/
│   └── presentation/                     # sheet da estação, chip da academia
├── lib/features/workout_day/
│   ├── domain/entities/workout_exercise.dart   # equipment + stationId
│   ├── presentation/organisms/exercise_card.dart
│   ├── presentation/pages/workout_day_screen.dart
│   ├── presentation/providers/exercise_last_sets_provider.dart
│   └── data/mappers/workout_draft_snapshot_mapper.dart
├── lib/core/database/                    # tabelas + schema v8
├── lib/core/api/api_endpoints.dart
├── lib/core/sync/sync_manager.dart       # flush de lugar antes do outbox
└── lib/main.dart                         # overrides do repositório

iron_log_back_end/
├── prisma/schema.prisma                 # Gym, ExerciseStation, FKs
├── src/training-place/                   # novo módulo Nest
├── src/workout/                          # gymId, stationId, last-sets
└── src/suggestion/                       # filtro por estação
```

**Structure Decision**: Dois repositórios, um fluxo. O app é dono da experiência (chip, pré-seleção, rascunho). A API é dona da unicidade da estação, do filtro de histórico e de copiar `stationId` para todas as séries do movimento dentro da transação já usada no treino.

## Complexity Tracking

> Nenhuma violação de constituição requer exceção.

| Item | Notas |
|------|-------|
| Dois repositórios | Schema canônico já vive no backend; o app só espelha. Não é um terceiro projeto. |
| `ExerciseRecord` continua por movimento | A spec mede última vez e sugestão, não PR. Recalcular recorde por estação fica fora. |
| Script genérico de agent context | Não substitui o bloco Spec Kit inteiro; o plano ativo é atualizado dentro do bloco existente. |

## Implementation Phases (design → tasks)

1. **Schema e contrato**: Prisma + Drift v8; CRUD de academia e estação com id do cliente; campos opcionais no treino.
2. **Histórico (US1)**: `stationId` em todas as séries; última vez filtrada; chip só em máquina/cabo/Smith; pré-seleção; edição de treino passado.
3. **Academia (US2)**: chip só com duas ou mais; estações de academias diferentes não se misturam; zero academias continua válido.
4. **Sugestão (US3)**: `/suggestion` respeita `stationId` e não herda carga de outra máquina.
5. **Ajuste (US4)**: renomear e ocultar; rascunho e outbox carregam academia e estação; sync ordenado.
