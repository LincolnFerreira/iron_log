# Contract: Remediation slices (008)

**Purpose**: Definir o que cada fatia de PR MUST entregar para a feature 008.  
**Related**: [spec.md](../spec.md), [research.md](../research.md), 006 `contracts/pr-review-checklist.md`

## Slice rules (all PRs)

1. Prefer **one feature** (or one P1 cluster) per PR  
2. **No UX redesign** (FR-011)  
3. Smoke: login → home → start/open workout → history (manual OK)  
4. Update inventário status do item no PR description  
5. Follow 006 layer + Riverpod conventions  

## P1 slices

| Slice ID | Scope | Done when |
|----------|-------|-----------|
| `p1-home-data` | `home` datasource + repository + controllers sem HTTP direto | Grep presentation `home` sem `HttpService`/`ApiEndpoints`/`AuthService` em páginas/providers remediados |
| `p1-isolate-session-screen` | Isolar `WorkoutSessionScreen` | Sem export em `workout_day.dart`; sem rota GoRouter; SC-004 |
| `p1-http-workout-day` | Extrair HTTP dos providers presentation de `workout_day` | Grep presentation providers listados sem Dio/Http/ApiEndpoints diretos |
| `p1-http-routines` | Extrair HTTP presentation de `routines` (browse/history/etc.) | Grep ampliado inclui `httpServiceProvider`; provider morto `routine_history` removido |

## P2 slices

| Slice ID | Scope | Done when |
|----------|-------|-----------|
| `p2-auth-layout` | Controllers sob `presentation/providers`; login sem `GoogleAuthService`/`AuthService` na page; profile via `AuthRepository` | Grep ampliado + page só fala com controller |
| `p2-history-di` | DI/overrides na raiz da feature como routines | Provider de UI não instancia datasource |
| `p2-creation-onboarding` | Estrutura mínima / UI-only documentado + órfãos | Critério da spec inventário |
| `p2-domain-tag-color` | `exercise_tag` sem Color Flutter | Domain compile sem material color |
| `p2-core-feature-deps` | Cortar leaks core→feature datasource | Dependência documentada ou movida |
| `p2-state-notifier-*` | Um PR por notifier (lista R5) | Arquivo sem `StateNotifier`/`StateNotifierProvider` |

## P3 slices

| Slice ID | Scope | Done when |
|----------|-------|-----------|
| `p3-delete-analytics` | Remover feature stub | Pasta ausente; imports 0 |
| `p3-delete-workout-session-stub` | Remover stub module | Pasta ausente; imports 0 |
| `p3-delete-deprecated-search` | Remover `ExerciseSearchField` legado | Usos 0; UnifiedExerciseSearch permanece |
| `p3-cosmetic-folders` | Unificar organisms/styles se tocados | Sem dual root desnecessário nos arquivos tocados |

## Close-out checklist

- [ ] Todos os DeviationItems `done` ou `accepted_exception`  
- [ ] SC-003 grep P1 HTTP presentation limpo  
- [ ] SC-004 session screen isolada  
- [ ] SC-007 StateNotifier inventário limpo  
- [ ] Agent context / docs não apontam stubs deletados como paths existentes  
