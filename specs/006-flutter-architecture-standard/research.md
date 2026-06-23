# Research: Padrão Arquitetural Flutter — Iron Log

**Feature**: `006-flutter-architecture-standard` | **Date**: 2026-06-23

## R1 — Estado: Riverpod AsyncNotifier vs StateNotifier legado

**Decision**: Código **novo** MUST usar `@riverpod` + `AsyncNotifier`/`Notifier` com `AsyncValue.guard`. `StateNotifier` existente (~14 arquivos) permanece até migração **incremental** (arquivo a arquivo ao tocar o código).

**Rationale**:
- Documentação Riverpod 3 e práticas 2026 favorecem Notifier/AsyncNotifier.
- Rewrite único de `workoutDayExercisesProvider`, `AuthNotifier`, `homeProvider` etc. arrisca regressão em fluxos críticos (treino, sync, auth redirect).
- Time explicitou: “aos poucos e aos poucos MESMO”.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Big bang StateNotifier → AsyncNotifier | Alto risco E2E/offline; bloqueia entregas de produto |
| Manter StateNotifier para sempre | Contradiz FR-003 e aumenta divergência para novos devs |
| Adotar BLoC para features novas | Zero uso atual; duplicaria padrão |

---

## R2 — read vs watch (Estado ≠ DI)

**Decision**: UI `ref.watch` apenas controllers/estado async. Repositories, `HttpService`, datasources: `ref.read` sempre. Proibido `ref.watch(repository)` na UI.

**Rationale**:
- Evita rebuilds desnecessários e confusão semântica.
- Alinha com injeção via Riverpod sem service locator (GetIt).

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| GetIt para DI + Riverpod só estado | Segundo container; constituição exige Riverpod único |
| watch repository “para reatividade” | Repository não emite mudanças — estado deve estar no controller |

---

## R3 — HttpService singleton vs @riverpod Dio

**Decision**: Manter `HttpService` singleton + `httpServiceProvider` (padrão atual). Novos datasources recebem `ref.read(httpServiceProvider).dio`. Migração futura opcional para `@Riverpod(keepAlive: true) Dio dio(Ref ref)` **dentro** de `HttpService` — não nesta feature.

**Rationale**:
- `AuthInterceptor`, base URL e init já centralizados.
- Exemplo do time com `@riverpod Dio` é válido conceitualmente mas trocar agora é churn sem ganho imediato.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Dio por feature | Duplica interceptors e tokens |
| Substituir HttpService agora | Escopo extra; Fase 5 opcional |

---

## R4 — Endpoints duplicados (`endpoints.dart` vs `api_endpoints.dart`)

**Decision**: Fase 1 — mover símbolos restantes para `api_endpoints.dart`; `endpoints.dart` vira `export` deprecado com `@Deprecated`; deletar após grep zero em `lib/` e `test/`.

**Rationale**:
- Constituição IV exige arquivo único.
- Hoje ~18 arquivos importam um ou outro (lista na spec).

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| Manter dois arquivos | Viola FR-006 e constituição |
| Delete imediato | PR massivo de imports |

---

## R5 — DP-01: WorkoutDayScreen no GoRouter

**Decision**: Opção **A** — rotas query/path em `/workout/*` com parsing em factory constructors existentes (`create`, `manual`, `edit`, `resume`). Substituir `Navigator.push` em Home e History por `context.push`.

**Rationale**:
- Menor mudança na API interna de `WorkoutDayScreen`.
- `ShellRoute` adiciona complexidade sem benefício para tela full-screen única.

**Alternatives considered**:
| Alternativa | Por que rejeitada |
|-------------|-------------------|
| ShellRoute + child | Overhead para uma tela |
| Manter Navigator indefinidamente | Viola FR-008 a longo prazo |

---

## R6 — DP-03: WorkoutDayScreen vs WorkoutSessionScreen

**Decision**: Manter **`WorkoutDayScreen`** como canônica. `WorkoutSessionScreen` → `@Deprecated` na Fase 4; remover após grep zero.

**Rationale**:
- Home, History e Patrol E2E usam `WorkoutDayScreen`.
- Duas UIs duplicam lifecycle start/finish.

---

## R7 — DP-02: Remover provider/bloc do pubspec

**Decision**: Fase 6 — remover `provider`, `bloc`, `flutter_bloc` após `rg` zero em `lib/` e `test/` e `flutter pub deps` sem dependentes transitivos críticos.

**Rationale**:
- Já sem uso em `lib/`; pacotes aumentam confusão e tamanho de resolve.

---

## R8 — DP-04: Localização (l10n)

**Decision**: **Fora de escopo** desta feature. Strings pt-BR inline até feature dedicada.

---

## R9 — Organização home/onboarding (maior divergência estrutural)

**Decision**: Fase 2 move `home/components/` → `home/presentation/`; `state/` → `presentation/providers/`; `home_page.dart` → `presentation/pages/`. Re-exports temporários na raiz da feature por 1 release se necessário.

**Rationale**:
- `home` é o pior desvio do padrão atomic + presentation.
- Uma feature por PR limita blast radius.

---

## R10 — ProviderObserver

**Decision**: Adicionar `AppProviderObserver` em `main.dart` quando `kDebugMode` (Fase 5 início, pode antecipar na Fase 0 se trivial).

**Rationale**:
- Baixo custo; acelera debug de providers durante migração.

---

## R11 — Nomenclatura declarativa

**Decision**: Código novo MUST usar nomes completos (`routineRepository`, `authState`). Proibir abreviações opacas (`m.`, `svc`, `repo` sem prefixo de domínio).

**Rationale**:
- Preferência explícita do time para legibilidade em code review.

---

## R12 — CI / validação arquitetural

**Decision**: Quickstart manual + opcional script `scripts/check_architecture.sh` (grep proibidos: `package:provider`, `StateNotifier` em arquivos novos via diff, imports `endpoints.dart`). Não bloquear CI na Fase 0 — adicionar na Fase 1 se trivial.

**Rationale**:
- Evita false positives em legado até migração avançar; `git diff` contra main para código novo.
