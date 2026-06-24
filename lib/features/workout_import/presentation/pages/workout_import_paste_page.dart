import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/core/services/http_error_handler.dart';
import 'package:iron_log/core/routes/workout_route_locations.dart';
import 'package:iron_log/features/auth/auth.dart';

import '../providers/workout_import_providers.dart';

class WorkoutImportPastePage extends ConsumerStatefulWidget {
  const WorkoutImportPastePage({super.key});

  @override
  ConsumerState<WorkoutImportPastePage> createState() =>
      _WorkoutImportPastePageState();
}

class _WorkoutImportPastePageState extends ConsumerState<WorkoutImportPastePage> {
  static const _maxChars = 16000;
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show(context: context, type: AppSnackbarType.warning, title: 'Atenção', message: 'Cole o texto do treino para continuar');
      return;
    }
    final userId = ref.read(authStateProvider).user?.uid;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      final draft = await ref
          .read(workoutImportRepositoryProvider)
          .parseText(text, userId);
      if (!mounted) return;
      context.push(WorkoutRouteLocations.importReview(draft.id));
    } on DioException catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        type: AppSnackbarType.error,
        title: 'Erro',
        message: HttpErrorHandler.getUserFriendlyMessage(e),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        type: AppSnackbarType.error,
        title: 'Erro',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final length = _controller.text.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Importar de texto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cole seu treino (WhatsApp, notas, etc.)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                maxLength: _maxChars,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Upper 1\nSupino 20x15...',
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('$length / $_maxChars'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Interpretar'),
            ),
          ],
        ),
      ),
    );
  }
}
