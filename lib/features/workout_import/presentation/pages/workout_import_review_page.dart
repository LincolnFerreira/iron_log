import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iron_log/core/components/app_snackbar.dart';
import 'package:iron_log/core/components/exercise_search/unified_exercise_search.dart';
import 'package:dio/dio.dart';
import 'package:iron_log/core/services/http_error_handler.dart';
import 'package:iron_log/features/routines/domain/entities/search_exercise.dart';

import '../providers/workout_import_controller.dart';
import '../widgets/import_exercise_tile.dart';
import '../widgets/import_session_card.dart';
import '../widgets/import_set_row.dart';
import '../widgets/import_uncertainty_banner.dart';

class WorkoutImportReviewPage extends ConsumerStatefulWidget {
  const WorkoutImportReviewPage({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<WorkoutImportReviewPage> createState() =>
      _WorkoutImportReviewPageState();
}

class _WorkoutImportReviewPageState
    extends ConsumerState<WorkoutImportReviewPage> {
  bool _listened = false;

  @override
  Widget build(BuildContext context) {
    final asyncState =
        ref.watch(workoutImportControllerProvider(widget.draftId));

    if (!_listened) {
      _listened = true;
      ref.listen(workoutImportControllerProvider(widget.draftId), (prev, next) {
        next.whenOrNull(
          error: (e, _) {
            if (!mounted) return;
            final message = e is DioException
                ? HttpErrorHandler.getUserFriendlyMessage(e)
                : e.toString();
            AppSnackbar.show(
              context: context,
              type: AppSnackbarType.error,
              title: 'Erro',
              message: message,
            );
          },
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar importação'),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(workoutImportControllerProvider(widget.draftId).notifier)
                .toggleOriginalText(),
            child: const Text('Texto original'),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          if (state == null) {
            return const Center(child: Text('Rascunho não encontrado'));
          }
          final controller = ref.read(
            workoutImportControllerProvider(widget.draftId).notifier,
          );
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ImportUncertaintyBanner(
                      unmappedFragments: state.snapshot.unmappedFragments,
                      parserWarnings: state.snapshot.parserWarnings,
                    ),
                    if (state.showOriginalText)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(state.rawText),
                        ),
                      ),
                    ...state.snapshot.sessions
                        .where((s) => !s.removed)
                        .map((session) {
                      return ImportSessionCard(
                        session: session,
                        onRemove: () => controller.removeSession(session.clientKey),
                        child: Column(
                          children: session.exercises
                              .where((e) => !e.removed)
                              .map((exercise) {
                            return ImportExerciseTile(
                              exercise: exercise,
                              onNameChanged: (name) => controller.updateExerciseName(
                                sessionKey: session.clientKey,
                                exerciseKey: exercise.clientKey,
                                name: name,
                              ),
                              onPickExercise: () => _pickExercise(
                                session.clientKey,
                                exercise.clientKey,
                              ),
                              onRemove: () => controller.removeExercise(
                                sessionKey: session.clientKey,
                                exerciseKey: exercise.clientKey,
                              ),
                              setRows: exercise.sets
                                  .map(
                                    (set) => ImportSetRow(
                                      set: set,
                                      onWeightChanged: (w) =>
                                          controller.updateSetWeight(
                                        sessionKey: session.clientKey,
                                        exerciseKey: exercise.clientKey,
                                        setKey: set.clientKey,
                                        weight: w,
                                      ),
                                      onRepsChanged: (r) =>
                                          controller.updateSetReps(
                                        sessionKey: session.clientKey,
                                        exerciseKey: exercise.clientKey,
                                        setKey: set.clientKey,
                                        reps: r,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () async {
                                  await controller.discard();
                                  if (context.mounted) context.pop();
                                },
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () async {
                                  final result = await controller.confirm();
                                  if (!context.mounted) return;
                                  if (result != null) {
                                    AppSnackbar.success(
                                      context: context,
                                      title: 'Importado',
                                      message: 'Treino(s) salvos no histórico',
                                    );
                                    context.go('/history');
                                  }
                                },
                          child: state.isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickExercise(String sessionKey, String exerciseKey) async {
    SearchExercise? picked;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: UnifiedExerciseSearch(
          onExerciseSelected: (exercise) {
            picked = exercise;
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(workoutImportControllerProvider(widget.draftId).notifier)
        .setExerciseId(
          sessionKey: sessionKey,
          exerciseKey: exerciseKey,
          exerciseId: picked!.id,
        );
  }
}
