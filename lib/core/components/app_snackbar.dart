import 'package:flutter/material.dart';

enum AppSnackbarType { success, warning, error }

final class AppSnackbar {
  static void success({
    required BuildContext context,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context: context,
      type: AppSnackbarType.success,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void warning({
    required BuildContext context,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context: context,
      type: AppSnackbarType.warning,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error({
    required BuildContext context,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context: context,
      type: AppSnackbarType.error,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void show({
    required BuildContext context,
    required AppSnackbarType type,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        content: _AppSnackbarContent(
          type: type,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }

  static Future<void> showExamplesDialog(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15181E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .06)
                  : Colors.black.withValues(alpha: .06),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Testar alertas',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              _ExampleButton(
                label: 'Sucesso',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  success(
                    context: context,
                    title: 'Treino salvo',
                    message: 'Seu progresso foi sincronizado.',
                    actionLabel: 'Ver',
                    onAction: () {},
                  );
                },
              ),
              const SizedBox(height: 10),
              _ExampleButton(
                label: 'Atenção',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  warning(
                    context: context,
                    title: 'Conexão instável',
                    message: 'Algumas ações podem demorar mais.',
                  );
                },
              ),
              const SizedBox(height: 10),
              _ExampleButton(
                label: 'Erro',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  error(
                    context: context,
                    title: 'Erro ao finalizar treino',
                    message: 'Tentaremos novamente automaticamente.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExampleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExampleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(46),
        ),
        child: Text(label),
      ),
    );
  }
}

class _AppSnackbarContent extends StatelessWidget {
  final AppSnackbarType type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AppSnackbarContent({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = _palette(type);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1D2430)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .05)
              : Colors.black.withValues(alpha: .06),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: palette.bg,
            ),
            child: Icon(palette.icon, size: 20, color: palette.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF98A2B3)
                            : const Color(0xFF667085),
                      ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  actionLabel!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8AB4FF),
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _SnackbarPalette _palette(AppSnackbarType kind) {
    switch (kind) {
      case AppSnackbarType.success:
        return const _SnackbarPalette(
          icon: Icons.check_rounded,
          fg: Color(0xFF22C55E),
          bg: Color(0x1F22C55E),
        );
      case AppSnackbarType.warning:
        return const _SnackbarPalette(
          icon: Icons.warning_amber_rounded,
          fg: Color(0xFFFBBF24),
          bg: Color(0x1FFBBF24),
        );
      case AppSnackbarType.error:
        return const _SnackbarPalette(
          icon: Icons.error_outline_rounded,
          fg: Color(0xFFEF4444),
          bg: Color(0x1FEF4444),
        );
    }
  }
}

class _SnackbarPalette {
  final IconData icon;
  final Color fg;
  final Color bg;

  const _SnackbarPalette({
    required this.icon,
    required this.fg,
    required this.bg,
  });
}
