# Quickstart: Validar Observabilidade de Erros

**Feature**: `001-api-error-observability`  
**Prerequisites**: Flutter SDK >=3.27, Firebase project configurado, backend local opcional para erros reais.

## 1. Dependências Firebase

```bash
cd iron_log
flutter pub get
# Confirmar pubspec: firebase_core ^4.10.0, firebase_crashlytics ^5.2.3
dart run build_runner build --delete-conflicting-outputs
```

## 2. Build e run (dev)

```bash
flutter run --dart-define=FLAVOR=dev
```

## 3. Validar log local de API (401)

1. Faça logout ou use token inválido.
2. Navegue para tela que chama `/routine`.
3. **Esperado**: Snackbar amigável (comportamento existente) + nova linha em `api_error_logs`.

**Inspecionar SQLite** (dev):

```bash
# Após implementação — Drift schema v5
# Usar drift/devtools ou query manual no arquivo iron_log_db
```

Campos esperados: `httpMethod`, `httpPath`, `statusCode=401`, `responseBodyJson` sem token.

## 4. Validar timeout / sem rede

1. Ative modo avião.
2. Dispare sync ou refresh de rotinas.
3. **Esperado**: `dioErrorType=connectionError` (ou timeout), `statusCode` null.

## 5. Validar purge 7 dias

**Unit test** (preferido em CI):

```bash
flutter test test/core/observability/api_error_log_retention_test.dart
```

Cenário: inserir log com `createdAt` = now - 8 days → `purgeExpiredLogs()` → count deleted = 1.

## 6. Validar ErrorWidget (release)

```bash
flutter run --release --dart-define=FLAVOR=prod
# Temporariamente: widget de teste que throws em build (remover após validação)
```

**Esperado**: fallback pt-BR temático, sem tela vermelha; evento no Firebase Crashlytics.

## 7. Validar Crashlytics (device físico, release)

1. Build release instalado em dispositivo.
2. Force API 500 contra backend local/prod.
3. Abra Firebase Console → Crashlytics → Non-fatals.
4. **Esperado**: custom keys `http_path`, `http_status` presentes; ausência de `Authorization`.

## 8. Sanitização (audit)

```bash
flutter test test/core/observability/error_log_sanitizer_test.dart
```

50 fixtures com tokens fake → zero match `Bearer` no output.

## 9. O que NÃO validar nesta feature

- PostgreSQL / Prisma Studio — nenhuma tabela nova no servidor.
- DELETE em dados de treino — purge só afeta `api_error_logs`.

## Referências

- [spec.md](./spec.md) — user stories e FRs
- [data-model.md](./data-model.md) — schema Drift
- [contracts/observability-services.md](./contracts/observability-services.md) — interfaces internas
