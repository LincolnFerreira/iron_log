# Research: Persistência de Rascunhos de Treino

**Feature**: `005-workout-draft-persistence` | **Date**: 2026-06-22

## R1 — Modelo de persistência: tabela única vs. outbox separado

**Decision**: Nova tabela Drift `WorkoutDrafts` como fonte única de rascunhos; `WorkoutOutbox` migrada e descontinuada para novos writes (leitura/flush legado na migration, depois removida).

**Rationale**:
- Hoje `WorkoutOutbox` só cobre POST/PATCH com envelope JSON e apenas em erro de conectividade (`HttpErrorHandler.isConnectivityError`).
- A spec exige dois status (`em andamento` / `aguardando envio`), snapshot de UI e nunca apagar em falha — o outbox atual não modela isso.
- Unificar evita o usuário (e o código) distinguir “outbox” vs. “rascunho” (FR-015).

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Estender só `WorkoutOutbox` com coluna `status` | Outbox é fila de envio; snapshot de execução em andamento é conceito diferente e geraria JSON duplicado/confuso |
| Reusar `WorkoutSessions` + `SerieLogs` normalizados | `LocalWorkoutRepository` existe para voz, mas mapear `WorkoutExercise` + `TechniqueBlock` + timer exige muito glue; JSON snapshot é mais rápido e alinhado ao payload API |
| Persistir só em SharedPreferences | Sem transações, sem query por usuário/status, não atende offline-first da constituição |

---

## R2 — Formato do snapshot de execução

**Decision**: Coluna `snapshotJson` (TEXT) com schema versionado `draftSnapshotV1` serializando lista de `WorkoutExercise` (incl. `entries`, `blocks`), metadados de tela e timer.

**Rationale**:
- `WorkoutExercise.toJson()` hoje **não** inclui `entries`/`blocks` — precisamos de `WorkoutExerciseSnapshotMapper` dedicado (reuso de `fromJson` parcial + extensão).
- Um blob versionado permite evoluir sem migration destrutiva.
- O mesmo mapper gera o payload API via `WorkoutLogService.exerciseToWorkoutExerciseDto` no finalize.

**Alternatives considered**:
- Normalizar em `SerieLogs`/`TechniqueBlocks` durante execução — correto a longo prazo, mas escopo maior e SyncManager ainda incompleto para workout writes.

---

## R3 — Quando persistir (auto-save)

**Decision**: Debounce 500ms após mutações em `workoutDayExercisesProvider` enquanto `status == inProgress`; flush imediato em `startExecution`, ao sair da tela (`dispose`/`PopScope`) e antes de `finishWorkout`.

**Rationale**:
- Atende FR-004/FR-011 sem I/O a cada keystroke.
- `PopScope` na `WorkoutDayScreen` garante save ao voltar para Home sem finalizar.

**Alternatives considered**:
- Save só no background kill — insuficiente para SC-003.
- Save síncrono em cada série — risco de jank na UI de treino.

---

## R4 — Tratamento de falha de API no `WorkoutLogService`

**Decision**: Em **qualquer** `DioException` em POST/PATCH `/workout`, upsert rascunho `pendingUpload` com payload + `lastErrorCode`/`lastErrorType`; **não** rethrow sem persistir (exceto se usuário não autenticado).

**Rationale**:
- Fecha lacuna atual: 400/500 perdiam dados.
- `pendingUpload` mantém dados para reenvio quando API for corrigida.

**Alternatives considered**:
- Manter rethrow para 401 — sim, auth errors podem rethrow após persistir opcional; 401 não deve apagar rascunho existente.

---

## R5 — Home “Continuar”

**Decision**: `activeWorkoutDraftProvider` (FutureProvider por `userId`) consulta `WorkoutDrafts` com `status = inProgress` (máx. 1 por usuário, índice único). `ActiveWorkoutCard` recebe `WorkoutDraftSummary?` e renderiza `ContinueWorkoutButton` (novo átomo, espelhando `StartWorkoutButton`) quando draft existe.

**Rationale**:
- Integra no card existente sem nova rota na Home.
- `HomePage._navigateToWorkout` bifurca: se draft → `WorkoutDayScreen.resume(draftId: …)`; senão fluxo atual `create`.

**Alternatives considered**:
- Banner separado acima do card — mais intrusivo; spec pede substituir/priorizar no mesmo card.

---

## R6 — Retomada de timer

**Decision**: Persistir `timerStartedAt` (DateTime?) e `accumulatedDurationSeconds` no snapshot; ao resume, `workoutTimerProvider` restaura com `startTimer(from: timerStartedAt)` ou equivalente no notifier.

**Rationale**:
- Timer hoje é só `StateProvider<DateTime?>` em memória.
- Para treino manual (`manualDate != null`), timer pode ser null — só duração no finish.

---

## R7 — Reenvio e integração com sync

**Decision**: `WorkoutDraftSyncService.flushPendingUploads()` chamado em: app startup, `SyncManager.sync()` pré-batch, e após recuperação de rede (`connectivity_plus` se já usado no app). Sucesso → delete row; falha → manter row e atualizar `lastAttemptAt` + erro.

**Rationale**:
- Reusa padrão de `flushWorkoutOutbox` mas sem `break` que abandona fila inteira — tenta todos, para só itens com erro repetido se necessário.
- **Não** deletar payloads inválidos; marcar `status = failedValidation` + log (substitui delete silencioso do outbox).

**Alternatives considered**:
- Depender só de SyncManager `/sync` — workout POST/PATCH não passa por `/sync` hoje; manter canal dedicado.

---

## R8 — Backend

**Decision**: **Sem alterações** no `iron_log_back_end` nesta feature. Contratos permanecem POST `/workout` e PATCH `/workout/:id`.

**Rationale**:
- Rascunho é 100% cliente; servidor já aceita os payloads quando saudável.

---

## R9 — Testes

**Decision**:
- Unit: `WorkoutDraftRepository`, mapper snapshot, `WorkoutLogService` falha → draft.
- Widget: `ContinueWorkoutButton` / card com draft.
- Integration/Patrol (opcional P2): fluxo iniciar → série → kill app → continuar.

**Rationale**: Alinha constitution “testes para fluxos críticos de workout”.
