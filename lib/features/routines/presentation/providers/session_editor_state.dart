import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/routine.dart';
import '../../domain/entities/search_exercise.dart';
import 'session_selection_provider.dart';

/// Snapshot do formulário de sessão para diff local vs servidor.
class SessionEditorSnapshot {
  final String name;
  final List<String> muscles;
  final List<String> exerciseIds;

  const SessionEditorSnapshot({
    required this.name,
    required this.muscles,
    required this.exerciseIds,
  });

  factory SessionEditorSnapshot.empty() {
    return const SessionEditorSnapshot(name: '', muscles: [], exerciseIds: []);
  }

  factory SessionEditorSnapshot.fromSession(Session session) {
    return SessionEditorSnapshot(
      name: session.name.trim(),
      muscles: _normalizeMuscles(session.muscles),
      exerciseIds: session.exercises.map((e) => e.exerciseId).toList(),
    );
  }

  factory SessionEditorSnapshot.fromForm({
    required String name,
    required String musclesText,
    required List<SearchExercise> exercises,
  }) {
    return SessionEditorSnapshot(
      name: name.trim(),
      muscles: _normalizeMusclesFromText(musclesText),
      exerciseIds: exercises.map((e) => e.id).toList(),
    );
  }

  bool isValidToSave() => name.isNotEmpty && exerciseIds.isNotEmpty;

  bool hasChangesFrom(SessionEditorSnapshot baseline) {
    return name != baseline.name ||
        !listEquals(muscles, baseline.muscles) ||
        !listEquals(exerciseIds, baseline.exerciseIds);
  }

  static List<String> _normalizeMuscles(List<String> raw) {
    return raw
        .map((m) => m.trim().toLowerCase())
        .where((m) => m.isNotEmpty)
        .toList()
      ..sort();
  }

  static List<String> _normalizeMusclesFromText(String text) {
    return _normalizeMuscles(
      text.split(',').map((m) => m.trim()).where((m) => m.isNotEmpty).toList(),
    );
  }
}

/// Estado salvo no servidor (ou vazio para nova sessão).
final sessionEditorBaselineProvider =
    StateProvider.autoDispose<SessionEditorSnapshot?>((ref) => null);

/// Nome da sessão no formulário (sincronizado com TextField).
final sessionEditorNameProvider = StateProvider.autoDispose<String>((ref) => '');

/// Músculos da sessão como texto (sincronizado com controller interno).
final sessionEditorMusclesTextProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// true = nova sessão; false = editando sessão existente.
final sessionEditorIsNewProvider =
    StateProvider.autoDispose<bool>((ref) => true);

/// Se o botão Salvar deve ficar habilitado (form válido + mudanças em edição).
final sessionEditorCanSaveProvider = Provider.autoDispose<bool>((ref) {
  final baseline = ref.watch(sessionEditorBaselineProvider);
  if (baseline == null) return false;

  final current = SessionEditorSnapshot.fromForm(
    name: ref.watch(sessionEditorNameProvider),
    musclesText: ref.watch(sessionEditorMusclesTextProvider),
    exercises: ref.watch(sessionAllExercisesProvider),
  );

  final isNew = ref.watch(sessionEditorIsNewProvider);
  return current.isValidToSave() &&
      (isNew || current.hasChangesFrom(baseline));
});
