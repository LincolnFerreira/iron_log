# E2E Flutter (Patrol) — Registro de treino

Testes **ponta a ponta** com [Patrol](https://patrol.leancode.co): UI Flutter + **picker nativo do Google** + verificação via API.

## Setup (uma vez)

```bash
# 1. Patrol CLI
dart pub global activate patrol_cli
patrol doctor

# 2. Backend local no ar (fixtures E2E são criados automaticamente via API)
cd iron_log_back_end && npm run start:dev

# 3. Emulador com conta Google (Settings → Accounts)
cd iron_log && flutter pub get
```

Opcional: `npm run seed:e2e` só se quiser inspecionar dados no banco — **não é obrigatório**.

## Rodar

```bash
cd iron_log

# Um teste
patrol test --target integration_test/workout_techniques_e2e_test.dart --no-uninstall

# Script (todos — ajuste --target no script)
bash scripts/run_e2e_workout.sh

# Dev com hot restart
patrol develop --target integration_test/workout_techniques_e2e_test.dart
```

**Não use** `flutter test integration_test/` — Patrol exige `patrol test`.

### Conta Google no picker

Por padrão toca a **1ª conta** listada (`textContains: '@'`).

Para forçar uma conta:

```bash
patrol test --target integration_test/workout_create_e2e_test.dart \
  --dart-define=E2E_GOOGLE_ACCOUNT=lincolnsp17@example.com \
  --no-uninstall
```

## Fluxo de auth

1. Reinstall do APK zera sessão Firebase (normal)
2. Patrol abre login → **Continuar com Google**
3. Picker nativo → 1ª conta (ou `E2E_GOOGLE_ACCOUNT`)
4. `GET /routine` → se não existir, **POST /routine** + exercícios E2E (automático)

## Cenários

| Arquivo | Verificação |
|---------|-------------|
| `workout_create_e2e_test.dart` | POST séries normais |
| `workout_techniques_e2e_test.dart` | WARMUP / DROP / CLUSTER |
| `workout_manual_e2e_test.dart` | `isManual: true` |
| `workout_edit_e2e_test.dart` | PATCH reps/peso |

## Troubleshooting

| Sintoma | Causa / fix |
|---------|-------------|
| `Gradle failed` + `Total: 0` | Resolvido: `connectivity_plus ^6.1` + `compileSdk 36` |
| `Rotina E2E não encontrada` | Backend off ou sem auth — precisa `npm run start:dev` |
| `patrol: command not found` | `dart pub global activate patrol_cli` |
| Picker não clicou | `--dart-define=E2E_GOOGLE_ACCOUNT=seu@gmail.com` |
| Usou `flutter test` | Use **`patrol test`** — picker Google é nativo ([SO](https://stackoverflow.com/questions/58052343/selecting-email-account-from-google-sign-in-during-flutter-integration-testing)) |
