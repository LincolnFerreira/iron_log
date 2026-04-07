# Rotina Provider Initialization Fix

## Problem Analysis

Two critical issues were identified:

### 1. **UnimplementedError: RoutineRepository not provided**
- **Root Cause**: The `routineRepositoryProvider` in `routine_provider.dart` was throwing an error without being overridden
- **Why It Happens**: Riverpod requires explicit provider overrides in `ProviderScope` before the app uses them
- **Impact**: Any widget accessing routines would crash during initialization

### 2. **Widget Test Failure: "Expected: exactly one matching candidate Found 0 widgets with text 'Rotina Minha Rotina'"**
- **Root Cause**: The test didn't provide the necessary provider overrides, so the widget couldn't render properly
- **Why It Happens**: Flutter tests need the full provider setup to match the production app
- **Impact**: SessionEditPage test couldn't render, provider chain failed

## Solution Implemented

### Files Updated

#### 1. **main.dart**
- Ensured `ProviderScope` applies overrides before `MyApp()` builds
- Added comments explaining the override setup

#### 2. **routine_providers.dart**
- Added better error messages
- Added documentation about usage
- Wrapped provider creation in try-catch for debugging

#### 3. **routine_provider.dart**
- Improved error message with debugging hints

#### 4. **test/helpers/test_providers_setup.dart** (NEW)
- Created `getTestProviderOverrides()` helper function
- Initializes `HttpService` properly for tests
- Ensures all provider chains are complete

#### 5. **test/features/routines/session_edit_page_test.dart**
- Updated to use `getTestProviderOverrides()` helper
- Test now properly initializes all providers before rendering

## How Provider Override Chain Works

```
ProviderScope (main.dart)
  └─ ...routineProvidersOverrides
      └─ routineRepositoryOverride
          └─ routineRepositoryProvider.overrideWith()
              └─ routineRepositoryProviderImpl
                  └─ httpServiceProvider (injected)
                      └─ HttpService (initialized)
```

## Testing the Fix

### Run the failing test:
```bash
flutter test test/features/routines/session_edit_page_test.dart
```

### Manually test in the app:
1. Run the app: `flutter run`
2. Navigate to Routines screen
3. Verify routines load without "RoutineRepository not provided" error

## Prevention Guidelines

### For Developers Adding New Features

1. **Always override abstract providers in a `*_providers.dart` file**:
   ```dart
   final myFeatureRepositoryProvider = Provider<MyRepository>((ref) {
     throw UnimplementedError('MyRepository provider must be overridden');
   });
   ```

2. **Create the implementation provider**:
   ```dart
   final myFeatureRepositoryProviderImpl = Provider<MyRepository>((ref) {
     final service = ref.watch(someServiceProvider);
     return MyRepositoryImpl(service);
   });
   ```

3. **Create the override**:
   ```dart
   final myFeatureRepositoryOverride = myFeatureRepositoryProvider.overrideWith(
     (ref) => ref.watch(myFeatureRepositoryProviderImpl),
   );
   ```

4. **Export overrides in a list**:
   ```dart
   final myFeatureProvidersOverrides = [myFeatureRepositoryOverride];
   ```

5. **Apply in main.dart**:
   ```dart
   ProviderScope(
     overrides: [
       ...myFeatureProvidersOverrides,
     ],
     child: const MyApp(),
   )
   ```

6. **Use test helper in all widget tests**:
   ```dart
   ProviderScope(
     overrides: getTestProviderOverrides(),
     child: MaterialApp(home: MyWidget()),
   )
   ```

## Debugging Provider Errors

If you ever see `UnimplementedError` with a provider name:

1. ✅ Check if the provider is overridden in `ProviderScope`
2. ✅ Verify the provider chain is complete (no missing dependencies)
3. ✅ Ensure `HttpService` is initialized (or mocked in tests)
4. ✅ Check main.dart imports the feature's `*_providers.dart` file
5. ✅ In tests, always use `getTestProviderOverrides()` or create your own

## Related Files

- `lib/features/routines/routine_providers.dart` - Provider setup
- `lib/features/routines/presentation/bloc/routine_provider.dart` - Abstract provider
- `lib/main.dart` - App initialization with ProviderScope
- `test/helpers/test_providers_setup.dart` - Test provider setup helper
- `test/features/routines/session_edit_page_test.dart` - Example test usage
