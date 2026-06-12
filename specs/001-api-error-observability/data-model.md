# Data Model: Observabilidade de Erros

**Feature**: `001-api-error-observability` | **Storage**: Drift (SQLite local only)

## Entity: ApiErrorLog

Registro local de um incidente de falha HTTP/API. **Não sincroniza** com servidor (sem `pendingSync`).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | TEXT (UUID/cuid) | yes | PK |
| `createdAt` | DateTime (UTC) | yes | Momento do incidente; usado no purge |
| `httpMethod` | TEXT | yes | GET, POST, PATCH, DELETE, etc. |
| `httpPath` | TEXT | yes | Path relativo (ex. `/routine`) |
| `baseUrl` | TEXT | no | Base no momento do erro (dev/prod) |
| `statusCode` | INTEGER | no | HTTP status quando houver `response` |
| `dioErrorType` | TEXT | yes | Ex. `connectionTimeout`, `badResponse` |
| `errorMessage` | TEXT | no | `DioException.message` sanitizado |
| `requestBodyJson` | TEXT | no | Body enviado, sanitizado + truncado |
| `responseBodyJson` | TEXT | no | Corpo resposta, sanitizado + truncado |
| `truncated` | BOOLEAN | yes | default false; true se body cortado em 8KB |
| `originalLength` | INTEGER | no | Tamanho original antes do truncamento |
| `userIdHash` | TEXT | no | SHA256 truncado do Firebase UID ou null |
| `appVersion` | TEXT | no | `package_info_plus` |
| `flavor` | TEXT | no | `dev` / `prod` de `Env.flavor` |

### Indexes

- `{ createdAt }` — purge eficiente por idade
- `{ httpPath, createdAt }` — consulta diagnóstica (dev tools futuro)

### Validation rules

- `httpMethod` MUST NOT be empty.
- `httpPath` MUST start with `/` ou ser URL relativa registrada pelo interceptor.
- JSON columns MUST be valid JSON string ou null.
- Nenhum campo MUST conter substring `Bearer ` após sanitização.

---

## Entity: RetentionPolicy (config, not persisted)

| Constant | Value | Notes |
|----------|-------|-------|
| `retentionDays` | 7 | Ajustável sem migration produção |
| `maxBodyBytes` | 8192 | Truncamento de request/response |

---

## Entity: CrashlyticsCustomKeys (ephemeral)

Não persistido localmente; enviado ao Firebase por evento.

| Key | Source |
|-----|--------|
| `http_method` | ApiErrorLog.httpMethod |
| `http_path` | ApiErrorLog.httpPath |
| `http_status` | statusCode as string |
| `dio_type` | dioErrorType |
| `flavor` | Env.flavor |

---

## Drift migration

| From | To | Change |
|------|-----|--------|
| schema 4 | schema 5 | `CREATE TABLE api_error_logs (...)` + indices |

**Explicit constraint**: migration MUST NOT alterar tabelas de treino/rotina/sync existentes além de registrar nova tabela.

---

## Relationships

- **ApiErrorLog** — standalone; sem FK para User/Routine/Workout.
- Purge DELETE only on `api_error_logs` WHERE `createdAt < cutoff`.

---

## State transitions

```
[DioException in interceptor]
    → sanitize → insert ApiErrorLog
    → optional Crashlytics non-fatal (rate-limited)
    → HttpErrorHandler (unchanged user messaging)

[App startup]
    → purge ApiErrorLog where age > 7 days

[Widget build failure]
    → ErrorWidget.builder → AppErrorFallback UI
    → Crashlytics fatal/non-fatal per FlutterError policy
```
