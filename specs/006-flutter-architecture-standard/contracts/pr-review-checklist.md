# Contract: PR Review Checklist (Architecture)

**Type**: Internal architecture governance  
**Feature**: `006-flutter-architecture-standard`

Use em todo PR que toca `lib/`. Itens marcados **(new)** aplicam-se estritamente a código novo; **(legacy)** tolerado até migração da fase correspondente.

## Layers

- [ ] **(new)** Arquivos novos estão na camada correta (`domain` / `data` / `presentation`)
- [ ] **(new)** `domain/` sem imports Flutter/Dio/Drift
- [ ] **(new)** Widgets não chamam Dio nem Drift diretamente
- [ ] **(new)** DTOs não vazam para UI — entities via controller

## Riverpod

- [ ] **(new)** Sem `StateNotifier`, `provider`, `bloc` em código novo
- [ ] **(new)** UI `watch` só estado; `read` para repositories/services
- [ ] **(new)** Side-effects (snackbar, nav) via `ref.listen`, não no `build`
- [ ] **(new)** Async ops usam `AsyncValue.guard` em controllers codegen
- [ ] **(legacy)** Se tocou `StateNotifier` legado, avaliou migração para `AsyncNotifier` no mesmo PR?

## Folders

- [ ] **(new)** Sem pastas `state/`, `bloc/` na raiz da feature
- [ ] **(new)** Providers em `presentation/providers/` (não em `data/`)
- [ ] **(new)** Páginas em `presentation/pages/`

## Core

- [ ] **(new)** Endpoints só em `api_endpoints.dart`
- [ ] **(new)** HTTP via `HttpService` / datasource — não `Dio()` solto
- [ ] Reutilizou `core/components/` antes de duplicar UI

## Navigation

- [ ] **(new)** Rotas shell via GoRouter — não `Navigator.push` para páginas de primeiro nível
- [ ] **(legacy)** `Navigator.push` para `WorkoutDayScreen` OK até Fase 4 concluída

## Offline / domain

- [ ] Writes syncáveis incrementam `version` + `pendingSync`
- [ ] Writes compostos em transação Drift
- [ ] Não quebrou separação plano (Session) vs execução (WorkoutSession)

## Tests

- [ ] Widget tests usam `ProviderScope` + overrides
- [ ] E2E usa chaves `e2e_*` quando aplicável
- [ ] `flutter test` / Patrol relevantes passam

## Style

- [ ] Nomes declarativos — sem abreviações opacas em código novo
- [ ] Strings UI em pt-BR

## Quick reject triggers

Rejeitar imediatamente se código **novo** contém:

1. `import 'package:provider/` ou `flutter_bloc`
2. `class X extends StateNotifier`
3. `ref.watch(*RepositoryProvider)` em widget
4. `import .../endpoints.dart` (usar `api_endpoints.dart`)
5. Nova pasta `state/` ou `bloc/` na feature
