# Contract: Layer Boundaries

**Type**: Internal architecture governance  
**Feature**: `006-flutter-architecture-standard`

## domain/

**MUST**:
- Entidades puras, enums de negócio, interfaces de repository, use cases.
- Validações que não dependem de Flutter ou I/O.

**MUST NOT**:
- Importar `package:flutter`, `dio`, `drift`, `firebase_*`, `flutter_riverpod`.
- Referenciar widgets, `BuildContext`, providers.

**Violation signal**: qualquer `import 'package:flutter/` em `domain/`.

---

## data/

**MUST**:
- Datasources (local Drift + remote Dio), DTOs, mappers DTO↔entity, repository implementations, services de I/O (`WorkoutLogService`).

**MUST NOT**:
- Widgets, `ConsumerWidget`, navegação.
- Providers de UI (mover para `presentation/providers/`).

**Violation signal**: `presentation/providers/` ou `data/providers/` com `ConsumerWidget` imports.

---

## presentation/

**MUST**:
- Pages, widgets, `@riverpod` controllers, `StateNotifier` legado (até migração), fluxos de tela (`WorkoutFinishFlow`).
- Chamar repositories via `ref.read` dentro de notifiers.

**MUST NOT**:
- `Dio()` direto, `database.select(...)` direto, SQL raw.
- Lógica de domínio pesada (orquestração multi-repo → use case em `domain/`).

---

## core/

**MUST**:
- Infra compartilhada: HTTP, DB schema, sync, router, tema, componentes cross-feature.

**MUST NOT**:
- Regras de negócio específicas de uma feature (ex.: lógica de finish de treino).
- Importar `features/*` (core é dependência das features, não o contrário).

---

## Dependency direction

```text
presentation → domain ← data → core
                ↑__________|
```

Features MAY import `core/` e próprio `domain/`. `presentation` MUST NOT import `data/models` DTOs diretamente na UI — usar entities via controller/repository.
