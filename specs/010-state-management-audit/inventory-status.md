# Inventory Status — 010 State Management Audit

**Updated**: 2026-08-27 (implement — p2-setstate-workout-day)  
**Spec**: [spec.md](./spec.md) · **Slices**: [contracts/remediation-slices.md](./contracts/remediation-slices.md)

**Canonical inventory**: this file.

## How to pick next PR

1. Prefer open items with highest severity (`high` → `medium` → `low`)
2. Map item → slice ID below
3. One feature (or one P1 cluster) per PR; smoke login → home → workout → history
4. Set `status=done` only with grep/PR evidence

---

## High priority (P1)

| id | category | area | problem | evidence | slice | status |
|----|----------|------|---------|----------|-------|--------|
| SM-se-no-listen | side_effect | app-wide | Zero `ref.listen` (baseline) | **done** — G1 ≥1 por cluster P1: auth, workout_day, routines (×2), home | `p1-listen-foundation` | done |
| SM-auth-login | side_effect | auth | Snackbars imperativos + `_isLoading` | was `login_screen.dart:114-154`; **fixed** — `ref.listen` + `isSigningIn` | `p1-auth-listen` | done |
| SM-workout-day-screen | side_effect | workout_day | Side-effects fora de listener | **done** — `workout_day_screen.dart` + `workoutUiFeedbackProvider` | `p1-workout-day-listen` | done |
| SM-workout-finish | side_effect | workout_day | Finish flow snackbars | **done** — `workout_finish_flow.dart` | `p1-workout-day-listen` | done |
| SM-routines-page | side_effect | routines | ScaffoldMessenger em CRUD | **done** — `routines_page.dart` + `routineUiFeedbackProvider` | `p1-routines-listen` | done |
| SM-home-sheets | side_effect | home | Sheets com ScaffoldMessenger | **done** — `homeUiFeedbackProvider` + `home_page.dart` listener | `p1-home-sheets-listen` | done |

---

## Medium priority (P2)

| id | category | area | problem | evidence | slice | status |
|----|----------|------|---------|----------|-------|--------|
| SM-watch-routine-providers | watch_read | routines | `ref.watch` em wiring DI | `routine_providers.dart:54` → **read** | `p2-routines-watch-read` | done |
| SM-watch-exercise-browse | watch_read | routines | `ref.watch` datasource | `exercise_browse_provider.dart:9` → **read** | `p2-routines-watch-read` | done |
| SM-setstate-workout-day | setstate_boundary | workout_day | setState + domínio local | **done** — footer ephemeral KEEP + snackbar→feedback; cardio submit Notifier; session sheet ephemeral KEEP; day_screen start latch documented | `p2-setstate-workout-day` | done |
| SM-setstate-routines | setstate_boundary | routines | setState em modals/lists | create_exercise_modal (9×), reorderable_session_list (4×), routines_page (5×) | `p2-setstate-routines` | open |
| SM-setstate-creation | setstate_boundary | workout_creation | setState em bottom sheet | add_workout_bottom_sheet.dart (2×) | `p2-setstate-creation` | open |
| SM-select-coverage | select_rebuild | app-wide | `.select` fora home | **done** — home (008); workout_day loading select; routines_page body select | `p2-select-on-touch` | done |
| SM-lifecycle-sheets | lifecycle | workout_day, home | async + mounted ad hoc | voice_input (4×), rest_day sheets | `p2-lifecycle-sheets` | open |
| SM-session-detail | side_effect | routines | Side-effects session CRUD | **done** — `session_detail_content.dart` | `p1-routines-listen` | done |
| SM-exercise-card | side_effect | workout_day | Múltiplos ScaffoldMessenger | **done** — feedback provider | `p1-workout-day-listen` | done |
| SM-footer-actions | setstate_boundary | workout_day | setState + snackbar | **done** — weight UI `ephemeral_ui`; snackbar→`workoutUiFeedbackProvider` | `p2-setstate-workout-day` | done |

### setState file map (G5 — 20 files)

| file | category | resolution |
|------|----------|------------|
| `auth/.../login_screen.dart` | mirrors_provider | **done** — removed local loading |
| `workout_day/.../footer_actions.dart` | ephemeral_ui | **done** — KEEP weight/suggestions; snackbar migrado |
| `workout_day/.../cardio_creation_page.dart` | mixed | **done** — form KEEP; loading→`cardioCreationSubmitProvider`; feedback→home |
| `workout_day/.../workout_day_screen.dart` | domain_local | **accepted_exception** — `_workoutStarted`/`_isStartingWorkout` latch local + draft sync; `_selectedDate` ephemeral |
| `workout_day/.../exercise_card.dart` | mixed | **accepted_exception** — expand ephemeral; domain flush via notifier; suggestion loading parcial |
| `workout_day/.../session_exercises_sheet.dart` | ephemeral_ui | **done** — KEEP (legacy sheet; preview weight + list toggle) |
| `workout_day/.../add_exercise_bottom_sheet.dart` | ephemeral_ui | likely keep |
| `workout_day/.../exercise_reorder_sheet.dart` | ephemeral_ui | drag — keep |
| `workout_day/.../cluster_config_sheet.dart` | ephemeral_ui | keep |
| `workout_day/.../voice_input_bottom_sheet.dart` | domain_local | lifecycle P2 |
| `workout_day/.../workout_session_screen.dart` | domain_local | **accepted_exception** (legacy) |
| `routines/.../create_exercise_modal.dart` | domain_local | migrate |
| `routines/.../reorderable_session_list.dart` | ephemeral_ui | drag — keep |
| `routines/.../routines_page.dart` | domain_local | migrate |
| `routines/.../session_editor_page.dart` | ephemeral_ui | keep |
| `routines/.../session_exercise_card.dart` | ephemeral_ui | keep |
| `routines/.../session_detail_content.dart` | domain_local | migrate |
| `home/.../rest_day_creation_sheet.dart` | domain_local | P1 listen + P2 |
| `workout_creation/.../add_workout_bottom_sheet.dart` | domain_local | migrate |
| `settings/.../settings_page.dart` | domain_local | out of scope P3 |

---

## Low priority (P3)

| id | category | area | problem | evidence | slice | status |
|----|----------|------|---------|----------|-------|--------|
| SM-legacy-session | setstate_boundary | workout_day | Legado isolado | `workout_session_screen.dart` — sem rota produto (008) | — | accepted_exception |
| SM-settings-page | side_effect | settings | setState + AppSnackbar | fora escopo prioritário | — | open |
| SM-checklist-doc | side_effect | docs | Checklist PR estado | cross-link 006 pr-review-checklist | `p3-checklist` | done |
| SM-voice-input | lifecycle | workout_day | 4× ScaffoldMessenger | voice_input_bottom_sheet.dart | `p2-lifecycle-sheets` | open |

---

## Reference patterns (copy these)

| id | path | note |
|----|------|------|
| REF-auth-login | `lib/features/auth/presentation/pages/login_screen.dart` | `ref.listen` + AuthFeedback |
| REF-routines-page | `lib/features/routines/presentation/pages/routines_page.dart` | `ref.listen` + RoutineUiFeedback + body `.select` |
| REF-home-page | `lib/features/home/presentation/pages/home_page.dart` | `ref.listen` + HomeUiFeedback |
| REF-home-template | `lib/features/home/presentation/components/templates/home_template.dart` | Consumers + `.select` (008) |
| REF-workout-timer | `lib/features/workout_day/presentation/providers/workout_timer_provider.dart` | Rebuild isolado |
| REF-state-patterns | `specs/010-state-management-audit/contracts/state-patterns.md` | Page + listen template |

---

## Baseline greps

**Initial (2026-08-27 plan)**:

```text
G1 ref.listen files     → 0
G2 snackbar/scaffold    → 62 (presentation)
G3 watch repo UI pages  → 0
G4 watch repo wiring    → 1 (routine_providers.dart)
G5 setState files       → 20
G6 StateNotifier        → 0
```

**After implement slice auth + watch/read (2026-08-27)**:

```text
G1 ref.listen in auth        → login_screen.dart
G1 ref.listen in workout_day → workout_day_screen.dart
G1 ref.listen in routines   → routines_page.dart, session_detail_content.dart
G2 auth login reactive       → 0 ScaffoldMessenger (sync forgot-password AppSnackbar OK)
G4 watch repo wiring         → 0
```

**After implement slice home + US2 close (2026-08-27)**:

```text
G1 ref.listen in home        → home_page.dart
G1 ref.listen total (lib/)   → 6 files (auth, workout_day, routines×2, home, app_router)
G2 home presentation         → 0 ScaffoldMessenger
SM-se-no-listen              → done (P1 clusters auth/workout_day/routines/home)
```

---

## Close-out checklist

- [ ] All `high` items `done` or `accepted_exception`
- [ ] SC-002: zero side-effects proibidos no build (features remediadas)
- [ ] SC-003: zero `ref.watch` repo/HTTP in pages/widgets/components
- [ ] SC-004: smoke login → home → treino → histórico OK
- [x] SC-005: checklist publicado (006 + 010 state-enforcement)
- [x] SC-006: gabarito citado (REF-auth-login + home + timer)
