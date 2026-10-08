# Tasks: Academia e Estação da Máquina

**Input**: Design documents from `/specs/011-gym-machine-stations/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/training-place-api.md, quickstart.md

**Tests**: Incluídos porque plan.md, quickstart.md e a constituição VI pedem Jest e flutter_test. Não é TDD estrito — o teste fecha a história depois do comportamento, não antes.

**Organization**: Tarefas agrupadas por user story (spec.md). Schema, Drift e repositório local ficam na fase Foundational porque US1–US4 dependem deles.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefas incompletas)
- **[Story]**: US1–US4 conforme spec.md
- Fase Setup e Foundational não levam label de story

## Path Conventions

- App: `iron_log/lib/` e `iron_log/test/`
- API: `iron_log_back_end/prisma/` e `iron_log_back_end/src/`
- Contrato: `iron_log/specs/011-gym-machine-stations/contracts/training-place-api.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Alinhar os dois repositórios e reservar os caminhos da feature

- [x] T001 Criar ou trocar para a branch `011-gym-machine-stations` em `iron_log_back_end/` (o app `iron_log/` já está nela)
- [x] T002 [P] Criar o esqueleto `iron_log/lib/features/training_place/domain/`, `data/`, `presentation/` e o arquivo `iron_log/lib/features/training_place/training_place_providers.dart`
- [x] T003 [P] Declarar `GET/POST /gyms`, `PATCH /gyms/:id`, `GET/POST /exercise-stations` e `PATCH /exercise-stations/:id` em `iron_log/lib/core/api/api_endpoints.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Tabelas, ids do cliente e repositório local — bloqueia todas as user stories

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

- [x] T004 Adicionar `Gym`, `ExerciseStation`, `WorkoutSession.gymId` e `SerieLog.stationId` em `iron_log_back_end/prisma/schema.prisma` conforme `specs/011-gym-machine-stations/data-model.md` (uniq de apelido, `archivedAt`, sync `version`/`pendingSync`/`syncedAt`, FK do mesmo usuário)
- [x] T005 Gerar a migration Prisma em `iron_log_back_end/prisma/migrations/` sem alterar tabelas fora desse modelo
- [x] T006 [P] Criar `iron_log/lib/core/database/gyms_table.dart` e `iron_log/lib/core/database/exercise_stations_table.dart` com os mesmos campos e sync
- [x] T007 Adicionar `gymId` em `iron_log/lib/core/database/workout_sessions_table.dart`, `stationId` em `iron_log/lib/core/database/serie_logs_table.dart`, registrar as tabelas novas e subir `schemaVersion` para 8 com migration aditiva em `iron_log/lib/core/database/app_database.dart`
- [x] T008 Gerar o cliente Drift e atualizar `iron_log/lib/core/database/app_database.g.dart`
- [x] T009 [P] Criar entidades `iron_log/lib/features/training_place/domain/entities/gym.dart` e `iron_log/lib/features/training_place/domain/entities/exercise_station.dart`
- [x] T010 [P] Criar a interface `iron_log/lib/features/training_place/domain/repositories/training_place_repository.dart` (CRUD local, listagem por movimento e academia, id cuid gerado no cliente)
- [x] T011 Implementar `iron_log/lib/features/training_place/data/datasources/training_place_local_datasource.dart` com escrita Drift antes de rede e `pendingSync`
- [x] T012 Implementar `iron_log/lib/features/training_place/data/repositories/training_place_repository_impl.dart` usando só o datasource local nesta fase
- [x] T013 Registrar `trainingPlaceProvidersOverrides` em `iron_log/lib/features/training_place/training_place_providers.dart` e no `ProviderScope` de `iron_log/lib/main.dart` (`ref.read` no repositório, sem `StateNotifier`)
- [x] T014 Criar `iron_log_back_end/src/training-place/training-place.module.ts` e registrá-lo em `iron_log_back_end/src/app.module.ts` com `FirebaseAuthGuard` no padrão dos outros módulos

**Checkpoint**: Banco local e remoto aceitam academia e estação; o app grava as duas offline

---

## Phase 3: User Story 1 — Marcar a máquina e ver a última carga dela (Priority: P1) 🎯 MVP

**Goal**: No treino de máquina, cabo ou Smith, a pessoa escolhe a estação e a última vez mostra só a carga daquela máquina

**Independent Test**: Registrar o mesmo movimento em “preta” (40 kg) e “da ponta” (55 kg). Ao reabrir com “preta”, a última vez mostra 40 kg. Barra não mostra chip.

### Implementation for User Story 1

- [x] T015 [P] [US1] Implementar `POST/GET /exercise-stations` em `iron_log_back_end/src/training-place/dto/create-exercise-station.dto.ts`, `iron_log_back_end/src/training-place/exercise-station.controller.ts` e `iron_log_back_end/src/training-place/training-place.service.ts` (id do cliente, apelido 1–40, unicidade normalizada, limite padrão 3, só o dono)
- [x] T016 [P] [US1] Aceitar `stationId` opcional em `iron_log_back_end/src/workout/dto/create-workout.dto.ts` e gravar o mesmo id em todas as séries daquele movimento dentro da transação já usada em `iron_log_back_end/src/workout/helpers/workout-series-builder.ts` e `iron_log_back_end/src/workout/workout.service.ts`
- [x] T017 [US1] Filtrar `getLastWorkSetsForExercise` por `stationId` opcional e devolver `otherStation` só como aviso em `iron_log_back_end/src/workout/workout.service.ts` e `iron_log_back_end/src/workout/workout.controller.ts`, conforme `contracts/training-place-api.md`
- [x] T018 [US1] Incluir o nome do equipamento no exercício retornado por `iron_log_back_end/src/session/session.service.ts`
- [x] T019 [US1] Enviar e ler estações em `iron_log/lib/features/training_place/data/datasources/training_place_remote_datasource.dart` e ligar esse datasource em `training_place_repository_impl.dart` (local primeiro)
- [x] T020 [US1] Implementar o portão `maquina` / `cabo` / `smith` (minúsculas, sem acento) em `iron_log/lib/features/training_place/domain/station_equipment_gate.dart`
- [x] T021 [US1] Acrescentar `equipmentName` e `stationId` em `iron_log/lib/features/workout_day/domain/entities/workout_exercise.dart` e preencher o equipamento em `iron_log/lib/features/workout_day/data/models/session_exercise_dto.dart`
- [x] T022 [US1] Incluir `stationId` no payload de cada exercício em `iron_log/lib/features/workout_day/data/services/workout_log_service.dart` e na montagem em `iron_log/lib/features/workout_day/presentation/providers/workout_day_provider.dart`
- [x] T023 [US1] Passar `stationId` em `fetchExerciseLastSets` de `iron_log/lib/features/workout_day/data/datasources/workout_day_remote_datasource.dart`, no repositório `workout_day_repository_impl.dart` e na chave de `iron_log/lib/features/workout_day/presentation/providers/exercise_last_sets_provider.dart`
- [x] T024 [US1] Criar a sheet com até 3 estações recentes, apelido curto e marca opcional em `iron_log/lib/features/training_place/presentation/widgets/station_picker_sheet.dart`
- [x] T025 [US1] Mostrar o chip e pré-selecionar a última estação só em execução e edição, quando o portão passar, em `iron_log/lib/features/workout_day/presentation/organisms/exercise_card.dart` (não no modo template)
- [x] T026 [US1] Ler e gravar `stationId` ao editar treino passado em `iron_log/lib/features/workout_day/data/models/workout_edit_dto.dart` e no PATCH correspondente em `iron_log_back_end/src/workout/workout.service.ts`
- [x] T027 [P] [US1] Cobrir “mesmo stationId em todas as séries” e “última vez não cruza estação” em `iron_log_back_end/src/workout/workout-station.spec.ts`
- [x] T028 [P] [US1] Cobrir o portão de equipamento em `iron_log/test/features/training_place/station_equipment_gate_test.dart`

**Checkpoint**: Quickstart manual 1 e 2 (máquina vs barra) passam sem cadastrar academia

---

## Phase 4: User Story 2 — Separar academias (Priority: P2)

**Goal**: Duas academias não misturam a estação “preta”; uma academia só não pede o lugar

**Independent Test**: Mesmo apelido e mesmo movimento em duas academias, com cargas diferentes. A última vez de uma não mostra a carga da outra. Com uma academia só, o chip de lugar não aparece.

### Implementation for User Story 2

- [x] T029 [US2] Implementar `GET/POST/PATCH /gyms` em `iron_log_back_end/src/training-place/dto/create-gym.dto.ts`, `iron_log_back_end/src/training-place/gym.controller.ts` e `training-place.service.ts` (nome 1–40, id do cliente, só o dono)
- [x] T030 [US2] Aceitar e persistir `gymId` opcional no criar/atualizar treino em `iron_log_back_end/src/workout/dto/create-workout.dto.ts` e `iron_log_back_end/src/workout/workout.service.ts`, recusando estação de outra academia
- [x] T031 [US2] Filtrar `GET /exercise-stations` por `gymId` (ausente = só estações sem lugar) em `iron_log_back_end/src/training-place/training-place.service.ts` e na listagem de `iron_log/lib/features/training_place/data/repositories/training_place_repository_impl.dart`
- [x] T032 [US2] Mostrar o chip de academia só quando existir mais de uma, lembrar a última pelo `gymId` do treino mais recente, e enviar `gymId` no payload em `iron_log/lib/features/workout_day/presentation/pages/workout_day_screen.dart` e `workout_log_service.dart`
- [x] T033 [US2] Na criação da primeira academia, pedir confirmação para vincular estações com `gymId` nulo; a segunda academia começa vazia. Fluxo em `iron_log/lib/features/training_place/presentation/widgets/gym_attach_sheet.dart` e `training-place.service.ts`
- [x] T034 [P] [US2] Cobrir unicidade do mesmo apelido na mesma academia e estações distintas em academias diferentes em `iron_log_back_end/src/training-place/training-place.service.spec.ts`

**Checkpoint**: Quickstart manual 3 e 4 passam

---

## Phase 5: User Story 3 — Sugestão de carga da máquina escolhida (Priority: P3)

**Goal**: A carga sugerida usa só o histórico da estação selecionada

**Independent Test**: Duas estações com cargas bem diferentes. A sugestão muda com a estação. Estação sem série não propõe a carga da outra.

### Implementation for User Story 3

- [x] T035 [US3] Aceitar `stationId` opcional em `iron_log_back_end/src/suggestion/suggestion.controller.ts`, filtrar as séries em `iron_log_back_end/src/suggestion/suggestion.service.ts` e acrescentar `otherStation` informativo em `iron_log_back_end/src/suggestion/dto/suggestion-result.dto.ts` (sem histórico na estação: `suggestedWeight` 0 e texto de máquina sem histórico)
- [x] T036 [US3] Enviar `stationId` e não usar `otherStation.weight` como peso inicial em `iron_log/lib/features/workout_day/data/datasources/workout_day_remote_datasource.dart`, `iron_log/lib/core/api/api_endpoints.dart` e `iron_log/lib/features/workout_day/presentation/providers/exercise_suggestion_provider.dart`
- [x] T037 [P] [US3] Cobrir estação sem série não herdar carga alheia em `iron_log_back_end/src/suggestion/suggestion.service.spec.ts`

**Checkpoint**: Quickstart manual 5 passa; sem `stationId`, a sugestão continua a regra atual

---

## Phase 6: User Story 4 — Ajustar o nome das máquinas (Priority: P2)

**Goal**: Renomear atualiza o passado; ocultar tira do picker e mantém o nome no histórico. O rascunho e o envio offline não perdem academia nem estação.

**Independent Test**: Renomear “preta” e ver o nome novo no treino antigo. Ocultar “da ponta” e vê-la sumir do picker sem sumir do histórico. Finalizar sem rede preserva as duas escolhas.

### Implementation for User Story 4

- [x] T038 [US4] Implementar `PATCH /exercise-stations/:id` com `nickname` e `archived: true` (`archivedAt`, sem delete) em `iron_log_back_end/src/training-place/exercise-station.controller.ts` e `training-place.service.ts`
- [x] T039 [US4] Oferecer renomear e ocultar na sheet em `iron_log/lib/features/training_place/presentation/widgets/station_picker_sheet.dart`, sem listar estação arquivada no picker
- [x] T040 [US4] Persistir `gymId` e `stationId` no snapshot e na retomada em `iron_log/lib/features/workout_day/data/mappers/workout_draft_snapshot_mapper.dart`
- [x] T041 [US4] Enviar academias e estações `pendingSync` antes de `flushWorkoutOutbox` em `iron_log/lib/core/sync/sync_manager.dart`, e fazer a API recusar treino cujo `stationId` ainda não existe (`iron_log_back_end/src/workout/workout.service.ts`)

**Checkpoint**: Quickstart manual 6, 7 e 8 passam

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Garantir que plano, cardio e descanso ficaram de fora

- [x] T042 Confirmar que `iron_log/lib/features/routines/presentation/widgets/session_exercise_card.dart` e o editor de sessão não ganharam seletor de estação e que `SessionExercise` segue único por movimento
- [x] T043 Confirmar que cardio e descanso não enviam `gymId` nem `stationId` a partir de `iron_log/lib/features/workout_day/` (criação de cardio e descanso)
- [x] T044 Executar os cenários de `iron_log/specs/011-gym-machine-stations/quickstart.md` (Jest da API, teste do portão e os nove passos manuais)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: pode começar já
- **Foundational (Phase 2)**: depende do Setup e bloqueia US1–US4
- **US1 (Phase 3)**: depende da Foundational; não depende das outras histórias
- **US2 (Phase 4)**: depende da Foundational e integra o chip da US1; testável com duas academias sem a sugestão nova
- **US3 (Phase 5)**: depende da US1 (`stationId` já gravado e enviado)
- **US4 (Phase 6)**: depende da US1; o vínculo da primeira academia (US2) pode já existir, mas renomear/ocultar funciona com `gymId` nulo
- **Polish**: depois das histórias desejadas

### User Story Dependencies

- **US1 (P1)**: MVP. Academia não é obrigatória
- **US2 (P2)**: usa a estação da US1 e acrescenta o lugar
- **US3 (P3)**: usa o mesmo `stationId` da US1 na sugestão
- **US4 (P2)**: ajusta estação já criada na US1 e fecha rascunho/offline

### Within Each User Story

- API do contrato antes do datasource remoto que a chama
- Entidade e payload antes do chip
- Teste da história depois do comportamento que ele cobre

### Parallel Opportunities

- T002 e T003 em paralelo
- T006 e T009/T010 em paralelo com a migration, enquanto não dependem do cliente gerado (T008 espera T006 e T007)
- T015 e T016 em paralelo (módulo de lugar vs payload de treino)
- T027 e T028 em paralelo
- T034 e T037 em arquivos de teste diferentes, depois da implementação da própria história

---

## Parallel Example: User Story 1

```bash
# Contrato de estação e campo no treino, arquivos diferentes:
Task: "T015 POST/GET /exercise-stations em iron_log_back_end/src/training-place/"
Task: "T016 stationId no DTO e nas séries em iron_log_back_end/src/workout/"

# Testes da história, depois do comportamento:
Task: "T027 workout-station.spec.ts"
Task: "T028 station_equipment_gate_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 e Phase 2
2. Phase 3 (US1)
3. Parar e validar quickstart 1 e 2
4. Só então academia, sugestão e renomear

### Incremental Delivery

1. Fundação pronta
2. US1 — máquina e última vez (MVP)
3. US2 — academias
4. US4 — renomear, ocultar, rascunho e offline (pode vir antes da US3)
5. US3 — sugestão filtrada
6. Polish e quickstart completo

### Parallel Team Strategy

1. Os dois repositórios fecham Setup + Foundational juntos
2. Depois: uma pessoa na API de estação/última vez (T015–T018) e outra no chip Flutter (T020–T025), com o contrato já escrito
3. US2 e US3 só depois do `stationId` existir no treino

---

## Notes

- Não criar exercício duplicado nem gravar estação em `SessionExercise` ou em `variation`
- `ExerciseRecord` não muda
- Estação arquivada não é apagada
- Cardinalidade: uma estação por movimento por treino
