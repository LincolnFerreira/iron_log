# Quickstart: Importação de Treino por Texto Livre

**Feature**: `007-workout-text-import`  
**Repos**: `iron_log` + `iron_log_back_end`

Guia de validação end-to-end após implementação. Detalhes de API e modelo: [contracts/](./contracts/), [data-model.md](./data-model.md).

---

## Prerequisites

1. Backend rodando com `GEMINI_API_KEY` configurada
2. Flutter app apontando para API dev (`Env.apiBaseUrl`)
3. Usuário autenticado no app
4. Migrações aplicadas:
   - Prisma: `WorkoutTextImport`, `WorkoutSession.importId`, rotina import
   - Drift: tabela `WorkoutImportDrafts`

```bash
# Backend
cd iron_log_back_end
npm run prisma:migrate
npm run start:dev

# Flutter
cd iron_log
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Scenario 1 — Parse simples (P1)

**Goal**: Colar texto → revisão estruturada, sem salvar.

1. Abrir **Histórico** → **Importar de texto**
2. Colar:

```text
Upper 1
Supino reto
20kg 15
40kg 10
60kg 6 senti ombro
```

3. Tocar **Interpretar**

**Expected**:
- Navega para tela de revisão
- 1 sessão, 1 exercício, 3+ séries
- Anotação "senti ombro" vinculada ao supino
- Histórico ainda **sem** novo treino
- `GET /workout-import/:id` retorna `rawText` idêntico

---

## Scenario 2 — Revisão e confirm (P1)

**Goal**: Humano edita → só então persiste.

1. Na revisão, alterar última carga para `55kg`
2. Remover série de aquecimento se marcada
3. Confirmar salvamento

**Expected**:
- `POST /workout-import/confirm` → `201` com `workoutIds`
- Treino aparece no histórico com cargas editadas
- Série removida não existe no registro salvo
- `WorkoutTextImport.status = confirmed`

---

## Scenario 3 — Multi-sessão (P2)

**Goal**: Separar Upper/Lower no mesmo paste.

```text
Upper 1
Supino 60x8

Lower 1
Agachamento 100x5
```

**Expected**: 2 cards de sessão na revisão, títulos coerentes.

---

## Scenario 4 — Incerteza explícita (P2)

**Goal**: Campos ambíguos não inventados.

```text
Treino
Remo 3x?? com dor no punho
```

**Expected**:
- Reps vazias ou marcadas incertas
- Nota de dor preservada
- Banner de incerteza visível

---

## Scenario 5 — Falha de rede no parse

1. Ativar modo avião
2. Colar texto e interpretar

**Expected**: Mensagem amigável; texto permanece no textarea/draft local.

3. Desativar avião → tentar novamente → sucesso

---

## Scenario 6 — Resume draft (edge case)

1. Iniciar parse e chegar à revisão
2. Matar o app (force stop)
3. Reabrir app → Histórico → Importar

**Expected**: Opção de continuar revisão pendente OU draft listado.

---

## Scenario 7 — Idempotência confirm

1. Confirmar importação com sucesso
2. Repetir mesmo `POST /confirm` (via retry manual ou teste API)

**Expected**: `409 Conflict` — sem treinos duplicados.

---

## Automated checks

```bash
# Backend unit
cd iron_log_back_end
npm test -- workout-import

# Flutter unit/widget
cd iron_log
flutter test test/features/workout_import/

# Golden parser (backend)
npm test -- --testPathPattern=workout-import.golden
```

---

## Success criteria mapping

| ID | Validated by |
|----|----------------|
| SC-001 | Scenario 1 timing (manual ou teste UX) |
| SC-002 | Golden set 20+ textos + review accuracy script |
| SC-003 | Scenario 1 + `GET /workout-import/:id` após confirm |
| SC-004 | Scenario 1 — histórico vazio até confirm |
| SC-005 | Scenario 4 + golden com falhas/anotações |
| SC-006 | Scenario 2 timing de correção |

---

## Swagger

Documentação interativa: `http://localhost:3000/api` → tag `workout-import`.
