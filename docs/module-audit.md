# Auditoria por Módulos — Estado Inicial

Objetivo: mapear, por módulo, quais fluxos já verifiquei, quais ainda faltam, e anotar riscos/achados imediatos para priorizarmos correções.

---

## Módulos já verificados (resumo)

- **workout_day (presentation)**
  - Arquivos lidos/ajustados:
    - [lib/features/workout_day/presentation/pages/workout_day_screen.dart](lib/features/workout_day/presentation/pages/workout_day_screen.dart#L1) — conectei `workoutControllerProvider` ao `FooterActions.isLoading` e adicionei `bool _isStartingWorkout` com `try/catch/finally` no `_handleStartWorkout()`.
    - [lib/features/workout_day/presentation/controllers/workout_controller.dart](lib/features/workout_day/presentation/controllers/workout_controller.dart#L1) — verificado que `finishWorkout()` usa `state = AsyncValue.loading()` e atualiza `state` corretamente em sucessos/erros.
    - [lib/features/workout_day/presentation/organisms/exercise_card.dart](lib/features/workout_day/presentation/organisms/exercise_card.dart#L1) — detectado uso de boolean local `_isSuggestionLoading` (comportamento esperado).
    - [lib/features/workout_day/presentation/organisms/footer_actions.dart](lib/features/workout_day/presentation/organisms/footer_actions.dart#L1) — UI já preparada para `isLoading`, mas não recebia valor (corrigido na tela).
  - Achados imediatos:
    - Fluxo `Iniciar Treino` não mostrava loading → corrigi com `_isStartingWorkout`.
    - Fluxo `Finalizar Treino` tinha provider de loading (`workoutControllerProvider`) mas não era observado na UI → corrigi.
    - Tipos de payloads (`Map<String, dynamic>`) com problemas foram explicitados em mudanças anteriores.
  - Testes/execução: apenas análise estática e execução de `flutter analyze` (ok, sem erros de compilação). Ainda não rodei testes unitários específicos deste módulo.

- **workout_controller**
  - Verificado e estático: lógica de `finishWorkout()` cobre branches `needDuration` e `needSessionSelection` e limpa providers em `clearCacheOnSuccess`.
  - Achado: comportamento de limpeza (`clearCache`) pode impactar consumidores; manter atenção se widgets esperam dados após retorno.

- **home (presentation)**
  - Arquivos lidos/inspecionados:
    - [lib/features/home/state/home_provider.dart](lib/features/home/state/home_provider.dart#L1) — provider principal que carrega `todaysRoutine`, `todaysSession` e `metrics`. Usa `isLoading` boolean no `HomeState`.
    - [lib/features/home/home_page.dart](lib/features/home/home_page.dart#L1) — consumidor do `homeProvider`, passa `isLoading` e `error` para o template.
    - [lib/features/home/components/templates/home_template.dart](lib/features/home/components/templates/home_template.dart#L1) — template que repassa `isLoading` para `TodaysWorkoutCard`.
    - [lib/features/home/components/molecules/todays_workout_card.dart](lib/features/home/components/molecules/todays_workout_card.dart#L1) — escolhe entre `WorkoutLoadingCard`, `NoWorkoutCard` ou `ActiveWorkoutCard` com base em `isLoading` / `todaysRoutine`.
    - [lib/features/home/components/molecules/active_workout_card.dart](lib/features/home/components/molecules/active_workout_card.dart#L1) — contém `StartWorkoutButton`.
    - [lib/features/home/components/atoms/start_workout_button.dart](lib/features/home/components/atoms/start_workout_button.dart#L1) — componente suporta `isLoading` visível no ícone, mas raramente recebe esse valor.
    - [lib/features/home/state/workout_provider.dart](lib/features/home/state/workout_provider.dart#L1) — provider local com `isLoading` simulado; atualmente parece não ser consumido.
  - Achados imediatos:
    - O fluxo de carregamento primário do `home` usa um padrão customizado (`HomeState.isLoading`) e é corretamente observado pelo template (`TodaysWorkoutCard` mostra `WorkoutLoadingCard`).
    - O `StartWorkoutButton` suporta `isLoading`, porém **não é passado** em `ActiveWorkoutCard` e não há ligação com o `workoutProvider`. Consequência: o botão nunca mostra spinner durante operações locais.
    - `workoutProvider` existe mas não é utilizado pelo `ActiveWorkoutCard`/`HomePage` → provavel código morto ou integração incompleta.
    - `HomeNotifier` chama `_loadTodaysWorkout()` no construtor e a `HomePage` chama `refresh()` em `addPostFrameCallback`, causando duas requisições iniciais ao backend (ineficiência / potencial chamada duplicada).
    - `HomeTemplate` recebe `error` do `homeState` mas não exibe mensagem de erro no layout; erros de rede são silenciosamente guardados em `homeState.error` sem UI explícita (risco de UX sem feedback).
    - `_getTodaysSession` usa `routine.sessions..sort(...)` que muta a lista in-place; pode causar efeitos colaterais se `Routine.sessions` for reutilizada.
  - Recomendações rápidas:
    - Passar um `isStarting` boolean ou o `workoutProvider.isLoading` para o `StartWorkoutButton` quando aplicável, ou remover `workoutProvider` se não usado.
    - Mostrar `homeState.error` claramente no `HomeTemplate` (banner ou fallback com botão `onRetryWorkout`).
    - Evitar chamadas duplicadas no startup: remova a chamada em `addPostFrameCallback` ou o `_loadTodaysWorkout()` do construtor (preferir apenas um ponto de carregamento).
    - Substituir `..sort()` por uma cópia ordenada (`List.from(routine.sessions)..sort(...)`) para evitar mutação.
    - Verificar contratos de resposta do endpoint `ApiEndpoints.routines` — casos onde `response.data` não é `List<dynamic>` podem causar cast exceptions (atualmente protegido pela try/catch, mas vale um teste de contrato).
  - Impacto: problemas encontrados são majoritariamente UX/ineficiência (loading não exibido, chamadas duplicadas, mensagens de erro escondidas). Risco funcional baixo imediato, mas melhora a robustez do fluxo do usuário.

---

## Módulos ainda não verificados (prioridade sugerida)

- **home** (`lib/features/home`) — usa `isLoading` em estado customizado; verificar integração com botões e seleção de sessão.
- **routines** (`lib/features/routines`) — similar ao `home`, usa `isLoading`; possíveis padrões inconsistentes.
- **session** (`lib/features/session`) — contém lógica de sessions/ordenção; necessário verificar seleção/edits.
- **suggestion** (`lib/features/suggestion`) — verificar chamadas AI/async e estados locais de loading (chips que pedem sugestão).
- **sync** (`lib/features/sync`) — revisar lógica offline/pendente de sincronização (potencial para estados inconsistentes).
- **user / user-profile** — auth flows e perfil; checar integrações com Firebase (tokens/UID).
- **data/services** (ex.: `workout_log_service.dart`) — verificar contratos com o backend (payloads, erros esperados).
- **backend (iron_log_back_end)** — revisar endpoints esperados (create/update workout, create WorkoutSession) quando necessário para simulações de falha de contrato.

---

## Riscos e pontos que podem quebrar (exemplos)

- Chamadas de rede que retornam erros não tratados (500, 422) podem deixar o UI sem feedback se providers não atualizarem `state` corretamente.
- Branches condicionais que demandam entrada do usuário (`needDuration`, `needSessionSelection`) dependem de flows de UI (pickers, sheets) — testar cada branch programaticamente.
- Padrões de loading inconsistentes (AsyncValue vs `isLoading` bool) podem provocar UX inconsistente e bugs sutis ao combinar módulos.
- `clearCache()` chamado após salvar/atualizar pode invalidar consumidores; precisa validar navegação/estado pós-retorno.

---

## Auditoria: `routines` (resumo)

- Arquivos lidos/inspecionados:
  - [lib/features/routines/presentation/bloc/routine_provider.dart](lib/features/routines/presentation/bloc/routine_provider.dart#L1) — `RoutineNotifier` com padrão `isLoading` em `RoutineState`; cobre `loadRoutines`, `loadRoutine`, `createRoutine`, `updateRoutine`, `deleteRoutine`.
  - [lib/features/routines/presentation/pages/routines_page.dart](lib/features/routines/presentation/pages/routines_page.dart#L1) — lista de rotinas; chama `loadRoutines()` em `initState`, `didPopNext` e `didChangeAppLifecycleState`.
  - [lib/features/routines/presentation/pages/routine_sessions_page.dart](lib/features/routines/presentation/pages/routine_sessions_page.dart#L1) — carrega `loadRoutine()` em `initState` e `didPopNext`.
  - [lib/features/routines/presentation/providers/routine_last_workout_provider.dart](lib/features/routines/presentation/providers/routine_last_workout_provider.dart#L1) — `FutureProvider.family` que busca último treino por rotina; retorna `null` em caso de erro silencioso.
  - [lib/features/routines/presentation/components/molecules/routine_card.dart](lib/features/routines/presentation/components/molecules/routine_card.dart#L1) — visual da rotina na lista.
  - [lib/features/routines/presentation/components/molecules/routine_last_workout_section.dart](lib/features/routines/presentation/components/molecules/routine_last_workout_section.dart#L1) — exibe último treino via `when` do `FutureProvider`.

- Achados imediatos:
  - O módulo usa padrão `isLoading` (bool) consistente internamente, semelhante ao `home`.
  - Muitas páginas disparam `loadRoutines()` ou `loadRoutine()` em múltiplos pontos do ciclo de vida (`initState`, `didPopNext`, `didChangeAppLifecycleState`), o que pode gerar requisições redundantes (I/O desnecessário e carga adicional no backend).
  - `routineRepositoryProvider` lança `UnimplementedError` por padrão e precisa ser overriden em `ProviderScope` — certificar-se de que os overrides são aplicados em `main.dart` e em testes.
  - `routineLastWorkoutProvider` suprime erros e retorna `null` em qualquer exceção; algumas UIs mostram spinner para `lastWorkout` enquanto outras mostram nada (UX inconsistente).
  - `RoutineCard` e componentes relacionados calculam descrições e contagens ao renderizar; se as listas forem grandes, pode impactar a renderização (pode ser otimizado com lazy calculations ou caching).

- Recomendações rápidas:
  - Consolidar pontos de carregamento: evite chamar `loadRoutines()` em vários callbacks de ciclo de vida sem debounce/guard; prefira um único disparador (ex.: initState) e atualizações explícitas quando necessário.
  - Padronizar tratamento de loading/erro para `routineLastWorkoutProvider`: mostre um placeholder de loading consistente e registre/log os erros para diagnóstico em vez de silenciá-los.
  - Considerar usar `AsyncValue` para fluxos que retornam dados remotos (como `routineLastWorkoutProvider`) para facilitar composição com a UI, ou documentar a escolha do padrão `isLoading` para todo o app.
  - Verificar e centralizar `routineRepositoryProvider` overrides para evitar regressões em testes ou builds sem ProviderScope configurado corretamente.
  - Avaliar performance de `RoutineCard` se a lista crescer muito; otimizar a computação de descrições (por exemplo, pré-processar no provider).

- Impacto: principal risco — UX inconsistente e chamadas de rede redundantes; risco funcional baixo imediato, mas oportuniade de otimização e padronização para reduzir problemas em produção e em ambientes de teste.

---

## Auditoria: `session/services` (resumo)

- Arquivos lidos/inspecionados:
  - [lib/features/workout_day/presentation/providers/workout_day_provider.dart](lib/features/workout_day/presentation/providers/workout_day_provider.dart#L1) — provider que gerencia carregamento de sessões, execução, salvamento e edição de treinos. Contém `startExecution`, `saveSessionExercises`, `loadExistingWorkout`, `updateExistingWorkout`.
  - [lib/features/workout_day/data/services/workout_log_service.dart](lib/features/workout_day/data/services/workout_log_service.dart#L1) — serviço que converte `WorkoutExercise` para o payload esperado pelo backend e expõe `saveWorkout`, `updateWorkout`, `patchDate`.
  - [lib/core/database/sessions_table.dart](lib/core/database/sessions_table.dart#L1) e [lib/core/database/session_exercises_table.dart](lib/core/database/session_exercises_table.dart#L1) — tabelas Drift com campos offline (`version`, `pendingSync`, `syncedAt`).
  - [lib/features/workout_session/domain/entities/session_exercise.dart](lib/features/workout_session/domain/entities/session_exercise.dart#L1) — entidade local usada em algumas telas relativas a histórico.

- Achados imediatos:
  - `WorkoutLogService.exerciseToDtoForTesting` (anotado `@visibleForTesting`) está sendo chamado diretamente por `updateExistingWorkout()` no provider. Usar um método marcado para testes em código de produção é um cheiro de manutenção e deve ser formalizado como API pública de conversão.
  - `saveWorkout()` não valida explicitamente `response.statusCode` antes de acessar `response.data['workoutId']`. Falhas inesperadas no backend podem produzir erros de runtime pouco informativos.
  - `saveSessionExercises()` contém um `TODO` sugerindo que o endpoint pode não existir, mas o método já faz um `PATCH` ao endpoint `/session/:id/exercises`. Se o backend não suportar este endpoint, a chamada irá falhar em runtime.
  - As tabelas locais (`Sessions`, `SessionExercises`) possuem campos de sincronização (`pendingSync`) que não são consultados aqui — isso indica dependência com o módulo `sync` que ainda precisa ser auditado para garantir consistência offline/online.
  - O provider mistura chamadas a `WorkoutLogService` e diretamente a `_httpService`/`AuthService` para operações similares (`PATCH /workout/:id`), deve-se padronizar o cliente usado para evitar diferenças de interceptors/comportamento.

- Recomendações rápidas:
  - Expor uma função pública de conversão `exerciseToDto` no `WorkoutLogService` e remover o uso de `exerciseToDtoForTesting` em produção.
  - Adicionar verificação de `response.statusCode` e tratamento de erro mais explícito em `WorkoutLogService.saveWorkout()` (try/catch, mensagens de erro padronizadas).
  - Validar com o backend se o endpoint `PATCH /session/:id/exercises` existe; caso contrário, documentar a dependência e proteger a chamada com feature flags ou tratadores de fallback.
  - Auditar o módulo `sync` (próximo) para confirmar como `pendingSync`/`version` são usados e garantir que `saveSessionExercises()` e alterações locais marquem `pendingSync` quando offline.
  - Padronizar o uso de um único client (`AuthService` ou `HttpService` via provider) para operações autenticadas em toda a camada de dados.

- Impacto: questões apontadas têm potencial para causar falhas de persistência em produção (se endpoints estiverem ausentes) e dificultar diagnósticos por falta de validação de respostas. Recomendado tratar como prioridade média antes de lançar fluxo offline/recuperação.

---

## Auditoria: `sync` (resumo)

- Arquivos lidos/inspecionados:
  - [lib/core/sync/sync_manager.dart](lib/core/sync/sync_manager.dart#L1) — orquestrador de sincronização offline-first, coleta itens com `pendingSync == true`, envia `/sync` e aplica respostas (marca itens como sincronizados).
  - [lib/core/providers/sync_providers.dart](lib/core/providers/sync_providers.dart#L1) — providers que expõem `syncManager`, `syncStatusStreamProvider`, `syncConflictsStreamProvider`, `syncStateProvider` e `pendingChangesCountProvider`.
  - [lib/core/database/*.dart] (tables) — tabelas Drift (`Routines`, `Sessions`, `SessionExercises`, `WorkoutSessions`, `SerieLogs`, `RestDays`) que definem `version`, `pendingSync` e `syncedAt` campos.

- Achados imediatos:
  - `SyncManager` implementa coleção de mudanças (`_collectPendingChanges`) e aplica marcação de sincronizado (`_markAsSynced`) corretamente, mas **não valida explicitamente o `statusCode` da resposta** antes de processar `response.data` (pode lançar em respostas inesperadas).
  - O código depende de campos `pendingSync`/`version` nas tabelas locais, porém não foram encontrados pontos no código que **marquem `pendingSync = true` ou incrementem `version`** quando modificações locais ocorrem. Sem isso, o `SyncManager` não terá itens para enviar — ou seja, o fluxo offline está incompleto.
  - `SyncManager.sync()` não roda as atualizações de `_markAsSynced` dentro de uma transação única; em falhas parciais isso pode deixar o banco em estado inconsistente.
  - `syncConflictsStreamProvider` e `syncStatusStreamProvider` existem, mas não localizei consumidores na UI que mostrem status de sync ou permitam resolução de conflitos (UX e visibilidade ausentes).
  - `SyncManager` assume formato de payload `/sync` e campos `synced`, `conflicts`, `failed` na resposta; não há validação/timeout adicional nem retry/backoff explícito para falhas de rede.

- Recomendações rápidas:
  - Implementar pontos de marcação `pendingSync = true` e incremento de `version` sempre que uma entidade for criada/atualizada/deletada localmente (providers / local data sources). Sem isso o manager não terá trabalho a fazer.
  - Validar `response.statusCode` e tratar respostas inesperadas antes de chamar `SyncResult.fromJson(response.data)`. Adicionar tratamento para timeouts e retries (exponential backoff) para operações de sync.
  - Executar `_markAsSynced` dentro de uma transação ou agrupar atualizações por entidade em blocos atômicos para evitar inconsistências parciais.
  - Adicionar um consumidor UI para `syncStatusStreamProvider` (por exemplo, um pequeno indicador no header ou nas configurações) e um fluxo para visualizar/resolver `syncConflictsStreamProvider` — atualmente conflitos são emitem, mas não há UX para resolvê-los.
  - Registrar/logar falhas de sync (`failed` list) com contexto para diagnóstico e adicionar telemetry/metrics se possível.
  - Considerar compressão/limitação do payload de `changes` e paginação quando houver muitos itens pendentes.

- Impacto: Atualmente o sistema tem a infra de sync pronta, mas faltam as integrações essenciais (marcar mudanças locais e UX de conflitos). Sem esses pontos, o modo offline não funcionará — prioritizar implementação das marcações `pendingSync/version` e a exposição do status de sync na UI.

---

## Auditoria: `workout_history` (resumo)

- Arquivos lidos:
  - [lib/features/workout_history/presentation/providers/workout_history_provider.dart](lib/features/workout_history/presentation/providers/workout_history_provider.dart#L1)
  - [lib/features/workout_history/presentation/pages/workout_history_page.dart](lib/features/workout_history/presentation/pages/workout_history_page.dart#L1)
  - [lib/features/workout_history/data/models/workout_history_dto.dart](lib/features/workout_history/data/models/workout_history_dto.dart#L1)

- Achados:
  - O módulo usa `FutureProvider`/`AsyncValue` (`workoutHistoryProvider`) e já trata estados de `loading`/`error` na UI, o que é bom para feedback ao usuário.
  - O provider faz chamada direta ao backend via `AuthService.get(ApiEndpoints.workouts)` e não utiliza o banco local nem marca `pendingSync` — portanto o histórico é sempre consultado online.
  - A ação de editar/abrir um treino historico encaminha para `WorkoutDayScreen.edit(...)`. É importante garantir que os fluxos de edição/manuais acionem marcação `pendingSync` caso seja possível salvar offline.

- Recomendações:
  - Se for necessário suportar edição offline/reenviar treinos, adicionar gravação local + `pendingSync = true` nas operações de criação/edição.
  - Mantê-lo em `AsyncValue` é coerente; quando padronizar o loading global (AsyncValue vs booleans), preferir AsyncValue para providers que retornam Future/Stream.

---

## Auditoria: `workout_creation` (resumo)

- Arquivos lidos:
  - [lib/features/workout_creation/presentation/state/workout_creation_provider.dart](lib/features/workout_creation/presentation/state/workout_creation_provider.dart#L1)
  - Vários widgets de apresentação (`reorderable_workout_list`, `add_workout_bottom_sheet`, etc.)

- Achados:
  - O módulo usa `StateNotifier` com um `isLoading` boolean (`WorkoutCreationState.isLoading`) para operações de salvar localmente/simular API calls.
  - Atualmente não há persistência local nem marcação `pendingSync`. A ação `saveWorkoutRotation()` simula chamada remota com `Future.delayed`.

- Recomendações:
  - Se `saveWorkoutRotation()` for submetido ao backend/local DB no futuro, lembre de marcar `pendingSync = true` e incrementar `version` nas tabelas locais.
  - Considerar unificar loading patterns: para fluxos que usam `StateNotifier` e executam async operations, manter `isLoading` é OK; para providers que retornam `Future`, prefira `AsyncValue`.

---

## Auditoria: `auth` (resumo)

- Arquivos lidos:
  - [lib/features/auth/auth_state.dart](lib/features/auth/auth_state.dart#L1)
  - [lib/features/auth/presentation/providers/user_profile_provider.dart](lib/features/auth/presentation/providers/user_profile_provider.dart#L1)
  - [lib/features/auth/presentation/pages/login_screen.dart](lib/features/auth/presentation/pages/login_screen.dart#L1)

- Achados:
  - O fluxo de autenticação é baseado em `FirebaseAuth` e `AuthNotifier` observa `authStateChanges()`; o estado de autenticação usa um boolean `isLoading` (padrão local).
  - A página de login usa `_isLoading` local para bloquear botões e mostra feedback via `SnackBar` em falhas.
  - Após login com Google, o app faz `http.post('/user', data: {...})` para sincronizar/criar o usuário no backend. Erros são notificados, mas não há retry, persistência local nem marcação `pendingSync` para essa operação.
  - `userProfileProvider` usa `AuthService.getUserProfile()` e retorna `null` em erro — isso é tolerante, mas oculta a causa do erro (usar logs/telemetria ajuda diagnóstico).

- Recomendações:
  - Manter `FirebaseAuth` para autenticação online; se for preciso suportar criação de conta offline, gravar o payload localmente e marcar `pendingSync = true` para criar usuário quando o dispositivo recuperar conexão.
  - Considere centralizar a experiência de retry/logging no `httpService` (ex.: exp backoff) para operações críticas como `POST /user`.
  - Expor mais contexto de erro em `userProfileProvider` (pelo menos logar o erro) para facilitar debugs sem poluir a UI.

---

## Auditoria: `exercises` (resumo)

- Arquivos lidos/inspecionados:
  - [lib/core/components/exercise_search/unified_exercise_search.dart](lib/core/components/exercise_search/unified_exercise_search.dart#L1)
  - [lib/core/api/endpoints.dart](lib/core/api/endpoints.dart#L1)
  - [lib/core/database/exercises_table.dart](lib/core/database/exercises_table.dart#L1)

- Achados:
  - A busca/unificação de exercícios (`UnifiedExerciseSearch`) faz chamadas diretas aos endpoints `GET /exercises/search` e `GET /exercises/find-or-create` via `AuthService`.
  - O componente suporta criação remota via `createExercise()` que invoca `exerciseFindOrCreate`. Em caso de falha (offline), a criação simplesmente retorna `null` e o usuário vê um `SnackBar`.
  - A tabela local `Exercises` existe no Drift com campos `version`, `pendingSync` e `syncedAt`, porém não há pontos no código que escrevam nessa tabela quando um exercício é criado pelo usuário via UI (ou que marquem `pendingSync=true`).

- Recomendações:
  - Para suportar criação offline, implementar fallback local: escrever o novo `Exercise` em `Exercises` com `pendingSync=true` e retornar imediatamente para a UI, permitindo que o `SyncManager` envie a criação quando houver conexão.
  - Caso prefira manter criação somente online, melhorar UX com mensagens/contexto e considerar um retry automático com backoff.
  - Adicionar testes para garantir que `createExercise()` se comporte de forma previsível em modo offline (fazer mock do `AuthService`).

---

## Auditoria: `workout_session` (resumo)

- Arquivos lidos:
  - [lib/features/workout_session/domain/entities/session_exercise.dart](lib/features/workout_session/domain/entities/session_exercise.dart#L1)
  - [lib/features/workout_session/presentation/molecules/molecules.dart](lib/features/workout_session/presentation/molecules/molecules.dart#L1)
  - [lib/features/workout_session/presentation/atoms/atoms.dart](lib/features/workout_session/presentation/atoms/atoms.dart#L1)

- Achados:
  - O módulo contém componentes de apresentação (`WorkoutHeader`, `TopTimerCard`, `ExerciseRow`, `WorkoutSummaryCard`) e uma entidade `SessionExercise` simples. Não há chamadas de rede nem escrita direta no banco dentro destes widgets.
  - Fluxos de mutação (ex.: adicionar série, incrementar contadores) parecem ser orquestrados por outras camadas (provavelmente `workout_day` provider/controller) — portanto este módulo está bem isolado como camada de apresentação.

- Recomendações:
  - Deixar o módulo focado em UI, mas garantir que os manipuladores (`onAddSet`, `onIncrement`) documentem claramente quais providers/notifiers invocarão para persistência/local que possa marcar `pendingSync`.
  - Se futuramente mover lógica de persistência para dentro destes componentes, seguir convenção de não colocar lógica de escrita em widgets e usar `StateNotifier`/providers para triggers de DB.

---

## Auditoria: `onboarding` (resumo)

- Arquivos lidos:
  - [lib/features/onboarding/controller/division_setup_controller.dart](lib/features/onboarding/controller/division_setup_controller.dart#L1)
  - [lib/features/onboarding/presentation/pages/frequency_setup_page.dart](lib/features/onboarding/presentation/pages/frequency_setup_page.dart#L1)
  - Vários componentes de UI (`metodology_list`, `division_organism`, `primary_button`).

- Achados:
  - O fluxo de onboarding é majoritariamente local: usa `riverpod` + controllers gerados (`@riverpod`) para manter estado transitório das telas de setup.
  - Não há persistência explícita em DB ou backend neste módulo — o `AuthNotifier.completeOnboarding()` é o ponto apropriado para gravar o status se necessário.

- Recomendações:
  - Persistir o status do onboarding em `SharedPreferences` (ou em backend) no final do fluxo, para evitar repetir onboarding em reinstalações/limpeza de app.
  - Evitar lógica de negócio pesada nos widgets; manter controllers/testes unitários para as regras de seleção de divisão/frequência.

---

## Auditoria: `settings` (resumo)

- Arquivos lidos:
  - [lib/features/settings/presentation/pages/settings_page.dart](lib/features/settings/presentation/pages/settings_page.dart#L1)

- Achados:
  - Página de `Settings` é majoritariamente UI/UX com animações e itens de configuração. Existem marcadores de funcionalidades futuras (ex.: `Backup de Dados`) sem implementação.
  - O botão de logout usa `LogoutUtils.showLogoutDialog` e o `AuthState` por trás do botão já foi auditado anteriormente.

- Recomendações:
  - Implementar `Backup de Dados` como um acionador que utilize o `SyncManager`/`syncStateProvider` ou uma chamada específica ao backend, com tratamento de estados (`isSyncing`, `lastSyncTime`).
  - Evitar colocar lógica de persistência diretamente em widgets; exponha um comando em providers para acionar backup/restore e marcar `pendingSync` quando necessário.

---

## Auditoria: `core/services` (resumo)

- Arquivos lidos:
  - [lib/core/services/http_service.dart](lib/core/services/http_service.dart#L1)
  - [lib/core/services/auth_service.dart](lib/core/services/auth_service.dart#L1)

- Achados:
  - `HttpService` centraliza a configuração do `Dio` e adiciona `AuthInterceptor`. Não há implementação de retry/backoff nem de timeout personalizado por endpoint (usa timeouts globais).
  - `AuthService` encapsula chamadas autenticadas e contains helper `getUserProfile()` que espera `{ user: {...} }` na resposta. Em caso de erro, o método captura a exceção e retorna `null` — isso é tolerante, mas reduz o contexto de erro disponível para diagnóstico.
  - Alguns componentes usam `AuthService` diretamente para chamadas via `authenticatedRequest`; outros usam `HttpService.dio` diretamente (ex.: `SyncManager`), o que espalha a responsabilidade de configuração/tratamento.

- Recomendações:
  - Adicionar políticas de retry (exponential backoff) para chamadas críticas no `HttpService` ou via um wrapper reutilizável; usar interceptors para retries ou pacotes como `dio_retry` se apropriado.
  - Padronizar o uso entre `HttpService`/`AuthService` — preferir métodos de `AuthService` para chamadas autenticadas e evitar acessar `dio` diretamente em alto nível, a menos que necessário.
  - No `getUserProfile()`, logar detalhes do erro (safely) e opcionalmente propagar uma exceção específica para os callers decidirem a UX (em vez de sempre retornar `null`).

---

## Auditoria: `core/database` (resumo)

- Arquivos lidos (amostra):
  - [lib/core/database/app_database.dart](lib/core/database/app_database.dart#L1)
  - [lib/core/database/sessions_table.dart](lib/core/database/sessions_table.dart#L1)
  - [lib/core/database/session_exercises_table.dart](lib/core/database/session_exercises_table.dart#L1)
  - [lib/core/database/workout_sessions_table.dart](lib/core/database/workout_sessions_table.dart#L1)
  - [lib/core/database/serie_logs_table.dart](lib/core/database/serie_logs_table.dart#L1)

- Achados:
  - Todas as tabelas críticas (`Routines`, `Sessions`, `SessionExercises`, `WorkoutSessions`, `SerieLogs`, `Exercises`) definem colunas de sincronização offline: `version`, `pendingSync`, `syncedAt`.
  - Apesar das colunas existentes, a auditoria não encontrou pontos claros no código que marquem `pendingSync = true` automaticamente nas operações locais de create/update/delete.
  - Operações compostas (ex.: criar `WorkoutSession` + adicionar múltiplos `SerieLogs`) não parecem envolver transações ou incrementos atômicos de `version`, o que pode levar a inconsistências parciais durante sync.

- Recomendações:
  - Implementar no nível das data sources (ou repositórios) a lógica padrão: em toda criação/atualização/remoção local, faça `version += 1` e `pendingSync = true` para as linhas afetadas.
  - Para operações compostas (ex.: gravação de sessão + séries), envolver as mudanças em uma transação Drift para garantir atomicidade e incrementar `version` de forma coerente para todas as linhas relacionadas.
  - Adicionar testes unitários que simulem falhas de rede e verifiquem se as linhas locais permanecem com `pendingSync = true` e `version` incrementado até o sync bem-sucedido.

---

## Auditoria: `core/providers` (resumo)

- Arquivos lidos:
  - [lib/core/providers/sync_providers.dart](lib/core/providers/sync_providers.dart#L1)

- Achados:
  - `syncStateProvider` cria um `SyncStateNotifier` que escuta o `syncManager.syncStatus` mas não cancela explicitamente a subscription ao ser descartado — risco de vazamento se o StateNotifier viver além do esperado.
  - `pendingChangesCountProvider` atualmente conta apenas `routines.pendingSync` — não agrega `pendingSync` de `workout_sessions`, `serie_logs`, `session_exercises`, `exercises`.
  - `syncManagerProvider` injeta `httpServiceProvider` e passa `dio.dio` diretamente; recomenda-se manter a rota autenticada centralizada via `AuthService` ou garantir que `AuthInterceptor` cubra todos os casos.

- Recomendações:
  - Alterar `SyncStateNotifier` para manter a `StreamSubscription` retornada por `listen()` e cancelá-la em `dispose()` para evitar leaks.
  - Expandir `pendingChangesCountProvider` para agregar `pendingSync` across todas as tabelas relevantes e retornar a soma total, para dar ao usuário um número representativo de mudanças pendentes.
  - Revisar se o `syncManager` deve receber `AuthService` em vez de `Dio` bruto, ou documentar claramente quando acessar `dio` diretamente é aceitável.

---

## Auditoria: `core/navigation` & `core/routes` (resumo)

- Arquivos lidos:
  - [lib/core/navigation/navigation_service.dart](lib/core/navigation/navigation_service.dart#L1)
  - [lib/core/routes/app_router.dart](lib/core/routes/app_router.dart#L1)

- Achados:
  - `NavigationService` usa `navigatorKey.currentContext` sem checagens nulas ao expor `context` e chamar `context!.pushNamed(...)` — risco de `NoSuchMethodError` se navegação for chamada antes do `MaterialApp` montar.
  - `app_router` tem lógica de `redirect` que lê `authStateProvider` e faz casts diretos de `state.extra as Routine` em várias rotas sem validação do tipo/valor, o que pode lançar `TypeError` em casos invulgares.

- Recomendações:
  - Proteger chamadas de navegação com checagem de `context != null` e expor métodos que retornem `Future` resolvendo com falha/erro controlado se o contexto ainda não estiver pronto.
  - No `app_router`, validar `state.extra` antes de cast (ex.: `if (state.extra is Routine) ... else`), e adicionar guards que mostrem uma tela de erro ou redirecionem para uma rota segura quando parâmetros estiverem faltando ou incorretos.

---

## Auditoria: `core/components/exercise_search` (resumo)

- Arquivos lidos:
  - [lib/core/components/exercise_search/unified_exercise_search.dart](lib/core/components/exercise_search/unified_exercise_search.dart#L1)

- Achados:
  - Implementação com `StateNotifier` + `Timer` para debounce e um contador `_searchCounter` para ignorar respostas antigas — solução válida e explícita para corrida de respostas.
  - O `createExercise()` usa `GET` no endpoint `exerciseFindOrCreate` e retorna `null` em falha sem log detalhado, reduzindo a observabilidade de erros.
  - A construção de sugestões (`suggestionsBuilder`) faz polling por até 2s, lendo repetidamente `exerciseSearchProvider` — isso funciona, mas é ineficiente comparado a uma abordagem reativa baseada em `Stream`/`AsyncValue`.

- Recomendações:
  - Considerar migrar para `AsyncValue` ou expor um `Stream` para as buscas, evitando loops de polling no `suggestionsBuilder`.
  - Logar/expor erros em `createExercise()` para facilitar diagnóstico; retornar uma `Result`/`Either` ou lançar exceções controladas pode melhorar UX ao tratar falhas.
  - Evitar inicializações repetidas de `AuthService()` em cada chamada; preferir injeção via providers quando possível para facilitar testes e evitar reconfigurações desnecessárias.












---

## Próximos passos sugeridos (curto prazo)

1. Rodar testes unitários e widget tests focados no fluxo completo: `Iniciar -> Executar (criar WorkoutSession) -> Finalizar`.
2. Auditar o módulo `home` (próximo) e `routines` para unificar padrão de loading.
3. Verificar `workout_log_service` e contratos com o backend (códigos de erro, formatos de payload).
4. Documentar quaisquer endpoints do backend que não suportem payloads atuais.

---

## Como reproduzir localmente (rápido)

- Análise rápida:

```bash
flutter analyze
```

- Rodar testes (se existirem):

```bash
flutter test test/features/workout_day
```

---

Se quiser, começo agora a auditoria do módulo **home** e atualizo este documento com achados por módulo.
