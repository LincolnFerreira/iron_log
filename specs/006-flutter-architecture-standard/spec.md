# Feature Specification: Padrão Arquitetural Flutter — Iron Log

**Feature Branch**: `006-flutter-architecture-standard`

**Created**: 2026-06-23

**Status**: Draft

**Input**: Definir padrão arquitetural e regras de organização do aplicativo Flutter Iron Log — arquitetura limpa, enxuta e pragmática, como fonte de verdade para o time, sem implementação nesta etapa.

---

## Resumo Executivo

O Iron Log adota **Clean Architecture por feature** com três camadas obrigatórias (`domain`, `data`, `presentation`), infraestrutura compartilhada em `lib/core/`, e **Riverpod** como único gerenciador de estado. O padrão oficial consolida o que já funciona em `routines` e `workout_day`, elimina divergências legadas (múltiplos pacotes de estado, pastas inconsistentes, navegação mista) e define regras explícitas para offline-first (Drift + SyncManager/Outbox), HTTP (Dio), autenticação (Firebase) e navegação (GoRouter + exceções documentadas).

**Princípio guia**: consistência global por camada/feature, não perfeição teórica. Abstrações só entram quando reduzem duplicação real ou habilitam testes; caso contrário, código direto na camada correta.

**Referências canônicas no código atual**: `lib/features/routines/`, `lib/features/workout_day/`, `lib/core/`.

**Não usar como referência**: `analytics/`, `workout_session/` (stubs), `settings/` (exceção visual local `IronTokens` até migração).

---

## User Scenarios & Testing

### User Story 1 - Desenvolvedor implementa feature nova (Priority: P1)

Como desenvolvedor do Iron Log, quero um guia arquitetural único para criar uma nova feature sem decidir estrutura arquivo a arquivo, para que o código seja previsível e revisável por qualquer membro do time.

**Why this priority**: Sem padrão único, cada PR aumenta dívida estrutural e custo de onboarding.

**Independent Test**: Um desenvolvedor consegue criar o esqueleto de uma feature fictícia (`features/example/`) seguindo apenas este documento e a constituição, sem perguntar onde colocar providers, repositórios ou páginas.

**Acceptance Scenarios**:

1. **Given** uma nova feature com persistência e API, **When** o desenvolvedor consulta a spec, **Then** sabe que MUST criar `domain/repositories`, `data/datasources`, `data/repositories`, `presentation/pages` e `presentation/providers`.
2. **Given** necessidade de estado reativo, **When** o desenvolvedor escolhe biblioteca, **Then** MUST usar apenas `flutter_riverpod` (não `provider`, não `flutter_bloc`).
3. **Given** injeção de repositório, **When** a feature sobe para produção, **Then** o provider abstrato MUST falhar sem override e a implementação MUST ser registrada em `main.dart` via `ProviderScope.overrides`.

---

### User Story 2 - Desenvolvedor migra código legado (Priority: P1)

Como mantenedor do código existente, quero um plano incremental de migração para o padrão oficial, para alinhar o legado sem parar o desenvolvimento de produto.

**Why this priority**: O app já está em produção; big bang é inviável.

**Independent Test**: Para cada módulo listado no mapa de divergências, existe uma fase de migração com critério de "done" verificável.

**Acceptance Scenarios**:

1. **Given** o módulo `home` com `components/` na raiz e `state/` fora de `presentation/`, **When** a migração da Fase 2 for concluída, **Then** a estrutura MUST espelhar `routines/presentation/`.
2. **Given** navegação imperativa para `WorkoutDayScreen`, **When** a Fase 4 for concluída, **Then** a execução de treino MUST estar registrada no GoRouter ou documentada como exceção temporária com prazo.

---

### User Story 3 - Revisor valida PR (Priority: P2)

Como revisor de código, quero uma lista de anti-padrões proibidos e convenções obrigatórias, para rejeitar PRs que aumentem inconsistência arquitetural.

**Why this priority**: O padrão só vale se for aplicado em review.

**Independent Test**: Checklist de review derivável das seções "Proibido" e "Obrigatório" cobre 100% dos conflitos detectados na análise do repositório.

**Acceptance Scenarios**:

1. **Given** um PR que importa `package:provider` ou cria `Bloc`, **When** o revisor aplica a spec, **Then** MUST solicitar refatoração para Riverpod.
2. **Given** um PR que chama Dio diretamente de um widget, **When** o revisor aplica a spec, **Then** MUST solicitar mover para datasource/repository.

---

### User Story 4 - QA valida testabilidade (Priority: P2)

Como QA/desenvolvedor de testes, quero padrões claros para unit, widget e E2E, para que novos fluxos críticos tenham cobertura previsível.

**Independent Test**: Novos testes seguem `test/helpers/test_providers_setup.dart` (unit/widget) e `integration_test/support/` (Patrol E2E).

**Acceptance Scenarios**:

1. **Given** teste widget que depende de repositório, **When** escrito conforme spec, **Then** MUST usar `ProviderScope(overrides: getTestProviderOverrides())` ou override específico.
2. **Given** fluxo E2E de treino, **When** implementado, **Then** MUST usar chaves `e2e_*` de `integration_test/support/test_keys.dart`.

---

### Edge Cases

- Feature puramente visual (sem dados): pode omitir `data/` e `domain/` se não houver regra de negócio; MUST ainda viver em `features/<nome>/presentation/`.
- Feature que só consome API sem cache local: `data/datasources` remote-only é aceitável; MUST manter interface em `domain/repositories` se houver lógica de negócio.
- Fluxo full-screen intensivo (execução de treino): exceção temporária de `Navigator.push` permitida até migração GoRouter; MUST NOT criar terceira tela de execução.
- Código gerado (`@riverpod`, Drift): arquivos `*.g.dart` MUST ficar ao lado do arquivo fonte; MUST NOT editar manualmente.

---

## Decisões Arquiteturais Principais

| # | Decisão | Escolha | Alternativas descartadas | Justificativa |
|---|---------|---------|--------------------------|---------------|
| AD-01 | Organização macro | Feature-first + Clean Architecture (3 camadas) | Layer-first global (`lib/data`, `lib/domain`); MVC simples | Features do Iron Log são coesas (rotina, treino, histórico); camadas dentro da feature isolam mudanças e espelham domínio de negócio. Layer-first dificulta ownership por módulo. |
| AD-02 | Estado | **Riverpod 3** com `@riverpod` codegen; `AsyncNotifier`/`Notifier` para lógica; `read` vs `watch` separando DI de estado | Provider; Bloc; StateNotifier em código novo; GetIt/service locator | Riverpod resolve estado **e** DI — mas são papéis distintos. Codegen + `AsyncValue.guard` é o padrão maduro 2026. Legado `StateNotifier` permanece até migração incremental ao tocar cada arquivo. |
| AD-03 | Navegação shell | **GoRouter** central em `core/routes/` | Navigator 1.0 global; auto_route | GoRouter já governa auth redirect, onboarding e rotas principais. |
| AD-04 | Navegação modal/full-screen | GoRouter para rotas estáveis; `Navigator.push` **temporário** só para fluxos full-screen não migrados (execução treino) | Tudo imperativo; tudo GoRouter agora | Migrar `WorkoutDayScreen` para GoRouter é desejável mas arriscado em big bang; exceção documentada com fase de migração. |
| AD-05 | HTTP | Dio singleton via `HttpService` + interceptors | Um Dio por feature; http package | Auth token, logging e error handling centralizados; constituição já exige. |
| AD-06 | Persistência local | Drift em `core/database/`; datasources por feature | Hive; Isar; SQL raw | Schema v4 existente, sync fields (`version`, `pendingSync`, `syncedAt`), outbox de treino. |
| AD-07 | Sync offline | `SyncManager` + `WorkoutOutbox` para treinos; repositórios cache (ex. `RoutineCachedRepositoryImpl`) | Sync ad hoc por tela | Constituição NON-NEGOTIABLE; evita perda de dados. |
| AD-08 | Auth | Firebase Auth + `AuthInterceptor` Bearer (`safeGetIdToken`) | Auth custom JWT no app | Stack atual; backend valida Firebase Admin. |
| AD-09 | Erros | `Failure`/`AppException` no domínio quando aplicável; `HttpErrorHandler` na infra; UI via `AppSnackbar` + mensagem amigável | Either/dartz obrigatório em todo lugar | Either puro em todo o app é over-engineering para o estágio atual; providers podem expor `AsyncValue` e mapear erros na presentation. |
| AD-10 | UI components | Atomic design **somente** em `presentation/` (`atoms`, `molecules`, `organisms`, `pages`, `widgets`) | Atomic na raiz da feature; sem atomic | `home/components/` na raiz é legado e causa duplicação com `presentation/components/`. |
| AD-11 | Use cases | Obrigatórios quando há regra de negócio composta ou orquestração multi-repo; opcionais para CRUD fino | Use case para toda operação | `routines/domain/usecases` justifica-se pela orquestração; provider fino pode chamar repository direto em features simples. |
| AD-12 | Endpoints | **Único arquivo canônico**: `lib/core/api/api_endpoints.dart` | `endpoints.dart` duplicado | Constituição IV; hoje há imports mistos — convergir. |

### Decisões pendentes

| ID | Tema | Opções | Recomendação provisória | Prazo sugerido |
|----|------|--------|-------------------------|----------------|
| DP-01 | Migrar `WorkoutDayScreen` para GoRouter | A) rota `/workout/:mode` com query params; B) `ShellRoute` + child | A — menor mudança de API da tela | Fase 4 da migração |
| DP-02 | Remover `provider` e `bloc` do `pubspec.yaml` | Após grep zero em `lib/` e `test/` | Remover na Fase 5 | Pós-migração estado |
| DP-03 | Consolidar `WorkoutDayScreen` vs `WorkoutSessionScreen` | Manter uma; deprecar outra | Manter `WorkoutDayScreen` (E2E, Home, Histórico) | Fase 4 |
| DP-04 | Localização formal (l10n ARB) | Inline pt-BR vs `flutter gen-l10n` | Manter inline até feature dedicada de i18n | Fora desta spec |

---

## Estrutura de Camadas e Responsabilidades

### Visão geral

```
┌─────────────────────────────────────────────────────────┐
│  presentation (UI + estado Riverpod + navegação local)   │
│  ─────────────────────────────────────────────────────  │
│  data (datasources, repositories impl, DTOs, mappers)   │
│  ─────────────────────────────────────────────────────  │
│  domain (entities, repository interfaces, use cases)    │
└─────────────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
   lib/core/ (HTTP, DB, sync, theme, router, widgets)
```

### `domain/` — regras e contratos

**Responsabilidade**: entidades de negócio puras (sem Flutter, sem Dio, sem Drift), interfaces de repositório, use cases com lógica que não pertence à UI nem à infra.

**Pode**: validações de domínio, enums de modo (`WorkoutScreenMode`, `WorkoutMode`), mappers puros domínio↔domínio.

**Não pode**: importar `package:flutter`, `dio`, `drift`, widgets, providers.

### `data/` — implementação e I/O

**Responsabilidade**: falar com mundo externo — API (via datasources remote), SQLite (datasources local), DTOs/JSON, implementações de repositório, serviços de persistência (`WorkoutLogService`).

**Pode**: mapear DTO → entity; enfileirar outbox; transações Drift.

**Não pode**: widgets; lógica de exibição; `BuildContext`.

**Anti-padrão atual**: `workout_day/data/providers/` — providers são presentation; MUST migrar para `presentation/providers/`.

### `presentation/` — UI e estado

**Responsabilidade**: páginas, widgets, providers/notifiers/controllers, fluxos de tela (`WorkoutFinishFlow`), mapeadores de UI quando específicos da view.

**Pode**: `ConsumerWidget`, `StateNotifier`, `@riverpod`, sheets, dialogs.

**Não pode**: SQL/Dio direto; MUST passar por repository/service injetado.

### `lib/core/` — infra compartilhada

| Subpasta | Responsabilidade |
|----------|------------------|
| `api/` | Endpoints canônicos |
| `services/` | `HttpService`, `AuthService`, interceptors |
| `database/` | Drift schema, tabelas, `AppDatabase` |
| `sync/` | `SyncManager`, outbox sync |
| `routes/` | GoRouter, `RouteNames`, `AppPage` |
| `providers/` | Providers globais (sync, http, db) |
| `components/` | UI reutilizável cross-feature |
| `widgets/` | Widgets utilitários (headers, fallbacks) |
| `observability/` | Crashlytics wrapper |

Features **não** duplicam infra que já existe em `core/`.

---

## Estrutura de Pastas Oficial

### Árvore padrão por feature

```
lib/features/<feature_name>/
├── <feature_name>.dart              # barrel export (opcional)
├── <feature>_providers.dart         # overrides para main.dart (se injeção)
├── domain/
│   ├── entities/
│   ├── repositories/                # interfaces abstratas
│   ├── usecases/                    # quando AD-11 aplicar
│   └── mappers/                     # opcional, puros
├── data/
│   ├── datasources/
│   │   ├── <feature>_local_datasource.dart
│   │   └── <feature>_remote_datasource.dart
│   ├── models/                      # DTOs
│   ├── mappers/
│   ├── repositories/                # *Impl
│   └── services/                    # serviços de I/O complexos (ex. workout log)
└── presentation/
    ├── pages/
    ├── providers/                   # ou controllers/ com @riverpod
    ├── widgets/                     # compostos específicos da feature
    ├── atoms/
    ├── molecules/
    ├── organisms/
    └── components/                # agrupamentos internos (opcional)
```

### Exemplo concreto — feature `routines` (referência)

```
lib/features/routines/
├── routine_providers.dart
├── session_providers.dart
├── domain/entities/routine.dart
├── domain/repositories/routine_repository.dart
├── domain/usecases/routine_usecases.dart
├── data/datasources/routine_remote_datasource.dart
├── data/repositories/routine_cached_repository_impl.dart
└── presentation/
    ├── pages/routines_page.dart
    ├── providers/session_provider.dart
    └── widgets/...
```

### `lib/` raiz

```
lib/
├── main.dart                        # Firebase, Crashlytics, ProviderScope overrides
├── app_widget.dart                  # MaterialApp.router + tema
├── firebase_options.dart
├── core/                            # infra compartilhada
└── features/                        # módulos de produto
```

### Convenções de nomenclatura

| Artefato | Padrão | Exemplo |
|----------|--------|---------|
| Feature folder | `snake_case` singular ou composto | `workout_day`, `workout_history` |
| Entity | `PascalCase` substantivo | `Routine`, `SerieLog` |
| Repository interface | `<Nome>Repository` | `RoutineRepository` |
| Repository impl | `<Nome>RepositoryImpl` ou `<Nome>CachedRepositoryImpl` | `RoutineCachedRepositoryImpl` |
| Datasource | `<Nome>LocalDataSource`, `<Nome>RemoteDataSource` | `RoutineRemoteDataSource` |
| DTO | sufixo `Dto` ou `Model` consistente por feature | `RoutineHistoryDto` |
| Provider (estado) | `<contexto>Controller` ou `<ação>Provider` declarativo | `authControllerProvider`, `workoutDayExercisesProvider` |
| Provider (DI) | `<entidade>Repository` / `<serviço>` sem sufixo genérico | `routineRepositoryProvider`, `httpServiceProvider` |
| Controller codegen | `@riverpod class X extends _$X` | `AuthController`, `WorkoutDraftController` |
| Variáveis locais | nomes **declarativos**; sem abreviações opacas | `authState`, `routineRepository` — **não** `m.`, `ref.` como nome de variável |
| Page/Screen | sufixo `Page` (preferido) ou `Screen` quando já estabelecido | `RoutinesPage`, `WorkoutDayScreen` |
| Arquivo | `snake_case.dart` espelhando classe principal | `routine_repository.dart` |
| Teste unit | espelha path `lib/` em `test/` | `test/features/routines/...` |
| E2E | `integration_test/<fluxo>_e2e_test.dart` | `workout_create_e2e_test.dart` |
| Test keys | prefixo `e2e_` | `e2e_start_workout` |

**Regra**: uma classe pública principal por arquivo; barrels (`*.dart` export) só na raiz da feature quando reduzir imports externos.

---

## Fluxo de Dados Entre Camadas

### Leitura (online com fallback offline)

```
UI (ConsumerWidget)
  → ref.watch(xxxProvider)           [presentation/providers]
    → UseCase (opcional)             [domain/usecases]
      → Repository interface         [domain/repositories]
        → RepositoryImpl             [data/repositories]
          → RemoteDataSource (Dio)   [data/datasources]
          → LocalDataSource (Drift)  [data/datasources]
            → Entity                 [domain/entities]
```

### Escrita offline-first

```
UI action
  → Notifier/Controller
    → RepositoryImpl
      1. Transação Drift (version++, pendingSync=true)
      2. Se online: RemoteDataSource
      3. Se offline: SyncManager / Outbox enqueue
    → UI atualiza via provider state / AsyncValue
```

### Autenticação no fluxo HTTP

```
AuthService (Firebase) → safeGetIdToken()
  → AuthInterceptor (core)
    → HttpService.dio
      → RemoteDataSource
```

**Proibido**: widget ou provider chamar `FirebaseAuth.instance` para token de API — usar `AuthService` / interceptor.

### Navegação e estado

- Estado de tela: Riverpod scoped à feature (`presentation/providers/`).
- Estado global (auth, router): `authStateProvider`, `routerProvider` em `core/` ou `auth/`.
- Parâmetros de rota: `GoRouterState.pathParameters` / `extra`; evitar singletons para args de navegação.
- Execução treino (legado): args via construtor `WorkoutDayScreen.create/edit/manual` até DP-01.

---

## Padrão de Estado (Riverpod)

> Base de conhecimento oficial do time. Migração do legado é **incremental** — um arquivo/feature por vez, sem big bang, para não quebrar produção.

### Regra nº1: Estado ≠ Injeção de Dependência

Riverpod resolve **ambos**, mas com APIs diferentes. Não criar providers “só porque sim”.

| Papel | O que é | Na UI / no notifier | Observar na UI? |
|-------|---------|---------------------|-----------------|
| **Estado** | Controller, lista async, fluxo de tela | `ref.watch(...)` | Sim — rebuild |
| **DI** | Repository, Dio/HttpService, datasource, use case | `ref.read(...)` | **Não** — não é estado |

**Erro comum (proibido em código novo)**: `ref.watch(routineRepositoryProvider)` na UI. Repository é dependência, não estado.

### Hierarquia de escolha (código novo — 2026)

1. **`@riverpod` + `AsyncNotifier`** (`extends _$X`, `Future<T>` / `AsyncValue<T>`) — **padrão principal** para lógica de negócio e dados async.
2. **`@riverpod` + `Notifier`** — estado síncrono mutável (carrinho, filtros locais, UI flags).
3. **`@riverpod` function + `Future<T>`** — leituras simples com cache compartilhado (equivalente a `FutureProvider` codegen).
4. **`@riverpod` function + `Stream<T>`** — streams (auth session, connectivity) quando aplicável.
5. **`.family`** — providers parametrizados (`userProvider(userId)`).
6. **Estado derivado** — `@riverpod` que faz `ref.watch` em outro provider e computa (ex.: total do carrinho); **não** duplicar no estado fonte.
7. **`Provider` manual sem codegen** — só para overrides legados (`routineRepositoryProvider`) até migrar para `@Riverpod(keepAlive: true)`.

**Não usar em código novo**: `StateNotifier`, `StateNotifierProvider`, `ChangeNotifier`, `package:provider`, GetIt, service locator, BLoC misturado.

**Legado permitido temporariamente**: `StateNotifier` existente (`AuthNotifier`, `workoutDayExercisesProvider`, etc.) — migrar para `AsyncNotifier` **somente quando o arquivo for alterado** por outra razão, ou em PR dedicado pequeno.

### Padrão AsyncNotifier (código novo)

```dart
@riverpod
class AuthController extends _$AuthController {
  @override
  Future<User?> build() async => null;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      return authRepository.login(email, password);
    });
  }
}
```

- **`AsyncValue.guard`** MUST ser o padrão para operações async em controllers novos.
- Dentro de métodos do controller: **`ref.read`** para repositories e serviços.
- Na UI: **`ref.watch(authControllerProvider)`** + `.when(loading:, error:, data:)`.

### Consumo na UI

| Necessidade | API |
|-------------|-----|
| Rebuild com estado | `ref.watch(stateProvider)` |
| Disparar ação sem rebuild | `ref.read(controllerProvider.notifier).login(...)` |
| Side-effect (snackbar, navegação) | `ref.listen` — **nunca** `AppSnackbar` / `ScaffoldMessenger` direto no `build` |
| Pegar dependência em callback | `ref.read(repositoryProvider)` |

**Side-effects**: usar `ref.listen` + `AppSnackbar` (não `ScaffoldMessenger` cru em código novo do Iron Log).

### DI: repositories e HttpService

Infra compartilhada continua em `HttpService` (constituição IV) — exposto via `httpServiceProvider`. Padrão de consumo:

```dart
// Dentro de notifier / datasource factory — sempre read
final httpService = ref.read(httpServiceProvider);
final routineRepository = ref.read(routineRepositoryProvider);
```

Codegen para repositórios novos (quando migrar):

```dart
@Riverpod(keepAlive: true)
RoutineRepository routineRepository(Ref ref) {
  return RoutineCachedRepositoryImpl(
    remote: ref.read(routineRemoteDataSourceProvider),
    // ...
  );
}
```

Providers de repositório abstrato MUST `throw UnimplementedError` até override em `main.dart` (padrão atual `routineRepositoryProvider`) — válido até migração faseada para `@Riverpod(keepAlive: true)`.

### Family, cache e autoDispose

- **Family**: parâmetros de rota/ID (`@riverpod Future<Workout> workout(Ref ref, String id)`).
- **Cache**: múltiplos `ref.watch(productsProvider)` na árvore compartilham a mesma execução — não refetch duplicado.
- **autoDispose**: padrão do codegen para telas — estado destruído ao sair da árvore.
- **`@Riverpod(keepAlive: true)`**: sessão auth, tema, configuração, providers de infra registrados no boot.

### ProviderObserver (debug)

SHOULD registrar `ProviderObserver` em `ProviderScope` quando `kDebugMode` para rastrear atualizações de providers durante desenvolvimento. Opcional em release.

### Fluxo canônico (exemplo login)

```
LoginPage
  → ref.watch(authControllerProvider)     [estado]
AuthController.login()
  → ref.read(authRepositoryProvider)      [DI]
AuthRepositoryImpl
  → ref.read(authRemoteDataSourceProvider)
  → Firebase / Dio
  → state = AsyncData(user)
  → UI reconstrói via .when()
```

### Nomenclatura declarativa

- Nomes de providers, classes e variáveis MUST ser **autoexplicativos** (`workoutDayExercises`, `routineRepository`).
- **Proibido** abreviações opacas em código novo: `m.`, `ref.` como **nome de variável**, `svc`, `repo` sem contexto.
- `WidgetRef ref` como parâmetro do Riverpod é aceitável (API do framework); o conteúdo lido deve usar nomes claros: `final routineRepository = ref.read(routineRepositoryProvider)`.

### Regras obrigatórias (resumo)

- Overrides por feature agrupados em `<feature>_providers.dart` → `*ProvidersOverrides` no `main.dart`.
- Widgets reativos MUST ser `ConsumerWidget` / `ConsumerStatefulWidget`.
- Lógica de negócio MUST NOT viver em widgets — somente em controllers/notifiers.
- Repository MUST NOT ser observado pela UI (`watch`).

### O que fazer com legado

| Legado | Ação | Urgência |
|--------|------|----------|
| `StateNotifier` / `StateNotifierProvider` | Migrar para `@riverpod` `AsyncNotifier` ao tocar o arquivo | Gradual — **não** rewrite em massa |
| `presentation/bloc/` com Riverpod | Renomear para `providers/` | Fase 2 |
| `home/state/`, `workout_creation/.../state/` | Mover para `presentation/providers/` | Fase 2 |
| `onboarding/controller/` | Alinhar a `presentation/controllers/` + codegen | Fase 2 |
| `Provider` manual para DI | Manter até PR pequeno migrar para `@riverpod(keepAlive: true)` | Gradual |
| Pacotes `provider`, `bloc` no pubspec | Não usar; remover quando zero refs | Fase 5 |

### O que NÃO usar (lista 2026)

| Proibido código novo | Substituto |
|---------------------|------------|
| `StateNotifier` | `@riverpod` `AsyncNotifier` / `Notifier` |
| `ChangeNotifier` | Riverpod notifier |
| `package:provider` | `flutter_riverpod` |
| `flutter_bloc` / BLoC | Riverpod controllers |
| GetIt / service locator | Riverpod `ref.read` |
| `ref.watch(repository)` na UI | `ref.read` no notifier; UI watch só o controller |
| Lógica de negócio no widget | Controller + repository |

---

## Padrão de API, Banco Local e Autenticação

### API (Dio)

- Único ponto de configuração: `HttpService.initialize()` em boot.
- Endpoints: `ApiEndpoints` em `api_endpoints.dart` — **proibido** adicionar em `endpoints.dart`.
- Datasources remote recebem `Dio` injetado; não instanciam `Dio()`.
- Timeouts e base URL centralizados no `HttpService`.

### Drift (offline-first)

- Schema e tabelas apenas em `core/database/`.
- Features acessam DB via datasources locais ou providers `driftDatabaseProvider`.
- Writes compostos: `database.transaction(() async { ... })`.
- Campos sync em entidades sincronizáveis: `version`, `pendingSync`, `syncedAt`.

### Autenticação

- Login UI: `features/auth/presentation/`.
- `authStateProvider` governa redirect GoRouter.
- Token para API: interceptor, sem refresh agressivo em listeners globais (constituição IV).
- Logout: `logout_utils.dart` — fluxo único; não duplicar em cada página.

---

## Padrão de Tratamento de Erros

### Camadas

| Camada | Responsabilidade |
|--------|------------------|
| Infra HTTP | `HttpErrorHandler.handleError` — log debug, mapeamento status |
| Data/Repository | Capturar `DioException`, converter para exceção de domínio ou rethrow com contexto |
| Presentation | `AsyncValue.error`, try/catch em notifiers; nunca stack trace na UI |
| UI feedback | `HttpErrorHandler.getUserFriendlyMessage()` + `AppSnackbar` |
| Fatal não tratado | `CrashReportingService` / Crashlytics em `main.dart` |
| Widget tree | `AppErrorFallback` via `ErrorWidget.builder` |

### Regras

- Mensagens ao usuário em **pt-BR**, amigáveis.
- Erros esperados (rede offline) ≠ crash; MUST mostrar estado degradado ou fila pendente.
- **Proibido**: `print` de erro em produção sem `kDebugMode` guard (router hoje viola — migrar para logger).

---

## Padrão de Navegação

### GoRouter (padrão)

- Definição: `lib/core/routes/app_router.dart`, `route_names.dart`.
- `routerProvider` como `Provider<GoRouter>` preserva instância no hot reload.
- Redirect centralizado para auth/onboarding.
- Rotas nomeadas estáveis documentadas na constituição (Mapa de Módulos).

### Imperativo (exceção temporária)

Permitido **apenas** para:

- `WorkoutDayScreen` (execução, edição, manual) — até DP-01.
- Sheets/modais locais (`showModalBottomSheet`) — OK.
- Dialogs (`showDialog`) — OK.

**Proibido**: nova feature usar `Navigator.push` para páginas de primeiro nível que deveriam estar no router.

### Serviço de navegação

`NavigationService` em `core/navigation/` — usar só quando `BuildContext` não está disponível; preferir `context.go` / `context.push` quando possível.

---

## Padrão de Testes

### Pirâmide

| Tipo | Local | Ferramenta | Foco |
|------|-------|------------|------|
| Unit | `test/` espelhando `lib/` | `flutter_test` | mappers, parsers, use cases, services |
| Widget | `test/features/...` | `flutter_test` + `ProviderScope` | páginas e componentes com mocks |
| E2E | `integration_test/` | Patrol + `integration_test` | fluxos críticos offline/sync/treino |

### Convenções

- Overrides: `test/helpers/test_providers_setup.dart` — estender ao adicionar features com injeção.
- E2E: `integration_test/support/e2e_bootstrap.dart`, fixtures, `test_keys.dart`.
- **MUST NOT** depender de rede real quando mock bastar.
- Fluxos offline/sync críticos SHOULD ter cenário documentado no plano da feature.
- Nomenclatura: `<alvo>_test.dart`.

---

## Convenções Obrigatórias

1. Toda feature com lógica de negócio MUST ter `domain/`, `data/`, `presentation/`.
2. Estado MUST ser Riverpod; widgets reativos MUST usar `Consumer*`.
3. Repositórios injetáveis via override em `main.dart`.
4. HTTP via `HttpService`; DB via Drift em `core/database/`.
5. Offline-first em entidades sincronizáveis (constituição I).
6. Endpoints apenas em `api_endpoints.dart`.
7. UI compartilhada em `core/components/` antes de criar cópia local.
8. Tema global `AppTheme` / `AppColors`; exceções MUST ser documentadas e temporárias.
9. Separação plano vs execução de treino preservada (constituição V).
10. Commits em features seguem Conventional Commits quando hooks ativos.
11. Código novo em **pt-BR** para strings de UI.
12. Um padrão de sufixo de página: preferir `Page` para código novo.

---

## Convenções Opcionais

1. Barrel file na raiz da feature (`workout_day.dart`).
2. `ProviderObserver` em debug para rastrear providers.
3. Subpasta `presentation/components/` vs flat `widgets/` — escolher um por feature e manter consistente.
4. `templates/` em atomic design para layouts de página compostos (ex. `home_template.dart`).
5. `presentation/mappers/` só quando mapping é específico de UI (não confundir com `data/mappers`).

---

## O Que É Proibido

1. **Importar ou usar `package:provider` ou `flutter_bloc` em código novo.**
2. **Instanciar `Dio()` fora de `HttpService`.**
3. **Acessar Drift/SQL diretamente de widgets ou providers de presentation** (sem datasource).
4. **Duplicar endpoints em `endpoints.dart`.**
5. **Criar terceira tela de execução de treino** sem emenda à constituição.
6. **Lógica de negócio em widgets** (cálculos de domínio, regras de sync).
7. **Navegação imperativa para rotas shell novas** (histórico, rotinas, settings).
8. **Features stub (`analytics`, `workout_session`) como template para código novo.**
9. **Tokens visuais locais** (`IronTokens` em settings) copiados para outras features.
10. **Force refresh de Firebase token em listeners globais.**
11. **Commits de versão `pubspec.yaml` fora de `scripts/release-bump.sh`.**
12. **Editar arquivos `*.g.dart` gerados manualmente.**
13. **`ref.watch` em provider de DI** (repository, HttpService, datasource) — na UI ou sem necessidade de rebuild.
14. **SnackBar / navegação como side-effect dentro de `build`** — usar `ref.listen`.
15. **Abreviações opacas** (`m.`, `svc`, `repo` sem contexto) em código novo.
16. **`StateNotifier` / `ChangeNotifier` / GetIt** em código novo.

---

## Riscos e Trade-offs

| Risco | Mitigação |
|-------|-----------|
| Migração de pastas quebra imports em massa | Uma feature por PR; usar re-exports temporários |
| Riverpod único limita quem conhece só Bloc | Documentação + exemplos em `routines`; treinamento curto |
| GoRouter para workout aumenta complexidade de params | DP-01 com rota tipada; manter factory constructors |
| Clean Architecture “de papel” (interfaces demais) | AD-11: use cases opcionais em CRUD simples |
| Atomic design excessivo em features pequenas | Atoms/molecules opcionais se < 5 widgets |
| Remover provider/bloc do pubspec quebra transitive deps | Verificar com `flutter pub deps` antes de DP-02 |

**Trade-off aceito**: não adotar `fpdart`/`Either` globalmente — `AsyncValue` + exceções tipadas bastam no estágio atual; revisitar se erros discriminados virarem dor recorrente.

**Trade-off aceito**: `Navigator.push` temporário para treino — previsibilidade de migração faseada supera pureza imediata.

---

## Plano de Migração Incremental

### Fase 0 — Governança (sem mover código)

- Aprovar esta spec e alinhar constituição `.specify/memory/constitution.md` (já alinhada em ~90%).
- Adicionar seção arquitetural em `.cursor/rules/specify-rules.mdc` via `/speckit-agent-context-update` após plano.
- PR checklist de arquitetura derivado desta spec.

**Done**: spec aprovada; time informado.

### Fase 1 — Core e higiene

- Consolidar imports para `api_endpoints.dart`; deprecar `endpoints.dart`.
- Remover `print` de debug do router em produção.
- Documentar exceções de navegação em `core/routes/README` (opcional, 1 página).

**Done**: zero imports novos em `endpoints.dart`; router sem print em release.

### Fase 2 — Normalizar presentation por feature

| Módulo | Ação |
|--------|------|
| `home` | Mover `components/` → `presentation/`; `state/` → `presentation/providers/`; `home_page.dart` → `presentation/pages/home_page.dart` |
| `onboarding` | `controller/` → `presentation/controllers/`; `model/` → `domain/entities/` |
| `workout_creation` | `presentation/state/` → `presentation/providers/` |
| `routines` | Renomear `presentation/bloc/` → `presentation/providers/` (ou merge) |
| `workout_day` | Mover `data/providers/` → `presentation/providers/`; unificar `atoms`/`molecules` duplicados sob `presentation/` |

**Done**: estrutura de cada módulo conforme árvore oficial; builds e testes passando.

### Fase 3 — Camadas faltantes

- `settings`: extrair lógica de logout/version para `domain`/`data` se crescer; migrar `IronTokens` para tema global ou `core/theme/`.
- `workout_history`: garantir `data/` + `domain/` se ainda acoplado à API na presentation.
- `auth`: alinhar `utils/` → `domain/` ou `presentation/` conforme conteúdo.

**Done**: nenhum provider de histórico chama API sem repository.

### Fase 4 — Navegação e telas duplicadas

- Registrar `WorkoutDayScreen` no GoRouter (DP-01).
- Deprecar `WorkoutSessionScreen` ou fundir (DP-03).
- Substituir `Navigator.push` de Home/History por `context.push` go_router.

**Done**: E2E Patrol passam com novas rotas; uma tela canônica de execução.

### Fase 5 — Riverpod moderno (gradual, arquivo a arquivo)

- Código **novo**: somente `@riverpod` + `AsyncNotifier`/`Notifier` + `AsyncValue.guard`.
- Código **alterado**: ao modificar um `StateNotifier` legado por outra feature/bugfix, avaliar migração no mesmo PR se o diff já toca o provider (PR pequeno, testes verdes).
- **Proibido**: PR único convertendo todos os `StateNotifier` do app.
- Adicionar `ProviderObserver` em `main.dart` quando `kDebugMode`.
- Migrar providers manuais de DI para `@Riverpod(keepAlive: true)` quando conveniente.

**Done**: zero `StateNotifier` novo; contagem de legado diminui release a release; observer ativo em debug.

### Fase 6 — Limpeza de dependências

- Remover `provider`, `bloc`, `flutter_bloc` do `pubspec.yaml` se DP-02 confirmado.
- Remover stubs não usados ou marcar `@Deprecated`.

**Done**: `pubspec` sem pacotes de estado legados; CI verde.

---

## Divergências Detectadas no Código Atual

| Local | Problema | Severidade |
|-------|----------|------------|
| `home/components/` na raiz da feature | Atomic fora de `presentation/` | Alta |
| `home/state/`, `home_page.dart` na raiz | Providers e page fora do padrão | Alta |
| `routines/presentation/bloc/` | Nome sugere Bloc; conteúdo é Riverpod | Média |
| `workout_day/data/providers/` | Providers na camada data | Alta |
| `workout_day/presentation/atoms` + `components/atoms` | Duplicação atomic | Média |
| `onboarding/controller`, `model/` | Não segue domain/presentation | Média |
| `settings/IronTokens` | Tema paralelo ao `AppTheme` | Média |
| `endpoints.dart` vs `api_endpoints.dart` | Duplicata de endpoints | Alta |
| `Navigator.push` → `WorkoutDayScreen` | Fora do GoRouter | Média (exceção temporária) |
| `WorkoutDayScreen` + `WorkoutSessionScreen` | Duas UIs de execução | Alta |
| `provider`, `bloc` no pubspec | Dependências mortas | Baixa |
| `app_router.dart` prints | Ruído e possível leak em prod | Baixa |
| `analytics/`, `workout_session/` | Stubs — risco de cópia | Média |

---

## Requirements

### Functional Requirements

- **FR-001**: O projeto MUST documentar um padrão único de camadas (`domain`, `data`, `presentation`) por feature com responsabilidades explícitas.
- **FR-002**: O projeto MUST definir estrutura de pastas oficial com exemplos e convenções de nomenclatura.
- **FR-003**: O projeto MUST adotar Riverpod 3 com `@riverpod` codegen; código novo MUST usar `AsyncNotifier`/`Notifier` (não `StateNotifier`); MUST NOT usar Provider, Bloc, GetIt nem service locator.
- **FR-003a**: UI MUST `watch` apenas providers de estado; repositories e serviços MUST ser acessados com `ref.read`.
- **FR-003b**: Side-effects (snackbar, navegação pós-ação) MUST usar `ref.listen`, não lógica no `build`.
- **FR-003c**: Migração de `StateNotifier` legado MUST ser incremental (arquivo a arquivo), sem rewrite em massa.
- **FR-004**: O projeto MUST definir fluxo de dados unidirecional UI → provider → repository → datasource.
- **FR-005**: O projeto MUST preservar padrão offline-first Drift + sync conforme constituição.
- **FR-006**: O projeto MUST centralizar HTTP em `HttpService`, auth em Firebase + interceptor, endpoints em arquivo canônico único.
- **FR-007**: O projeto MUST definir padrão de erros (infra, domínio, UI) com feedback pt-BR.
- **FR-008**: O projeto MUST definir GoRouter como navegação shell com exceções temporárias documentadas.
- **FR-009**: O projeto MUST definir padrões de teste unit/widget/E2E alinhados a `test/` e `integration_test/`.
- **FR-010**: O projeto MUST listar anti-padrões proibidos aplicáveis em code review.
- **FR-011**: O projeto MUST incluir plano de migração incremental em fases sem big bang.
- **FR-012**: O projeto MUST registrar trade-offs explícitos e decisões pendentes.
- **FR-013**: O projeto MUST identificar divergências do código atual em relação ao padrão proposto.
- **FR-014**: Repositórios injetáveis MUST seguir padrão override em `ProviderScope` no `main.dart`.

### Key Entities (governança arquitetural)

- **Feature Module**: unidade de organização em `lib/features/<nome>/` com camadas prescritas.
- **Repository Contract**: interface em `domain/`, implementação em `data/`, injeção via Riverpod.
- **Provider Override Bundle**: lista exportada (`*ProvidersOverrides`) para composição no boot.
- **Syncable Entity**: entidade com `version`, `pendingSync`, `syncedAt` no Drift.
- **Shell Route**: rota GoRouter de primeiro nível; distinta de modal/full-screen legado.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% das features ativas de produto (auth, onboarding, home, routines, workout_day, workout_history, workout_creation, settings) possuem diagrama de pastas alvo documentado nesta spec.
- **SC-002**: Desenvolvedor novo consegue localizar onde criar repository, provider e page em menos de 5 minutos usando apenas a spec (validação por walkthrough do time).
- **SC-003**: Zero PRs mergeados com novo uso de `provider` ou `bloc` após Fase 0 aprovada (verificável por grep em CI).
- **SC-004**: Após Fase 2, zero pastas `state/` ou `bloc/` em features migradas (verificável por estrutura de diretórios).
- **SC-005**: Após Fase 1, 100% dos novos endpoints adicionados apenas em `api_endpoints.dart`.
- **SC-006**: Checklist de code review arquitetural com pelo menos 10 itens derivados das seções Obrigatório/Proibido.
- **SC-007**: Plano de migração com 6 fases e critério de done por fase (este documento).
- **SC-008**: Decisões pendentes (DP-01 a DP-04) registradas com dono e fase alvo.

---

## Critérios de Aceite da Arquitetura

A arquitetura está **aprovada como fonte de verdade** quando:

1. Existe padrão único por camada (`domain`, `data`, `presentation`, `core`).
2. Existe estrutura de pastas oficial com exemplos (`routines`, `workout_day`).
3. Existe regra clara de estado (Riverpod), navegação (GoRouter + exceções), dados (repository + offline-first) e domínio (entities + interfaces).
4. Existe estratégia offline-first e integrações Firebase documentadas e alinhadas à constituição.
5. Existe plano de migração em fases sem big bang.
6. Existe lista de anti-padrões proibidos.
7. Existe inventário de divergências atuais vs padrão.
8. Trade-offs e decisões pendentes estão explícitos.
9. Success criteria SC-001 a SC-008 são verificáveis.
10. Stakeholders do time validam que a spec é suficiente para `/speckit-plan` da implementação de migração (feature separada) ou adoção imediata em PRs novos.

---

## Assumptions

- A constituição v1.2.1 permanece válida e esta spec a operacionaliza sem contradição.
- Não há reescrita do backend; contrato API permanece em `iron_log_back_end`.
- Mobile-first pt-BR; l10n formal fica para feature futura (DP-04).
- Implementação da migração será tratada em `/speckit-plan` + `/speckit-tasks` separados — **esta spec não inclui código**.
- O time aceita `WorkoutDayScreen` como tela canônica de execução até consolidação DP-03.
- Features stub não serão expandidas até adotarem o padrão completo.
