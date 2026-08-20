# Research: 008-clean-architecture-audit

**Date**: 2026-08-20  
**Spec**: [spec.md](./spec.md)

## R1 — Gabarito estrutural

**Decision**: Usar `lib/features/routines/` e `lib/features/workout_day/` como única referência canônica (já 006 + constituição).

**Rationale**: Já têm `domain`/`data`/`presentation` e padrão de overrides; time já conhece.

**Alternatives considered**: Introduzir feature “example” nova só para template — rejeitado (duplica gabarito). Layer-first global — rejeitado pela 006.

---

## R2 — Extração de HTTP da presentation

**Decision**: Para cada call site em presentation (providers/pages):

1. Interface em `domain/repositories` (se regra de negócio / multi-fonte)
2. Remote em `data/datasources/*_remote_datasource.dart` via `HttpService` + `ApiEndpoints`
3. Impl em `data/repositories`
4. Provider abstrato + override em `*_providers.dart` / `main.dart` (padrão routines)
5. Presentation só `ref.read(repo)` / controller — **sem** `HttpService`/`ApiEndpoints`/`AuthService` direto

**Rationale**: FR-004/FR-013; testabilidade com overrides.

**Alternatives considered**: Manter HTTP só nos providers “porque não é widget” — rejeitado (ainda é presentation). Service solto em `core` por feature — rejeitado (quebra ownership por feature).

---

## R3 — Isolamento de `WorkoutSessionScreen`

**Decision**: Isolar, não deletar (clarification):

- Remover `export` de `workout_day.dart`
- Garantir zero rotas GoRouter apontando para ela
- Mover para pasta explícita tipo `presentation/pages/_legacy/` **ou** prefixar/documentar `@Deprecated` + comentário “não usar em produto”
- Fluxos oficiais = `WorkoutDayScreen` + `WorkoutRouteLocations`

**Rationale**: FR-006 / SC-004; reduz risco vs delete imediato mantendo arquivo para referência histórica.

**Alternatives considered**: Delete imediato — rejeitado na clarify. Manter export — rejeitado (continua caminho de produto).

---

## R4 — Remoção de stubs

**Decision**: Após `rg`/análise de imports = 0 usos de produto, deletar:

- `lib/features/analytics/`
- `lib/features/workout_session/`
- Widget deprecado `ExerciseSearchField` (+ seções que só o usam)
- Arquivo órfão `onboarding/.../pages/select`

Atualizar docs/agent context para não citar stubs como “não copiar” se pastas não existirem.

**Rationale**: FR-008; evita exemplo errado.

**Alternatives considered**: Marcar “não copiar” — rejeitado na clarify.

---

## R5 — Inventário StateNotifier → AsyncNotifier

**Decision**: Migrar **todos** os abaixo nesta feature (PRs 1 arquivo/notifier por vez quando possível):

| Arquivo | Notifier |
|---------|----------|
| `workout_day/.../workout_day_provider.dart` | `WorkoutDayExercisesNotifier` |
| `workout_day/.../workout_timer_provider.dart` | `WorkoutTimerNotifier` |
| `workout_day/.../workout_controller.dart` | `WorkoutController` |
| `workout_day/.../voice_input_provider.dart` | `VoiceInputNotifier` |
| `workout_creation/.../workout_creation_provider.dart` | `WorkoutCreationNotifier` |
| `home/.../workout_provider.dart` | `WorkoutNotifier` |
| `routines/.../session_provider.dart` | `SessionNotifier` |
| `routines/.../session_selection_provider.dart` | `SessionExerciseSelectionNotifier` |
| `core/components/exercise_search/unified_exercise_search.dart` | `ExerciseSearchNotifier` |
| `core/providers/sync_providers.dart` | `SyncStateNotifier` |

Padrão alvo: `@riverpod` + `AsyncNotifier`/`Notifier` + `AsyncValue.guard` onde async; regenerar `*.g.dart` com build_runner.

**Rationale**: FR-014 / SC-007 + clarification.

**Alternatives considered**: Só ao tocar — rejeitado na clarify. Um PR único — rejeitado (rewrite em massa).

---

## R6 — `home` data layer

**Decision**: Criar `home/domain/repositories` + `home/data/datasources` + `home/data/repositories` cobrindo métricas, calendário, rest-day toggle e demais GETs hoje em `home_controller` / `*_provider` via `AuthService`/`HttpService`.

**Rationale**: P1 mais crítico; hoje não há fronteira de repositório.

**Alternatives considered**: Empurrar tudo para `routines` repo — rejeitado (home não é ownership de rotina).

---

## R7 — `auth` layout

**Decision**: Mover `auth_controller.dart` / `auth_state.dart` para `presentation/providers/`; login page só via controller; Firebase/HTTP de login atrás de data/service se ainda houver call direto na page.

**Rationale**: FR inventário P2; alinhamento a feature layers.

**Alternatives considered**: Manter na raiz “porque keepAlive” — rejeitado (keepAlive funciona sob presentation/providers).

---

## R8 — Domínio sem cor de UI

**Decision**: Remover `Color` / Flutter material de `domain/entities/exercise_tag.dart`; mapear cor em presentation (styles/mapper).

**Rationale**: FR-007.

**Alternatives considered**: Manter Color no domain “é só um enum visual” — rejeitado (acopla domain a Flutter UI).

---

## R9 — Core ↔ features

**Decision**: Caso a caso: (a) mover contrato compartilhado para `core` se for realmente cross-feature; (b) ou inverter dependência (feature não vaza datasource para core). Não criar ciclo novo.

**Rationale**: Inventário médio; ownership claro.

**Alternatives considered**: Ignorar leaks — rejeitado (piora com o tempo).

---

## R10 — Ordem de PRs

**Decision**:

1. P1 home data + isolar session screen  
2. P1 HTTP workout_day / routines (por provider)  
3. P2 auth / history / creation-onboarding / domain color / core leaks  
4. StateNotifier migrations (podem intercalar após data layer da mesma feature)  
5. P3 deletes + cosmético  

Cada PR: smoke SC-005 + greps relevantes.

**Rationale**: Clarifications P1→P2→P3; reduz conflito.

**Alternatives considered**: Começar por deletes P3 — possível cedo se zero imports, mas não bloqueia P1.
