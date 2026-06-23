## Architecture review

Ao alterar `lib/`, use o checklist completo:

[specs/006-flutter-architecture-standard/contracts/pr-review-checklist.md](../specs/006-flutter-architecture-standard/contracts/pr-review-checklist.md)

### Quick checks

- [ ] Camadas corretas (`domain` / `data` / `presentation`)
- [ ] Riverpod: `watch` estado, `read` repository/HTTP
- [ ] Sem `StateNotifier` / `provider` / `bloc` em código novo
- [ ] Endpoints só em `lib/core/api/api_endpoints.dart`
- [ ] `flutter test` verde

Documentação: [docs/architecture/README.md](../docs/architecture/README.md)
