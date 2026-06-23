# Contract: Riverpod Conventions

**Type**: Internal architecture governance  
**Feature**: `006-flutter-architecture-standard`  
**Stack**: `flutter_riverpod` ^2.6, `riverpod_annotation`, `riverpod_generator`

## Rule 1 — State ≠ Dependency Injection

| Role | Provider examples | In UI | In notifier method |
|------|-------------------|-------|-------------------|
| State | `authControllerProvider`, `homeProvider` | `ref.watch` | `state = ...` |
| DI | `routineRepositoryProvider`, `httpServiceProvider` | **never watch** | `ref.read` |

## Code new (MUST)

```dart
@riverpod
class ExampleController extends _$ExampleController {
  @override
  Future<ExampleState> build() async => ExampleState.initial();

  Future<void> submit() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final exampleRepository = ref.read(exampleRepositoryProvider);
      return exampleRepository.submit();
    });
  }
}
```

```dart
// UI
final exampleState = ref.watch(exampleControllerProvider);
ref.listen(exampleControllerProvider, (previous, next) {
  next.whenOrNull(
    error: (error, stack) => AppSnackbar.showError(context, message: ...),
  );
});
```

## Code legacy (allowed until migrated)

- `StateNotifier` + `StateNotifierProvider` in existing files.
- MUST NOT add new `StateNotifier` classes.
- Migrate to `@riverpod` `AsyncNotifier` when file is already being changed (small PR).

## Prohibited (new code)

- `package:provider`, `flutter_bloc`, `ChangeNotifier`, GetIt.
- `ref.watch(anyRepositoryProvider)` in widgets.
- `ScaffoldMessenger` / `AppSnackbar` side-effects inside `build` without `ref.listen`.
- Opaque variable names: `m`, `svc`, `repo` without domain prefix.

## Provider kinds

| Annotation | Use case |
|------------|----------|
| `@riverpod` class extends `_$X` (async build) | Business controllers |
| `@riverpod` class extends `_$X` (sync build) | UI flags, filters |
| `@riverpod Future<T> fn(Ref ref)` | Simple cached reads |
| `@riverpod Future<T> fn(Ref ref, String id)` | Family / route params |
| `@Riverpod(keepAlive: true)` | Auth session, HTTP, DB, repo DI |
| default codegen | autoDispose for screen-scoped |

## Testing

```dart
ProviderScope(
  overrides: [
    routineRepositoryProvider.overrideWithValue(mockRepository),
    ...getTestProviderOverrides(),
  ],
  child: MaterialApp(home: UnderTest()),
);
```

MUST override repository providers — not mock Dio in widget tests when repository abstraction exists.

## Boot

```dart
ProviderScope(
  observers: kDebugMode ? [AppProviderObserver()] : [],
  overrides: [
    ...routineProvidersOverrides,
    ...workoutDraftProvidersOverrides,
  ],
  child: const MyApp(),
);
```
