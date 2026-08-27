# Contract: State patterns (010)

**Type**: Internal UI/state governance  
**Feature**: `010-state-management-audit`  
**Extends**: 006 `contracts/riverpod-conventions.md`

## Pattern 1 — Page + controller + listener

**When**: Tela principal com operações async e feedback ao usuário.

**Variant A — `AsyncNotifier` + `AsyncValue`** (código novo codegen):

```dart
ref.listen(exampleControllerProvider, (previous, next) {
  next.whenOrNull(
    error: (error, _) => AppSnackbar.showError(context, message: ...),
  );
});
final asyncState = ref.watch(exampleControllerProvider);
```

**Variant B — `Notifier` + estado síncrono com `AuthFeedback`** (ex.: auth):

```dart
ref.listen(authControllerProvider.select((s) => s.feedback), (previous, next) {
  if (next == null) return;
  // AppSnackbar por next.kind
  ref.read(authControllerProvider.notifier).clearFeedback();
});
final isSigningIn = ref.watch(authControllerProvider.select((s) => s.isSigningIn));
```

**Variant B — `Notifier` + feedback no estado** (ex.: auth, workout day):

```dart
ref.listen(workoutUiFeedbackProvider, (previous, next) {
  if (next == null) return;
  // AppSnackbar por next.kind
  ref.read(workoutUiFeedbackProvider.notifier).clear();
});
```

**Reference implementations**:
- `lib/features/auth/presentation/pages/login_screen.dart`
- `lib/features/workout_day/presentation/pages/workout_day_screen.dart`

**MUST**:

- `ref.listen` no `build` do State que possui `context` (Riverpod deduplica)
- `ref.watch` só para rebuild de UI
- Loading de submit via `AsyncValue` do controller — MUST NOT `_isLoading` paralelo

**MUST NOT**:

- `AppSnackbar` / `ScaffoldMessenger` dentro de `build` **sem** `ref.listen` quando reage a provider
- `ref.watch(repositoryProvider)` na page

---

## Pattern 2 — Bottom sheet / modal

**When**: Sheet dispara ação async e precisa feedback.

**Option A (preferred)**: Sheet recebe callback; page pai registra `ref.listen`.

**Option B**: Sheet é `ConsumerStatefulWidget`; registra `ref.listen` no próprio build; fecha sheet antes de navegação global.

```dart
ref.listen(createRestDayProvider, (prev, next) {
  next.whenOrNull(
    data: (_) {
      if (context.mounted) Navigator.of(context).pop();
    },
    error: (e, _) => AppSnackbar.showError(context, message: ...),
  );
});
```

**MUST NOT**: `ScaffoldMessenger.of(context)` após `await` sem `context.mounted`.

---

## Pattern 3 — Rebuild isolado (timer / métrica)

**When**: Parte da UI atualiza frequentemente sem rebuildar a tela inteira.

**Reference**: `elapsedTimeProvider` + widget filho que só watch esse provider.

```dart
class ElapsedBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(elapsedTimeProvider);
    return Text(formatDuration(elapsed));
  }
}
```

---

## Pattern 4 — `.select` para campo único

**When**: Widget usa um campo de estado grande.

```dart
final userName = ref.watch(
  userProfileProvider.select((p) => p.valueOrNull?.displayName),
);
```

**Reference**: `home_template.dart`, `home_header_providers.dart`.

---

## Pattern 5 — DI wiring (feature root)

```dart
final exampleRepositoryOverride = exampleRepositoryProvider.overrideWith(
  (ref) => ref.read(exampleRepositoryProviderImpl), // read, NOT watch
);
```

---

## setState decision tree

```text
Estado muda dados persistidos ou compartilhados entre widgets?
  YES → Provider/Notifier
  NO → É só UI efêmera (drag, expand, focus)?
    YES → setState OK (documentar se não óbvio)
    NO → Reavaliar — provavelmente provider
```

---

## Testing snippet

```dart
testWidgets('shows error snackbar on controller failure', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exampleRepositoryProvider.overrideWithValue(mockFailingRepo),
        ...getTestProviderOverrides(),
      ],
      child: const MaterialApp(home: ExamplePage()),
    ),
  );
  await tester.tap(find.byKey(Key('submit')));
  await tester.pumpAndSettle();
  expect(find.text('...'), findsOneWidget);
});
```

MUST override repository — not intercept snackbar implementation detail unless testing listener wiring.
