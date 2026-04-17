# Escopo do Projeto — Iron Log (mobile + backend)

Data: 2026-04-17

Resumo rápido
- Produto: aplicação móvel para registro e acompanhamento de treinos (Iron Log) + backend REST para persistência, autenticação e sync offline.
- Objetivo deste documento: capturar o schema de dados, descrever arquitetura dos dois repositórios e listar funcionalidades principais, riscos e próximos passos.

---

## 1) Repositórios

- `iron_log` (Flutter, client/mobile)
  - Tech: Flutter, Riverpod, Drift (SQLite), Dio, Firebase Auth, go_router.
  - Localização: [lib/](lib/) — código cliente, bancos locais em `lib/core/database`.
  - Propósito: UI móvel para criação/execução/registro de treinos, histórico, gerenciamento de rotinas e exercícios.

- `iron_log_back_end` (NestJS, server)
  - Tech: NestJS, Prisma (Postgres), Firebase Admin (auth), Swagger, RxJS.
  - Localização: `prisma/schema.prisma`, `src/` — módulos de rotina, sessão, sync, workout, user, auth.
  - Propósito: API REST para orquestrar dados, sincronização offline, regras de negócio e análises.

---

## 2) Schema (resumo — backend Prisma)

O schema principal está em `prisma/schema.prisma` (backend). Principais modelos:

- `User` / `UserProfile` — conta, perfil e preferências do usuário.
- `Exercise`, `MuscleGroup`, `Equipment` — catálogo canônico de exercícios e metadados.
- `Routine` → `Session` → `SessionExercise` (+ `SessionExerciseConfig`) — modelagem de rotinas e sessões (configuração reutilizável).
- `ExercisePreset` — presets de configuração de exercício por usuário.
- `WorkoutSession` — registro de uma sessão executada (startedAt, endedAt, métricas agregadas).
- `SerieLog` — séries realizadas (peso, repetições, RIR, notes) vinculadas a `WorkoutSession`.
- `ExerciseRecord`, `WorkoutAggregate` — caches/agregados para relatórios e PRs.
- `Device`, `ChangeLog`, `SyncQueue`, `SyncConflict` — metadados e estruturas de suporte ao fluxo offline/filas e resolução de conflitos.
- `RestDay` — dias de descanso explícitos.

Observações do schema:
- IDs usam `cuid()` (string). Relacionamentos bem definidos via chaves estrangeiras.
- Muitos modelos têm campos de sincronização: `pendingSync` (bool), `syncedAt` (DateTime?), `version` (int). Isso confirma o design offline-first.

Referência: arquivo original em `iron_log_back_end/prisma/schema.prisma`.

---

## 3) Schema local (frontend — Drift)

O cliente mantém um banco local com tabelas que espelham os modelos principais do servidor:
- `Sessions` — [lib/core/database/sessions_table.dart](lib/core/database/sessions_table.dart#L1)
- `SessionExercises` — [lib/core/database/session_exercises_table.dart](lib/core/database/session_exercises_table.dart#L1)
- `WorkoutSessions` — [lib/core/database/workout_sessions_table.dart](lib/core/database/workout_sessions_table.dart#L1)
- `SerieLogs` — [lib/core/database/serie_logs_table.dart](lib/core/database/serie_logs_table.dart#L1)

Observações:
- As tabelas Drift também incluem `version`, `pendingSync` e `syncedAt`, refletindo a intenção de sincronização local/servidor.
- Auditoria inicial (código): foram encontrados os campos nas tabelas, mas não há garantia de que todas as operações locais já marquem `pendingSync = true` nem incrementem `version` automaticamente — ponto crítico (ver recomendações).

---

## 4) Funcionalidades principais (visão geral)

- Autenticação: Firebase Auth (cliente) + validação no backend (Firebase Admin / JwtStrategy).
- Onboarding e configuração inicial (frequência, metodologia).
- Gerenciamento de rotinas: CRUD de `Routine`, sessões e exercícios de sessão (editor de sessão).
- Catálogo de exercícios: busca, criação rápida (find-or-create), presets.
- Criação rápida de treino (quick workout), e execução do dia de treino (`workout_day`): modos template / execução / edição.
- Registro de sessões: `WorkoutSession` + múltiplas `SerieLog` por exercício.
- Histórico de treinos e agregados (relatórios simples / PRs locais em `ExerciseRecord` / `WorkoutAggregate`).
- Offline-first sync: `SyncManager` no cliente que coleta `pendingSync` e envia `/sync` para backend; backend mantém `SyncQueue` / `SyncConflict` para resolução.
- Configurações e backup/export (planejado).

---

## 5) Pontos críticos e recomendações (prioridade)

1. Marcação de escritas locais (ALTA): garantir que todas as operações de create/update/delete nas data sources locais executem `version += 1` e `pendingSync = true` (especialmente para `WorkoutSession`, `SerieLog`, `SessionExercise`). Prioridade alta — sem isso, não há itens a sincronizar.
2. Atomicidade nas operações compostas (ALTA): operações que criam sessão + múltiplas séries devem ocorrer em transação Drift e atualizar `version` coerentemente, evitando inconsistências parciais se o app cair.
3. SyncManager robusto (ALTA/MEIO):
   - Validar `statusCode`/resposta do backend antes de marcar como sincronizado.
   - Executar `_markAsSynced` em transação quando possível.
   - Implementar retry/backoff em chamadas críticas (usar `dio_retry` ou interceptor customizado).
4. UX de sincronização (MÉDIO): adicionar um consumidor de `syncStatus` e um componente de resolução de `syncConflicts` (mostrar número de mudanças pendentes, último sync, conflitos ativos).
5. Contador de pendentes (MÉDIO): `pendingChangesCountProvider` deve agregar `pendingSync` através de todas as tabelas relevantes, não apenas `routines`.
6. Gerenciamento de streams (MÉDIO): `SyncStateNotifier` deve cancelar subscriptions em `dispose()` para evitar leaks.
7. Padronizar loading (MÉDIO): escolher um padrão (ex.: `AsyncValue` do Riverpod ou `isLoading` no StateNotifier) e aplicar nos providers críticos (`workout_day`, `workout_creation`, sync flows) para UX consistente.

---

## 6) Próximos passos sugeridos (executáveis)

- Curto prazo (1-2 dias):
  - Implementar marcação `pendingSync/version` nas data sources de `workout_sessions`, `serie_logs`, `session_exercises`.
  - Envolver gravação de sessão + séries em transação Drift.
  - Expandir `pendingChangesCountProvider` para refletir todas as tabelas.

- Médio prazo (semanas):
  - Desenvolver UI de status de sync e fluxo de resolução de conflitos.
  - Adicionar testes unitários e E2E que simulem perda de rede e reconciliação.
  - Revisar `SyncManager` para retries e marcação atômica de synced.

- Longo prazo:
  - Gerar inventário completo de endpoints do backend e mapear para chamadas do cliente (rota -> método cliente).
  - Considerar uma API de backup/export que permita snapshots de dados do usuário.

---

## 7) Arquivos / locais chave (onde olhar primeiro)

- Backend (NestJS)
  - `prisma/schema.prisma` — modelo de dados canonical (`iron_log_back_end/prisma/schema.prisma`).
  - `src/sync/` — lógica de sincronização (collector, processador de conflitos).
  - `src/workout/`, `src/session/`, `src/routine/` — endpoints e regras de negócio.

- Frontend (Flutter)
  - `lib/core/database/` — tabelas Drift (sessions, session_exercises, workout_sessions, serie_logs).
  - `lib/core/sync/sync_manager.dart` — orquestrador de sync cliente.
  - `lib/core/providers/sync_providers.dart` — providers expostos para UI.
  - `lib/features/workout_day/` — tela principal de execução do treino do dia.
  - `lib/core/components/exercise_search/` — busca/creação rápida de exercícios.

---

## 8) Perguntas abertas / decisões a confirmar

- Qual prioridade quer dar para flows offline vs novas features UX?
- Deseja que eu inventarie todos os endpoints do backend (controller por controller) e gere um mapa de endpoint -> client call sites?
- Quer que eu implemente o primeiro fix (marcar `pendingSync/version` em `WorkoutSessions` + `SerieLogs`) e crie testes rápidos?

---

Documento gerado automaticamente (rascunho). Posso detalhar qualquer seção sob demanda.
