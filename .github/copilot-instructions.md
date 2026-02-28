# Iron Log - AI Agent Instructions

## Project Overview
Iron Log is a Flutter mobile application that helps users track their fitness progress. The project follows a clean architecture pattern with feature-first organization.

## Key Architecture Patterns

### Project Structure
- `/lib/features/` - Feature-first organization (auth, home, onboarding)
- `/lib/core/` - Shared functionality (colors, themes, navigation)
- Each feature follows Clean Architecture layers:
  ```
  features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/
    │   │   ├── models/
    │   │   └── repositories/
    │   ├── domain/
    │   │   ├── entities/
    │   │   ├── repositories/
    │   │   └── usecases/
    │   └── presentation/
    │       ├── bloc/
    │       ├── pages/
    │       ├── widgets/
    │       └── components/
    │           ├── atoms/
    │           ├── molecules/
    │           └── organisms/
  ```

### Clean Architecture Guidelines
**CRITICAL: Lean Architecture Approach**
- **Architecture is streamlined** - we don't need all Clean Architecture layers, but maintain organized separation
- **Always work with classes** - strongly typed entities and models
- **Entities are mandatory** - represent business objects with proper typing
- **Repositories when needed** - only for complex data operations
- **UseCases sparingly** - only for complex business logic
- **Focus on organization** over rigid layer compliance

### UI Component Organization Rules
**CRITICAL: Never create private Widget methods in classes**
- **NEVER** create private methods that return Widget in any class
- **ALWAYS** create separate component classes in individual files
- **UI components have business logic** - treat them as first-class citizens
- Components should be organized in the Atomic Design pattern:
  - `atoms/` - Basic UI elements (buttons, inputs, icons)
  - `molecules/` - Simple groups of atoms (search bars, form fields)
  - `organisms/` - Complex components made of molecules and atoms
- Private methods should only contain business logic, never UI rendering
- Each Widget should have its own file and class for better reusability and maintainability

**CRITICAL: Use proper domain entities, not Maps**
- **NEVER** use `Map<String, dynamic>` in UI layers for business data
- **ALWAYS** create proper domain entities with typed properties
- **ALWAYS** use enums for categorical data instead of strings
- UI components should work with strongly-typed entities
- Transform external data (APIs, JSON) to entities at data layer boundaries
- Example: Use `WorkoutExercise` entity instead of `Map<String, dynamic>`

**CRITICAL: Mock Data and TODOs**
- **NEVER** leave mock values in UI without TODO comments
- **ALWAYS** add TODO comments when using mock data for visualization
- **ASK** if real integration should be implemented when encountering TODOs
- **REMOVE** mock data immediately when real integration is ready

### Development Workflow Guidelines
**CRITICAL: Code Changes and Component Reuse**
- **DO NOT** change spacing, margins, or visual styling unless explicitly requested
- **ALWAYS** check for existing compatible components before creating new ones
- **REUSE** existing components when possible, extend only when necessary
- **VERIFY** that reusing components won't break existing usage
- **AVOID** code duplication - prefer composition and extension

**CRITICAL: Import Management and File Review**
- **ALWAYS** review all modified files for missing imports
- **NEVER** assume imports are correct - verify each file compiles
- **DO NOT** suggest `flutter run` commands - VS Code auto-compilation is always active
- **ASSUME** developer can see compilation errors immediately
- **FIX** import issues proactively during refactoring

### State Management
- BLoC pattern used for complex state (`flutter_bloc`)
- Riverpod used for simpler state management (`flutter_riverpod`)
- Example: See `/lib/features/auth/presentation/bloc/auth_bloc.dart`

### Navigation
- Using `go_router` for navigation
- Route definitions in `lib/core/routes/app_router.dart`

### Authentication
- Firebase Authentication integrated
- Google Sign-In support
- Repository pattern with remote data source
- See `/lib/features/auth/` for implementation

### API Integration
- Dio client for HTTP requests
- Error handling standardized in remote data sources
- See `AuthRemoteDataSourceImpl` for example patterns

## Development Workflow

### Getting Started
1. Ensure Flutter SDK (^3.8.1) is installed
2. Run `flutter pub get` to install dependencies
3. Set up Firebase project and add config files
   - Android: `/android/app/google-services.json`
   - iOS: `/ios/Runner/GoogleService-Info.plist`

### Firebase Integration
- Firebase services used: Authentication, Crashlytics
- Initialize in `main.dart`
- Firebase options in `lib/firebase_options.dart`

### Understanding Riverpod (State Management)
Riverpod follows a different pattern than GetX/BLoC:

**Provider Declaration:**
```dart
final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier();
});
```

**State Reading in Widgets:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider); // Watch for changes
    final workoutNotifier = ref.read(workoutProvider.notifier); // Read once

    return YourWidget();
  }
}
```

**Data Flow:**
1. `Provider` declares what can be provided
2. `ref.watch()` subscribes to changes (rebuilds widget)
3. `ref.read()` reads current value without subscription
4. `StateNotifier` manages state changes
5. `State` classes hold the actual data

**Key Differences from GetX:**
- No global access (everything through `ref`)
- Compile-time safety
- Explicit dependencies
- No service locator pattern

### Common Development Tasks
1. **Adding a New Feature**
   - Create directory structure under `/lib/features/`
   - Implement data, domain, and presentation layers
   - Register routes in app router
   - Create components following Atomic Design

2. **Error Handling**
   - Use `ServerException` for API errors
   - Implement error states in BLoCs
   - Show user-friendly messages via SnackBar

3. **Creating UI Components**
   - Never use private Widget methods
   - Create separate classes in individual files
   - Follow Atomic Design pattern
   - Place in appropriate `components/` subfolder

## Testing Guidelines
- Widget tests in `/test` directory
- BLoC tests should cover all states
- Mock external dependencies (Firebase, API)

## Common Pitfalls
- Always use proper error handling in remote data sources
- Remember to register new routes in the router
- Initialize Firebase before accessing any Firebase services
- Handle loading and error states in UI components
- **NEVER create private Widget methods - always use separate component classes**
- Understand Riverpod's reactive patterns vs imperative patterns from GetX
