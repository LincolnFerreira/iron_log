import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../observability/crash_reporting_service.dart';

/// Fallback quando um widget falha no build (release-friendly).
class AppErrorFallback extends StatefulWidget {
  const AppErrorFallback({
    super.key,
    required this.details,
    this.crashReporting,
  });

  final FlutterErrorDetails details;
  final CrashReportingService? crashReporting;

  @override
  State<AppErrorFallback> createState() => _AppErrorFallbackState();
}

class _AppErrorFallbackState extends State<AppErrorFallback> {
  @override
  void initState() {
    super.initState();
    widget.crashReporting?.recordWidgetError(widget.details);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDebugDetails = kDebugMode;

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Algo deu errado',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Não foi possível exibir esta parte do app. Tente voltar ou reiniciar.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray60,
                ),
                textAlign: TextAlign.center,
              ),
              if (showDebugDetails) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      '${widget.details.exception}\n${widget.details.stack}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
