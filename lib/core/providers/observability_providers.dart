import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iron_log/core/observability/crash_reporting_service.dart';

final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  return CrashReportingService();
});
