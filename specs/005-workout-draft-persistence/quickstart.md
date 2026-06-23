# Quickstart: Validar Rascunhos de Treino

**Feature**: `005-workout-draft-persistence` | **Pré-requisito**: branch `005-workout-draft-persistence`, migration Drift v7 aplicada

## Setup

```bash
cd iron_log
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --flavor dev
```

Login com usuário de teste. Backend dev acessível para cenários de sucesso; usar modo avião ou proxy para falhas.

---

## Cenário 1 — Auto-save + Continuar (P1)

1. Home → **Iniciar treino** (rotina do dia).
2. Toque **Iniciar** na tela de execução; registre peso/reps em ≥1 série.
3. Volte para Home (back) **sem** finalizar.
4. **Esperado**: card exibe **CONTINUAR TREINO** (não “Iniciar”).
5. Toque **Continuar**.
6. **Esperado**: mesma lista de exercícios e séries preenchidas; timer coerente se ao vivo.

**Prova**: `WorkoutDrafts` row com `status=inProgress` após passo 3 (devtools / unit test de repository).

---

## Cenário 2 — Crash recovery (P1)

1. Repita cenário 1 até passo 2.
2. Force-stop do app (Android) ou encerre processo.
3. Reabra o app → Home.
4. **Esperado**: **Continuar** visível; retomada com dados intactos (SC-003).

---

## Cenário 3 — Finalizar com API falhando (P1)

1. Inicie treino, registre séries, finalize.
2. Com rede desligada **ou** backend retornando 500.
3. **Esperado**:
   - Snackbar informando falha de envio + dados salvos localmente.
   - Draft `status=pendingUpload`; **Continuar** some da Home (não é mais `inProgress`).
4. Restaure rede/API → acione reenvio (lista de pendentes ou flush automático no startup).
5. **Esperado**: treino no histórico; draft removido após sucesso.

---

## Cenário 4 — Erro 400 não apaga dados (P1)

1. Provoque validação 400 no PATCH/POST (payload inválido em dev).
2. **Esperado**: draft permanece; mensagem amigável; dados visíveis para correção ou suporte.

---

## Cenário 5 — Um inProgress por usuário

1. Com treino em andamento salvo, tente iniciar outro treino novo.
2. **Esperado**: diálogo orientando continuar o atual (sem segundo `inProgress`).

---

## Testes automatizados

```bash
# Unit + widget
flutter test test/features/workout_day/data/workout_draft_repository_test.dart
flutter test test/features/workout_day/data/workout_log_service_draft_test.dart
flutter test test/features/home/components/continue_workout_button_test.dart

# Opcional E2E (Patrol)
patrol test integration_test/workout_draft_resume_test.dart
```

---

## Referências

- Modelo: [data-model.md](./data-model.md)
- Contratos: [contracts/workout-draft-services.md](./contracts/workout-draft-services.md)
- Decisões: [research.md](./research.md)
