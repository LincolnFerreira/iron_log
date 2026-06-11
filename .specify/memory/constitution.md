<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0
- Modified principles: none renamed; guidance expanded in new sections
- Added sections: Mapa de Módulos; Domínio Workout (fluxos, modos, start/finish)
- Removed sections: none
- Templates: plan-template.md ✅ | specify-rules.mdc ✅ | spec-template.md ✅ | tasks-template.md ✅
- Follow-up TODOs: migrar execução de treino para go_router; unificar WorkoutDayScreen vs WorkoutSessionScreen
-->

# Iron Log Constitution

## Core Principles

### I. Offline-First e Integridade de Dados (NON-NEGOTIABLE)

Toda escrita local MUST ocorrer no Drift (SQLite) antes de depender de rede.
Operações de create/update/delete MUST incrementar `version` e marcar
`pendingSync = true` nas entidades sincronizáveis (Routine, Session,
WorkoutSession, SerieLog, SessionExercise, TechniqueBlock, RestDay).

Gravações compostas (ex.: sessão + múltiplas séries) MUST usar transação Drift
para evitar estado parcial. Sincronização MUST passar por `SyncManager`
(`lib/core/sync/sync_manager.dart`) ou outbox dedicado (`WorkoutOutbox` +
`workout_outbox_sync.dart`) para POST/PATCH de treinos.

**Rationale**: O produto promete treinar sem internet; dados perdidos ou
inconsistentes quebram a proposta central do Iron Log.

### II. Arquitetura por Feature (data / domain / presentation)

Features com lógica de negócio MUST seguir a estrutura de `routines` e
`workout_day`:

- `domain/entities`, `domain/repositories` (interfaces), `domain/usecases`,
  `domain/mappers` quando aplicável
- `data/datasources` (local Drift + remote Dio), `data/repositories`,
  `data/models`, `data/services`
- `presentation/` com atomic design (`atoms`, `molecules`, `organisms`,
  `templates`, `pages`, `widgets`) quando a UI for composta

Repositórios injetáveis MUST expor provider abstrato que falha se não
sobrescrito + implementação concreta registrada em `main.dart` via
`ProviderScope.overrides` (padrão `routineProvidersOverrides`).

**Rationale**: Separa plano (rotina/sessão) de execução (workout) e mantém
testabilidade com mocks de repositório.

### III. Estado com Riverpod

Estado de aplicação MUST usar `flutter_riverpod`. Padrões permitidos:

- `StateNotifierProvider` + `StateNotifier` para fluxos complexos
- `FutureProvider` / `.family` para dados assíncronos
- `@riverpod` codegen para controllers isolados (ex.: onboarding)

`provider` e `flutter_bloc` estão no `pubspec.yaml` mas MUST NOT ser usados
em código novo. Pastas `presentation/bloc/` podem conter notifiers Riverpod
(legado de nomenclatura).

**Rationale**: Um único padrão de estado evita divergência e simplifica testes
com `ProviderScope` overrides.

### IV. Infraestrutura Core Compartilhada

HTTP MUST usar `HttpService` (Dio singleton) com `AuthInterceptor` e
`HttpErrorHandler`. Endpoints MUST preferir `lib/core/api/api_endpoints.dart`;
novos endpoints MUST NOT adicionar duplicatas em `endpoints.dart`.

Autenticação MUST usar Firebase Auth no cliente e Bearer token via
`safeGetIdToken()` — MUST NOT forçar refresh de token em listeners globais.

UI MUST reutilizar `AppTheme`, `AppColors`, fonte Barlow e componentes em
`lib/core/components/` (`AppSnackbar`, `AppLogo`, `UnifiedExerciseSearch`,
`PageHeaderTitle`) antes de criar variantes locais.

Feedback de erro ao usuário MUST usar mensagens amigáveis de
`HttpErrorHandler.getUserFriendlyMessage()` e `AppSnackbar`.

**Rationale**: Consistência visual e de rede reduz bugs de auth offline e
fragmentação de UI.

### V. Escopo de Produto e Registro Fino

O Iron Log registra treinos série a série (peso, reps, RIR, labels, kg/lb).
O modelo de domínio MUST preservar a separação **Rotina → Sessão (plano) →
WorkoutSession (execução) → SerieLog**.

Fora de escopo (MUST NOT implementar sem emenda desta constituição):

- Vídeos ou imagens de técnica/execução de exercícios
- Rede social, feed ou competição entre usuários
- Nutrição completa, wearables, periodização automática
- Versão web (mobile-first)

Catálogo de exercícios MUST funcionar com texto, ícones por grupo muscular
(`assets/type-muscles/`) e metadados — sem dependência de mídia de movimento.

**Rationale**: Limites de produto documentados no README evitam scope creep e
mantêm foco em histórico confiável de treino.

### VI. Testes e Qualidade

Testes unitários/widget MUST usar `flutter_test` em `test/` com overrides via
`getTestProviderOverrides()` quando providers forem necessários.

E2E MUST usar Patrol (`integration_test/`) com chaves estáveis (`*TestKeys`,
prefixo `e2e_*`). Testes MUST NOT depender de rede real quando mocks forem
suficientes.

Novos fluxos críticos offline/sync SHOULD incluir cenário sem conectividade ou
fila pendente documentado no plano da feature.

**Rationale**: Sync e execução de treino são fluxos de alto risco; testes
estruturados protegem regressões.

## Stack e Repositórios

| Repositório | Papel | Stack principal |
|-------------|-------|-----------------|
| `iron_log` (este) | App Flutter — UI, Drift local, sync cliente | Flutter 3.8+, Dart ^3.8, Riverpod, go_router, Drift, Dio, Firebase Auth/Crashlytics |
| `iron_log_back_end` | API REST — persistência, regras, catálogo | NestJS, TypeScript, Prisma/PostgreSQL, Firebase Admin, Swagger |

Schema canônico de dados: `iron_log_back_end/prisma/schema.prisma`.
Espelho local: `lib/core/database/` (Drift, schema v4).

Navegação shell: `go_router` em `lib/core/routes/app_router.dart`.
Execução de treino usa `Navigator.push` imperativo (fora do router) até
migração planejada.

Localização: strings em português (pt-BR) inline até introdução formal de l10n.

Documentação de referência: `README.md`, `docs/project-scope.md`.

## Mapa de Módulos

Visão dos módulos ativos em `lib/features/` e papel de cada um.

| Módulo | Caminho | Responsabilidade | Camadas / notas |
|--------|---------|------------------|-----------------|
| **auth** | `features/auth/` | Splash, login (Google/email), `AuthNotifier`, perfil | `domain/`, `presentation/`; `authStateProvider` governa redirect do router |
| **onboarding** | `features/onboarding/` | Frequência e metodologia inicial | `controller/` com `@riverpod`; rotas `/onboarding`, `/methodology` |
| **home** | `features/home/` | Dashboard: rotina/sessão do dia, métricas, calendário, streak | `components/` (atomic), `state/home_provider.dart`; ponto de **start** do treino ao vivo |
| **routines** | `features/routines/` | CRUD rotinas, sessões, editor, busca exercícios | Referência **data/domain/presentation**; cache offline via `RoutineCachedRepositoryImpl` |
| **workout_day** | `features/workout_day/` | Execução, registro série a série, voz, técnicas, timer, summary | Módulo central de **execução**; ver seção Domínio Workout |
| **workout_history** | `features/workout_history/` | Listagem, filtros, detalhe, edição e registro retroativo | Abre `WorkoutDayScreen.edit` / `.manual` via `Navigator` |
| **workout_creation** | `features/workout_creation/` | Treino rápido — reordenar split semanal | Rota `/workout/quick-create`; UI de rotação, não execução completa |
| **settings** | `features/settings/` | Preferências, logout, versão | `IronTokens` visual local (exceção ao tema global) |
| **analytics** | `features/analytics/` | Stub — gráfico evolução | MUST NOT usar como referência |
| **workout_session** | `features/workout_session/` | Stub legado | MUST NOT usar como referência |

### Core (`lib/core/`)

| Área | Módulos-chave |
|------|---------------|
| API | `api/api_endpoints.dart`, `services/http_service.dart`, `auth_interceptor.dart` |
| DB | `database/app_database.dart`, tabelas `*_table.dart` |
| Sync | `sync/sync_manager.dart`, `sync/workout_outbox_sync.dart`, `providers/sync_providers.dart` |
| UI | `app_theme.dart`, `app_colors.dart`, `components/`, `widgets/` |
| Rotas | `routes/app_router.dart`, `app_page.dart`, `route_names.dart` |

### Rotas go_router registradas

| Rota | Tela | Domínio |
|------|------|---------|
| `/`, `/login` | Splash / Login | auth |
| `/onboarding`, `/methodology` | Setup inicial | onboarding |
| `/home` | Dashboard | home |
| `/routines` | Lista rotinas | routines |
| `/routines/:id/edit` | Sessões da rotina | routines |
| `/routines/:routineId/sessions/new` | Nova sessão | routines → `SessionEditorPage` |
| `/routines/:routineId/sessions/:sessionId` | Editar sessão (plano) | routines → `SessionEditorPage` |
| `/workout/quick-create` | Rotação rápida | workout_creation |
| `/cardio-creation` | Registrar cardio | workout_day → `CardioCreationPage` |
| `/history` | Histórico | workout_history |
| `/settings` | Configurações | settings |

**Fora do go_router (imperativo):** `WorkoutDayScreen` (execução/edição/registro),
aberta de Home ou Histórico via `MaterialPageRoute`.

## Domínio Workout

Seção canônica sobre plano vs execução, modos operacionais e ciclo de vida.

### Modelo de dados (plano vs execução)

```
Routine (rotina do usuário)
 └── Session (template do dia — ex.: Push)
      └── SessionExercise (+ config opcional)
           └── plano reutilizável, editado em SessionEditorPage

WorkoutSession (execução real — startedAt/endedAt)
 └── SerieLog / entries por exercício
      └── log do que foi feito; NÃO altera o template ao remover em execution
```

Atividades não-musculação usam o mesmo endpoint de criação com `type` distinto:

- **cardio** — `CardioCreationPage` → `createActivityProvider` → POST workout
- **rest** — calendário Home → `CreateRestDayDto` → POST `/rest-day`

### Dois enums de modo (NÃO confundir)

| Enum | Arquivo | Propósito |
|------|---------|-----------|
| `WorkoutScreenMode` | `workout_day/domain/enums/workout_screen_mode.dart` | Comportamento da **UI e persistência por ação** (`template`, `execution`, `editing`) |
| `WorkoutMode` | `workout_day/domain/workout_mode.dart` | Comportamento do **finish** (`create`, `manual`, `edit`) |

**WorkoutScreenMode** — definido em `_determineMode()` (`workout_day_screen.dart`):

| Modo | Condição de entrada | Persistência típica |
|------|---------------------|---------------------|
| `template` | Sem `workoutId`, sem `manualDate`, sem par routine+session | Altera plano da Session (API session) |
| `execution` | `routineId`+`sessionId` (ao vivo) OU `manualDate` (retroativo) | Cria/atualiza `WorkoutSession`; séries em memória até finish |
| `editing` | `workoutId` definido | PATCH em `WorkoutSession` existente |

**WorkoutMode** — resolvido em `WorkoutFinishFlow.resolveMode()`:

| Modo | Condição | Finish |
|------|----------|--------|
| `create` | Treino ao vivo (sem `workoutId`, sem `manualDate`) | POST ou PATCH se já existe `workoutSessionId` do start |
| `manual` | `manualDate` definido | POST com `isManual: true`; exige duração (picker) |
| `edit` | `workoutId` definido | PATCH via `updateWorkout` |

Provider central de exercícios: `workoutDayExercisesProvider`
(`presentation/providers/workout_day_provider.dart`). Métodos MUST respeitar
`workoutScreenModeProvider`:

- `updateExerciseTemplate` — só `template`
- `updateExerciseExecution` — só `execution`
- `updateExerciseLog` — só `editing`
- `removeExerciseFromSession` — ramifica por modo (API session / PATCH workout / só memória)

### Ramificações de entrada (como o usuário chega ao treino)

```
Home — "Iniciar treino"
  → SessionPickerSheet (se rotina com >1 sessão)
  → WorkoutDayScreen.create(routineId, sessionId)
  → modo execution, timer ao vivo

Histórico — "Registrar treino passado"
  → date picker (até ontem)
  → SessionPickerSheet (opcional)
  → WorkoutDayScreen.manual(manualDate, …)
  → modo execution, SEM timer; duração no finish

Histórico — editar treino existente
  → WorkoutDayScreen.edit(workoutId, …)
  → modo editing, carrega loadExistingWorkout()

Rotinas — SessionEditorPage
  → edita plano da sessão (nome, exercícios, ordem)
  → NÃO usa WorkoutDayScreen; persiste via session providers/API

Cardio — calendário ou rota /cardio-creation
  → CardioCreationPage → createActivityProvider (type: cardio)

Descanso — mini calendário Home
  → RestDayCreationSheet / toggle → POST /rest-day
```

### Ciclo de vida: Start (Iniciar treino)

Fluxo em `WorkoutDayScreen._handleStartWorkout()`:

1. UI: `_workoutStarted = true`; botão `e2e_start_workout` (`WorkoutTestKeys`)
2. Se `sessionId` presente e modo `execution`:
   - `workoutDayExercisesProvider.startExecution()` → `WorkoutLogService.saveWorkout()`
   - Cria `WorkoutSession` no backend (POST `/workout`) com `endedAt` provisório
   - Armazena `workoutSessionIdProvider` para recovery pós-crash
   - Offline no start: `skipOutboxEnqueueOnUnreachable: true` → id `local_…`
3. Se treino **ao vivo** (`manualDate == null`): `WorkoutController.startWorkout()`
   → `workoutTimerProvider.startTimer()`
4. Treino **manual/retroativo**: timer NÃO inicia; duração informada no finish
5. Após start: FAB de voz habilitado; `FooterActions` registra séries (peso/reps)

**Regra**: `startExecution()` MUST NOT ser chamado fora de `WorkoutScreenMode.execution`.

### Ciclo de vida: Execução (durante o treino)

| Funcionalidade | Onde |
|----------------|------|
| Registro série a série | `FooterActions` + `ExerciseCard` |
| Labels (aquecimento, top set) | `SeriesEntry`, `ExerciseTag` |
| Técnicas (cluster, etc.) | `domain/entities/technique_block.dart`, widgets em `presentation/widgets/technique/` |
| Entrada por voz | `VoiceInputBottomSheet`, `voice_to_workout_parser.dart` |
| Sugestão de carga (IA) | `exercise_suggestion_provider.dart`, endpoint `/suggestion` |
| Reordenar / adicionar exercício | `AddExerciseBottomSheet`, `ReorderableExercisesList` |
| Histórico do exercício | `exercise_last_sets_provider`, chips/modal |

Em `execution`, remover exercício afeta **apenas a execução em memória**, não o
template da Session.

### Ciclo de vida: Finish (Finalizar treino)

Orquestração: `WorkoutFinishFlow.run()` → `WorkoutController.finishWorkout()`.

1. **Manual**: se `selectedDate != null` e sem duração → `pickDuration()` dialog
2. **Edit**: exige `workoutId` e `sessionId`; PATCH `updateWorkout`
3. **Create/live**:
   - Se `workoutSessionId` válido (criado no start) → PATCH final
   - Senão → POST `saveWorkout` (enfileira outbox se offline)
4. Antes do save (modos create/manual): `saveSessionExercises(sessionId)` opcional
5. Sucesso → `WorkoutSummaryScreen`; providers limpos se `clearCacheOnSuccess`

Persistência: `WorkoutLogService` (`data/services/workout_log_service.dart`).

- POST/PATCH `/workout` com exercícios, `techniqueBlocks`, RIR, restSeconds
- Offline no finish: enfileira em `WorkoutOutbox` (exceto start com skip outbox)

### Telas de execução (duas UIs)

| Tela | Status | Uso |
|------|--------|-----|
| `WorkoutDayScreen` | **Canônica hoje** | Home, Histórico, E2E Patrol |
| `WorkoutSessionScreen` | Alternativa search-first | Exportada em `workout_day.dart`; mesma lógica de lifecycle |

Novas features de execução MUST estender `WorkoutDayScreen` ou consolidar nas
duas telas explicitamente — MUST NOT criar terceira tela sem emenda.

### Providers e serviços workout (referência rápida)

| Provider / serviço | Papel |
|--------------------|-------|
| `workoutDayExercisesProvider` | Lista de exercícios, load/save por modo |
| `workoutScreenModeProvider` | Modo UI atual |
| `workoutSessionIdProvider` | ID da sessão criada no start |
| `workoutTimerProvider` | Timer ao vivo |
| `workoutControllerProvider` | start/finish |
| `workoutLogServiceProvider` | POST/PATCH backend + outbox |
| `voiceInputProvider` | Pipeline STT → parser → preview |

## Componentes e Padrões Incorporados

Componentes core reutilizáveis (MUST preferir antes de duplicar):

| Componente | Caminho | Uso |
|------------|---------|-----|
| Busca unificada de exercícios | `lib/core/components/exercise_search/` | Debounce, API, find-or-create |
| Snackbar | `lib/core/components/app_snackbar.dart` | success / warning / error |
| Logo | `lib/core/components/app_logo.dart` | Branding |
| Título de página | `lib/core/widgets/page_header_title.dart` | AppBar two-line |
| Sync | `lib/core/sync/sync_manager.dart` | POST `/sync`, conflitos |
| Outbox de treino | `lib/core/database/workout_outbox_table.dart` | Fila POST/PATCH workout |
| Repositório cache | `RoutineCachedRepositoryImpl` | Online fetch + fallback offline |
| Session picker | `home/components/organisms/session_picker_sheet.dart` | Escolha de sessão multi-split |
| Footer de execução | `workout_day/presentation/organisms/footer_actions.dart` | Start, séries, finish |

Padrões de dados sync: campos `version`, `pendingSync`, `syncedAt` em tabelas
Drift; `cachedRoutineJson` para snapshot offline de rotinas.

## Fluxo de Desenvolvimento

1. **Especificação** (`/speckit-specify`) — user stories independentes; fluxos
   workout MUST declarar modo (`WorkoutScreenMode` / `WorkoutMode`) e entrada.
2. **Plano** (`/speckit-plan`) — Constitution Check inclui offline-first, camadas,
   escopo e impacto em start/finish/outbox quando touch em `workout_day`.
3. **Tasks** — paths em `lib/features/workout_day/` para execução; `routines/`
   para plano; `core/sync` para fila.
4. **Implementação** — diff mínimo; MUST NOT quebrar separação plano/execução.
5. **Review** — validar ramificação por modo, `pendingSync`, test keys E2E.

Branches de feature MUST seguir convenção Spec Kit (extensão git). Commits
somente quando solicitados pelo usuário ou hooks opcionais.

## Governance

Esta constituição supersede práticas ad hoc e MUST ser verificada em todo
`/speckit-plan` (Constitution Check) e revisão de PR.

**Emendas**: documentar mudança, bump de versão semântica, propagar para
`.specify/templates/` e `.cursor/rules/specify-rules.mdc` (seção SPECKIT).

**Versionamento da constituição**:

- MAJOR: remoção ou redefinição incompatível de princípio
- MINOR: novo princípio ou seção material
- PATCH: clarificações e correções de redação

**Compliance**: complexidade extra (nova tela de execução, novo enum de modo,
endpoint duplicado) MUST ser justificada na tabela Complexity Tracking do plano.

Orientação runtime para agentes: `.cursor/rules/specify-rules.mdc` e plano
ativo em `specs/<feature>/plan.md`.

**Version**: 1.1.0 | **Ratified**: 2026-06-11 | **Last Amended**: 2026-06-11
