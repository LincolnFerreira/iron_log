# Tasks: Padrão Arquitetural Flutter — Iron Log

**Input**: Design documents from `/specs/006-flutter-architecture-standard/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Incluídos pontualmente (validação `flutter test` / quickstart por checkpoint). Não é TDD estrito — refactors estruturais validados por testes existentes.

**Organization**: Tarefas agrupadas por user story (spec.md). Migração de legado (US2) segue **uma feature por PR** — nunca big bang.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefas incompletas na mesma feature)
- **[Story]**: US1–US4 conforme spec.md

## Path Conventions

- Cliente: `lib/features/`, `lib/core/`, `lib/main.dart`
- Docs: `specs/006-flutter-architecture-standard/`, `docs/architecture/`
- Testes: `test/`, `integration_test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Preparar branch e ambiente

- [x] T001 Verificar branch `006-flutter-architecture-standard` e executar `flutter pub get` na raiz `iron_log/`
- [x] T002 [P] Confirmar artefatos em `specs/006-flutter-architecture-standard/` (plan.md, spec.md, research.md, data-model.md, quickstart.md, contracts/)
- [x] T003 [P] Confirmar `.cursor/rules/specify-rules.mdc` referencia plan e contracts da feature 006

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Governança operacional + higiene core (Fase 0–1 do plan) — **bloqueia migração de pastas**

**⚠️ CRITICAL**: Nenhuma tarefa de refactor de feature (US2) começa antes desta fase

- [x] T004 Criar índice `docs/architecture/README.md` com links para `specs/006-flutter-architecture-standard/spec.md`, `plan.md` e `contracts/`
- [x] T005 [P] Criar `scripts/check_architecture.sh` com greps do `quickstart.md` (provider/bloc imports, endpoints.dart, StateNotifier em diff)
- [x] T006 Auditar símbolos únicos em `lib/core/api/endpoints.dart` e migrar faltantes para `lib/core/api/api_endpoints.dart`
- [x] T007 Converter `lib/core/api/endpoints.dart` em re-export `@Deprecated` de `api_endpoints.dart` até grep zero
- [x] T008 [P] Atualizar imports de `endpoints.dart` → `api_endpoints.dart` em `lib/core/components/exercise_search/unified_exercise_search.dart`
- [x] T009 [P] Atualizar imports de `endpoints.dart` → `api_endpoints.dart` em `lib/features/routines/presentation/widgets/create_exercise_modal.dart`
- [x] T010 [P] Atualizar demais arquivos em `lib/` que importam `endpoints.dart` (grep `api/endpoints.dart`)
- [x] T011 Remover `lib/core/api/endpoints.dart` após grep zero em `lib/` e `test/`
- [x] T012 Substituir `print` de debug em `lib/core/routes/app_router.dart` por log guardado com `kDebugMode` ou remover
- [x] T013 Executar `flutter test` e confirmar verde após T006–T012

**Checkpoint**: Core higiene OK — endpoints únicos; router sem print em release

---

## Phase 3: User Story 1 — Desenvolvedor implementa feature nova (Priority: P1) 🎯 MVP

**Goal**: Time consegue criar feature nova seguindo padrão único sem ambiguidade

**Independent Test**: Walkthrough SC-002 do `quickstart.md` — dev localiza repository, provider e page em <5 min usando só docs

### Implementation for User Story 1

- [x] T014 [US1] Adicionar seção "Como criar uma feature nova" em `docs/architecture/README.md` (árvore canônica + links `contracts/folder-structure.md`)
- [x] T015 [P] [US1] Documentar padrão `*ProvidersOverrides` em `docs/architecture/README.md` com exemplo `lib/features/routines/routine_providers.dart` + `lib/main.dart`
- [x] T016 [P] [US1] Documentar Riverpod read/watch em `docs/architecture/README.md` (resumo de `contracts/riverpod-conventions.md`)
- [x] T017 [US1] Validar walkthrough humano SC-002 documentado em `specs/006-flutter-architecture-standard/quickstart.md` §7

**Checkpoint**: US1 atendida — documentação executável para código novo; MVP da feature 006

---

## Phase 4: User Story 2 — Migrar código legado: normalização de pastas (Priority: P1)

**Goal**: Features migradas seguem árvore oficial (`presentation/` único, sem `state/`/`bloc/` na raiz)

**Independent Test**: Após cada sub-fase, `flutter test` verde; grep sem `state/`/`bloc/` na feature migrada

### 4a — Feature `home` (1 PR)

- [x] T018 [US2] Criar `lib/features/home/presentation/pages/` e mover `lib/features/home/home_page.dart` → `presentation/pages/home_page.dart`
- [x] T019 [P] [US2] Mover `lib/features/home/components/` → `lib/features/home/presentation/components/` (preservar atoms/molecules/organisms/templates)
- [x] T020 [P] [US2] Mover `lib/features/home/state/home_provider.dart` → `lib/features/home/presentation/providers/home_provider.dart`
- [x] T021 [P] [US2] Mover `lib/features/home/state/workout_calendar_provider.dart` → `presentation/providers/workout_calendar_provider.dart`
- [x] T022 [P] [US2] Mover `lib/features/home/state/workout_provider.dart` → `presentation/providers/workout_provider.dart`
- [x] T023 [P] [US2] Mover `lib/features/home/state/rest_day_toggle_provider.dart` → `presentation/providers/rest_day_toggle_provider.dart`
- [x] T024 [US2] Atualizar imports em `lib/core/routes/app_router.dart`, `lib/features/home/presentation/**` e consumidores externos de `home_page.dart`
- [x] T025 [US2] Adicionar barrel re-export temporário `lib/features/home/home_page.dart` exportando `presentation/pages/home_page.dart` (1 release) se necessário
- [x] T026 [US2] Atualizar `test/features/home/**` com novos paths; `flutter test test/features/home/`

### 4b — Feature `onboarding` (1 PR, paralelo após T018 se equipe >1)

- [x] T027 [P] [US2] Mover `lib/features/onboarding/model/` → `lib/features/onboarding/domain/entities/`
- [x] T028 [P] [US2] Mover `lib/features/onboarding/controller/` → `lib/features/onboarding/presentation/controllers/`
- [x] T029 [US2] Atualizar imports em `lib/features/onboarding/presentation/pages/` e `lib/core/routes/app_router.dart`
- [x] T030 [US2] `flutter test` — corrigir testes onboarding se existirem

### 4c — Feature `routines` (1 PR)

- [x] T031 [US2] Renomear `lib/features/routines/presentation/bloc/` → `lib/features/routines/presentation/providers/` (merge com providers existentes se duplicado)
- [x] T032 [US2] Atualizar imports de `routine_provider.dart` e `session_providers.dart` em `lib/features/routines/` e `lib/main.dart`
- [x] T033 [US2] `flutter test test/features/routines/`

### 4d — Feature `workout_creation` (1 PR)

- [x] T034 [P] [US2] Mover `lib/features/workout_creation/presentation/state/workout_creation_provider.dart` → `presentation/providers/workout_creation_provider.dart`
- [x] T035 [US2] Atualizar imports em `lib/features/workout_creation/presentation/pages/quick_workout_creation_page.dart`

### 4e — Feature `workout_day` (1 PR)

- [x] T036 [P] [US2] Mover `lib/features/workout_day/data/providers/create_activity_provider.dart` → `presentation/providers/create_activity_provider.dart`
- [x] T037 [P] [US2] Consolidar `presentation/atoms/` e `presentation/molecules/` duplicados sob `presentation/components/` (unificar estrutura atomic)
- [x] T038 [US2] Atualizar imports em `lib/features/workout_day/presentation/pages/workout_day_screen.dart` e providers relacionados
- [x] T039 [US2] `flutter test test/features/workout_day/`

**Checkpoint Fase 2 plan**: zero pastas `state/` ou `bloc/` nas features migradas

---

## Phase 5: User Story 2 — Camadas faltantes (Fase 3 do plan)

**Goal**: `settings`, `workout_history`, `auth` alinhados a domain/data/presentation

**Independent Test**: Nenhum provider em `workout_history/presentation/` chama Dio/API diretamente

### Implementation for User Story 2 (camadas)

- [x] T040 [P] [US2] Auditar `lib/features/workout_history/presentation/providers/workout_history_provider.dart` — extrair chamadas HTTP para `data/datasources/` + `domain/repositories/` se acopladas
- [x] T041 [US2] Implementar `lib/features/workout_history/data/` e `domain/` mínimos se T040 identificar gap (repository + remote datasource)
- [x] T042 [P] [US2] Reorganizar `lib/features/auth/utils/logout_utils.dart` — mover lógica de domínio para `domain/` ou manter util em `presentation/` conforme conteúdo
- [x] T043 [US2] Extrair `IronTokens` de `lib/features/settings/presentation/pages/settings_page.dart` para `lib/core/app_theme.dart` ou `lib/core/theme/iron_tokens.dart`
- [x] T044 [US2] Atualizar `settings_page.dart` para consumir tema global; remover duplicação de cores
- [x] T045 [US2] `flutter test` completo após T040–T044

**Checkpoint**: History sem Dio na presentation; settings sem tema paralelo

---

## Phase 6: User Story 2 — Navegação GoRouter workout (Fase 4 do plan)

**Goal**: `WorkoutDayScreen` no GoRouter; uma tela canônica de execução

**Independent Test**: Patrol `integration_test/workout_create_e2e_test.dart`, `workout_manual_e2e_test.dart`, `workout_edit_e2e_test.dart` verdes

### Implementation for User Story 2 (navegação)

- [x] T046 [US2] Adicionar constantes de rota workout em `lib/core/routes/route_names.dart` (`/workout/execution`, `/workout/manual`, `/workout/edit/:id`, `/workout/resume/:draftId`)
- [x] T047 [US2] Registrar rotas workout em `lib/core/routes/app_router.dart` com parsing de query/path params
- [x] T048 [US2] Estender factories em `lib/features/workout_day/presentation/pages/workout_day_screen.dart` para construir a partir de `GoRouterState`
- [x] T049 [US2] Substituir `Navigator.push` por `context.push` em `lib/features/home/presentation/pages/home_page.dart` (ou path pós-T018)
- [x] T050 [US2] Substituir `Navigator.push` por `context.push` em `lib/features/workout_history/presentation/pages/workout_history_page.dart`
- [x] T051 [US2] Marcar `@Deprecated` `lib/features/workout_day/presentation/pages/workout_session_screen.dart` e remover referências externas
- [x] T052 [US2] Atualizar `integration_test/support/steps/workout_steps.dart` e testes E2E para novas rotas se necessário
- [ ] T053 [US2] Executar Patrol nos três fluxos E2E de treino listados no `quickstart.md` §5

**Checkpoint**: Uma tela execução; E2E verde; Navigator legado removido de Home/History

---

## Phase 7: User Story 2 — Riverpod moderno + deps (Fase 5–6 do plan)

**Goal**: Observer em debug; migração gradual AsyncNotifier nos arquivos prioritários; pubspec limpo

**Independent Test**: `rg "extends StateNotifier" lib/` — apenas legado conhecido; zero novos; `pubspec.yaml` sem provider/bloc

### Implementation for User Story 2 (Riverpod)

- [x] T054 [P] [US2] Criar `lib/core/providers/app_provider_observer.dart` com `ProviderObserver` e logs em `kDebugMode`
- [x] T055 [US2] Registrar observer em `lib/main.dart` `ProviderScope(observers: ...)` quando `kDebugMode`
- [x] T056 [US2] Migrar `lib/features/auth/auth_state.dart` de `StateNotifier` para `@riverpod` `AsyncNotifier` (PR dedicado pequeno)
- [x] T057 [P] [US2] Migrar `lib/features/home/presentation/providers/home_provider.dart` para `@riverpod` `AsyncNotifier` após T020
- [x] T058 [P] [US2] Migrar `lib/features/routines/presentation/providers/routine_provider.dart` (ex-bloc) para `@riverpod` quando T031 concluído
- [x] T059 [US2] Documentar inventário restante de `StateNotifier` em `docs/architecture/README.md` (arquivos não migrados + regra "ao tocar")
- [x] T060 [US2] Remover `provider`, `bloc`, `flutter_bloc` de `pubspec.yaml` após `rg` zero em `lib/` e `test/`
- [x] T061 [US2] Executar `flutter pub get` e `flutter test` após T060

**Checkpoint**: Observer ativo; pubspec sem deps mortas; migração StateNotifier iniciada nos arquivos prioritários

---

## Phase 8: User Story 3 — Revisor valida PR (Priority: P2)

**Goal**: Checklist arquitetural obrigatório em todo PR que toca `lib/`

**Independent Test**: PR de teste contra `contracts/pr-review-checklist.md` — revisor marca itens sem ambiguidade

### Implementation for User Story 3

- [x] T062 [P] [US3] Criar `.github/pull_request_template.md` com link e cópia resumida de `specs/006-flutter-architecture-standard/contracts/pr-review-checklist.md`
- [x] T063 [US3] Adicionar job opcional em `.github/workflows/firebase.yml` ou novo workflow `architecture-check.yml` executando `scripts/check_architecture.sh` em PRs
- [x] T064 [US3] Documentar "quick reject triggers" em `docs/architecture/README.md` (espelho do contract)

**Checkpoint**: SC-006 — checklist com ≥10 itens aplicável em review

---

## Phase 9: User Story 4 — QA valida testabilidade (Priority: P2)

**Goal**: Padrões de teste documentados e helpers atualizados pós-migração

**Independent Test**: Widget test exemplo usa `getTestProviderOverrides()` com paths pós-refactor

### Implementation for User Story 4

- [x] T065 [P] [US4] Atualizar comentários e imports em `test/helpers/test_providers_setup.dart` após renomeações de providers (routines bloc→providers, home state→providers)
- [x] T066 [US4] Adicionar seção "Testes após migração arquitetural" em `specs/006-flutter-architecture-standard/quickstart.md` §4 com paths atualizados
- [x] T067 [P] [US4] Verificar `integration_test/support/test_keys.dart` — documentar convenção `e2e_*` em `docs/architecture/README.md`
- [x] T068 [US4] Executar `flutter test` e registrar resultado no PR da feature 006

**Checkpoint**: US4 — helpers e docs de teste alinhados ao novo layout

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Validação final e critérios de aceite da spec

- [x] T069 [P] Executar greps de `specs/006-flutter-architecture-standard/quickstart.md` §2 e documentar resultados
- [x] T070 Executar checklist completo `quickstart.md` §1–§8
- [x] T071 [P] Atualizar `.cursor/rules/specify-rules.mdc` se paths canônicos mudaram (ex.: `home_page` em `presentation/pages/`)
- [x] T072 Verificar SC-001 a SC-008 da spec — marcar status em `specs/006-flutter-architecture-standard/checklists/requirements.md` notas
- [x] T073 Revisar `analytics/` e `workout_session/` — adicionar `@Deprecated` ou README interno "não usar como referência" em `lib/features/analytics/` e `lib/features/workout_session/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende de Setup — **BLOQUEIA** US2 (Phases 4–7)
- **US1 (Phase 3)**: Depende de Foundational T004 (docs index); pode paralelizar com final de Phase 2
- **US2 pastas (Phase 4)**: Depende de Phase 2 completa
- **US2 camadas (Phase 5)**: Depende de Phase 4 home + workout_history estrutura mínima
- **US2 navegação (Phase 6)**: Depende de Phase 4e (workout_day) + Phase 4a (home paths)
- **US2 Riverpod (Phase 7)**: Depende de Phase 4c/4a para paths finais de providers
- **US3 (Phase 8)**: Pode iniciar após Phase 2 (checklist); CI script após T005
- **US4 (Phase 9)**: Depende das fases de migração que alteram providers (4–7)
- **Polish (Phase 10)**: Depende de fases desejadas completas (mínimo MVP = Phases 1–3)

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Phase 2 | Docs + walkthrough SC-002 |
| US2 | Phase 2 | Cada sub-fase 4a–4e é PR isolado testável |
| US3 | Phase 2 T005 opcional | Checklist em PR template |
| US4 | Phase 4+ | Helpers após paths estáveis |

### Parallel Opportunities

- **Phase 2**: T008–T010 em paralelo (arquivos diferentes)
- **Phase 4**: Sub-fases 4b, 4c, 4d podem rodar em paralelo **após** 4a ou em devs diferentes
- **Phase 4 home**: T019–T023 em paralelo (moves de arquivos distintos)
- **Phase 7**: T056–T058 em paralelo (features diferentes, PRs separados)
- **Phase 8–9**: T062–T064 paralelo a T065–T067

### Parallel Example: Phase 4 folder migration

```bash
# Dev A — home (sequencial interno T018→T026)
# Dev B — onboarding T027–T030 (após T018 ou em branch separada)
# Dev C — routines T031–T033
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1: Setup
2. Phase 2: Foundational (endpoints + router + script)
3. Phase 3: US1 (docs architecture README)
4. **STOP**: Walkthrough SC-002; time pode adotar padrão em PRs novos imediatamente

### Incremental Delivery (recomendado)

1. Setup + Foundational → core higiene
2. US1 docs → MVP governança
3. US2 Phase 4a (home) → 1 PR → `flutter test`
4. US2 Phase 4b–4e → 1 PR por feature
5. US2 Phase 5–7 → camadas, GoRouter, Riverpod gradual
6. US3 + US4 + Polish → fechamento SC

### Regras de ouro (spec)

- **Proibido**: PR único movendo todas as features
- **Proibido**: PR único convertendo todos `StateNotifier`
- **Obrigatório**: `flutter test` verde ao final de cada PR de migração
- **Obrigatório**: código novo segue `contracts/riverpod-conventions.md` imediatamente

---

## Notes

- `iron_log_back_end/` — **sem tarefas** nesta feature
- Decisões DP-01 a DP-03 resolvidas em `research.md`; DP-04 (l10n) fora de escopo
- Tarefas T056–T058 são exemplos prioritários — demais `StateNotifier` migram ao tocar arquivo (regra contínua)
- Total: **73 tarefas** | US1: 4 | US2: 48 | US3: 3 | US4: 4 | Setup+Foundational+Polish: 14

---

## Phase 11: Convergence

**Purpose**: Fechar lacunas entre tarefas marcadas `[x]` e o estado real do código após `/speckit-implement` (pastas legadas duplicadas, teste vermelho, guardrails incompletos). Fases 5–10 permanecem em aberto — esta fase cobre apenas gaps **não** rastreados por T040–T072 ou remediação de checkpoints falsamente atendidos.

- [x] T074 Remover `lib/features/home/state/` e `lib/features/home/components/` após grep zero de imports em `lib/` e `test/`; confirmar consumidores usam `presentation/providers/` e `presentation/components/` per US2/AC1 (partial)
- [x] T075 Achatar `lib/features/home/presentation/components/components/` duplicado em `presentation/components/` (árvore atomic única) e corrigir imports per AD-10 (partial)
- [x] T076 Remover `lib/features/routines/presentation/bloc/` após confirmar `presentation/providers/routine_provider.dart` como único canônico per T031 (partial)
- [x] T077 Remover cópias legadas `lib/features/workout_creation/presentation/state/` e `lib/features/workout_day/data/providers/` per T034–T036 (partial)
- [x] T078 Corrigir `test/features/routines/session_edit_page_test.dart` (overrides de repositório / sem Firebase) até `flutter test` verde — remedia T013 e T033 (contradicts)
- [x] T079 Estender `scripts/check_architecture.sh` para falhar se existirem pastas `state/`, `bloc/` ou `components/` na raiz de `lib/features/*/` (fora de `presentation/`) per quickstart §2 e US3 (partial)

---

## Phase 12: Convergence

**Purpose**: Lacunas pós-implementação da Phase 11 — tarefas abertas T053/T056–T058 permanecem; esta fase cobre gaps adicionais não rastreados.

- [x] T080 Atualizar `.cursor/rules/specify-rules.mdc` — seção Navegação MUST refletir `WorkoutRouteLocations` e rotas `/workout/*`; remover exceção obsoleta `Navigator.push` para `WorkoutDayScreen` per T071 (contradicts)
- [x] T081 Extrair chamada HTTP de `lib/features/routines/presentation/providers/routine_last_workout_provider.dart` para camada `data/` + `domain/repositories/` (espelhar padrão `workout_history` T040–T041) per Constitution II (partial)
- [x] T082 Adicionar rota GoRouter para `WorkoutSummaryScreen` e substituir `Navigator.push` em `lib/features/workout_day/presentation/controllers/workout_finish_flow.dart` per AD-04 (partial)
