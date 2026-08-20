# Inventory Status — 008 Clean Architecture Audit

**Updated**: 2026-08-20 (post `/speckit-analyze` remediação C1–C3 / A1 / U1)  
**Spec**: [spec.md](./spec.md) · **Slices**: [contracts/remediation-slices.md](./contracts/remediation-slices.md)

**Canonical inventory** (post-US1): this file. Spec “Inventário Inicial” is the audit snapshot.

## How to pick next PR

1. Prefer open items with highest priority (`high` → `medium` → `low`)
2. Map item → slice ID below
3. One feature (or one P1 cluster) per PR; smoke login → home → workout → history
4. Set `status=done` only with grep/PR evidence

---

## High priority (P1)

| id | area | problem | evidence | slice | status |
|----|------|---------|----------|-------|--------|
| P1-home-http | home | Presentation HTTP | `HomeRepository` + greps 0 | `p1-home-data` | done |
| P1-session-screen | workout_day | Legacy export | barrel comment only; rotas `WorkoutDayScreen` | `p1-isolate-session-screen` | done |
| P1-http-workout-day | workout_day | Presentation HTTP | `WorkoutDayRepository` + greps 0 | `p1-http-workout-day` | done |
| P1-http-routines | routines | Presentation HTTP | Exercise remote + repo active routine; **deleted** dead `routine_history_provider` (HTTP via `httpServiceProvider`); greps ampliados 0 | `p1-http-routines` | done |

---

## Medium priority (P2)

| id | area | problem | evidence | slice | status |
|----|------|---------|----------|-------|--------|
| P2-auth-layout | auth | Controllers at root + login/profile I/O | login → `AuthController.signInWithGoogle`; profile → `AuthRepository.getUserProfile`; greps ampliados 0 | `p2-auth-layout` | done |
| P2-history-di | workout_history | DS in presentation | `workout_history_providers.dart` + main overrides | `p2-history-di` | done |
| P2-creation-onboarding | creation/onboarding | Incomplete layers | UI-only over domain entities; orphan `pages/select` deleted | `p2-creation-onboarding` | done |
| P2-domain-tag-color | workout_day | `Color` in domain | `exercise_tag.dart` Flutter-free; `exercise_tag_styles.dart` | `p2-domain-tag-color` | done |
| P2-core-feature-deps | core | Core→feature | `routineLocalDataSourceProvider` removed; search via `ExerciseRemoteDataSource`. Residual: `AuthService` still imports feature entity types for legacy helpers | `p2-core-feature-deps` | accepted_exception |
| P2-sn-* (10) | various | StateNotifier | all migrated to `@riverpod` Notifier; SC-007 greps 0 | `p2-state-notifier-*` | done |

---

## Low priority (P3)

| id | area | status |
|----|------|--------|
| P3-analytics | deleted | done |
| P3-workout-session-stub | deleted | done |
| P3-deprecated-search | deleted | done |
| P3-cosmetic | dual organism folders | accepted_exception |

---

## Reactivity follow-up (U1 — T073/T074)

| id | hotspot | issue | suggested fix | status |
|----|---------|-------|---------------|--------|
| RX-home-watches | `home_page.dart` / `HomeTemplate` | 5× `ref.watch` no `build` da page | Consumers + `.select` + `homeGreetingNameProvider` | done |
| RX-di-watch | `*_providers.dart` / sync | `ref.watch` em DI | `ref.read` para Http/repo/db; `watch`+`select` só userId | done |
| RX-select-coverage | app-wide | Quase zero `Provider.select` | Home header/banner/metrics usam select; ampliar ao tocar | done (home) / open elsewhere |
| RX-timer-ok | `WorkoutTimer` | Isolado via `elapsedTimeProvider` | **Manter como gabarito** | done (reference) |

---

## Close-out log (T063+; revalidado pós-analyze remediação)

```text
# Presentation HTTP / AuthService leaks (SC-003) — grep AMPLIADO
rg "\bHttpService\b|\bApiEndpoints\b|\bAuthService\b|\bhttpServiceProvider\b" \
  lib/features/home/presentation \
  lib/features/workout_day/presentation \
  lib/features/routines/presentation \
  lib/features/auth/presentation
→ 0

# GoogleAuthService em pages/widgets → 0 (AuthController may use it)

# Legacy export (SC-004)
rg "workout_session_screen" lib/features/workout_day/workout_day.dart lib/core/routes
→ comment only in workout_day.dart

# US2 AC3 — product finish → summary via GoRouter
# workout_finish_flow.dart: context.push(WorkoutRouteLocations.summaryPath, …)

# FR-005 — ref.watch(*Repository*) em pages/widgets/components
→ 0 (DI wiring em *providers.dart / feature root ainda pode watch — preferir read em follow-up RX-di-watch)

# Stubs
test ! -d lib/features/analytics → OK
test ! -d lib/features/workout_session → OK

# StateNotifier inventory (SC-007) → 0

# Analyze remediação 2026-08-20
# - Deleted: routines/.../routine_history_provider.dart + routine_history_dto.dart (dead + HTTP leak)
# - Auth: login sem GoogleAuthService; userProfile via AuthRepository; ApiEndpoints.me
```

**Smoke SC-005 (T064)**: **OPEN** — pending manual QA on device/emulator before merge.  
Checklist: login → home (métricas/calendário) → iniciar/registrar treino → histórico.

**flutter analyze (T067)**: re-run on auth + routines after remediação.

**PR checklist**: use `specs/006-flutter-architecture-standard/contracts/pr-review-checklist.md` + this inventory for each remediation PR (FR-010).
