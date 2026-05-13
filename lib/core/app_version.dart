/// Release label when [PackageInfo] is unavailable (e.g. hot reload after adding a plugin).
/// Keep in sync with `pubspec.yaml` → `version:` (name + build).
class AppVersion {
  AppVersion._();

  static const String version = '1.0.1';
  static const String buildNumber = '1';

  static String get label => 'IronLog v$version ($buildNumber)';
}
