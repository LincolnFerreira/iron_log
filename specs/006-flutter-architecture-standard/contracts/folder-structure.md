# Contract: Folder Structure per Feature

**Type**: Internal architecture governance  
**Feature**: `006-flutter-architecture-standard`

## Canonical tree

```text
lib/features/<feature_name>/
├── <feature>_providers.dart       # optional — ProviderScope overrides
├── domain/
│   ├── entities/
│   ├── repositories/
│   ├── usecases/                  # when orchestration needed
│   └── mappers/                   # optional — pure domain
├── data/
│   ├── datasources/
│   ├── models/
│   ├── mappers/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── pages/
    ├── providers/                 # or controllers/ (@riverpod)
    ├── widgets/
    ├── atoms/
    ├── molecules/
    ├── organisms/
    └── components/                # optional groupings
```

## Reference implementations

| Feature | Path | Notes |
|---------|------|-------|
| Routines | `lib/features/routines/` | Full 3-layer + use cases |
| Workout day | `lib/features/workout_day/` | Execution domain; fix `data/providers/` in Fase 2 |

## Forbidden folder names (new code)

| Forbidden | Use instead |
|-----------|-------------|
| `features/<x>/state/` | `presentation/providers/` |
| `features/<x>/bloc/` | `presentation/providers/` |
| `features/<x>/components/` at feature root | `presentation/...` |
| `data/providers/` | `presentation/providers/` |
| `features/<x>/model/` | `domain/entities/` |

## Pages location

- New pages: `presentation/pages/<name>_page.dart`
- Legacy `home_page.dart` at feature root → migrate to `presentation/pages/`

## File naming

- `snake_case.dart` matching primary public class
- Generated: `*.g.dart` adjacent to source — never edit manually
- Tests mirror: `test/features/<feature>/...`

## core/ (not duplicated per feature)

```text
lib/core/
├── api/api_endpoints.dart          # sole endpoint constants file
├── services/http_service.dart
├── database/
├── sync/
├── routes/
├── providers/
├── components/
└── widgets/
```

## Barrel exports

Optional `lib/features/<feature>/<feature>.dart` — export public API only when it reduces cross-feature imports.
