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
    │       └── widgets/
  ```

### State Management
- BLoC pattern used for complex state (`flutter_bloc`)
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

### Common Development Tasks
1. **Adding a New Feature**
   - Create directory structure under `/lib/features/`
   - Implement data, domain, and presentation layers
   - Register routes in app router

2. **Error Handling**
   - Use `ServerException` for API errors
   - Implement error states in BLoCs
   - Show user-friendly messages via SnackBar

## Testing Guidelines
- Widget tests in `/test` directory
- BLoC tests should cover all states
- Mock external dependencies (Firebase, API)

## Common Pitfalls
- Always use proper error handling in remote data sources
- Remember to register new routes in the router
- Initialize Firebase before accessing any Firebase services
- Handle loading and error states in UI components
