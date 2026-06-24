import '../../domain/entities/effort_type.dart';
import '../../domain/entities/parsed_workout_import.dart';
import '../../domain/repositories/workout_import_repository.dart';
import '../datasources/workout_import_local_datasource.dart';
import '../datasources/workout_import_remote_datasource.dart';

class WorkoutImportRepositoryImpl implements WorkoutImportRepository {
  WorkoutImportRepositoryImpl({
    required WorkoutImportLocalDataSource local,
    required WorkoutImportRemoteDataSource remote,
  })  : _local = local,
        _remote = remote;

  final WorkoutImportLocalDataSource _local;
  final WorkoutImportRemoteDataSource _remote;

  @override
  Future<WorkoutImportDraft> parseText(String rawText, String userId) async {
    final draftId = 'import_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();

    var draft = WorkoutImportDraft(
      id: draftId,
      userId: userId,
      status: ImportDraftStatus.parsing,
      rawText: rawText,
      snapshot: const ParsedWorkoutImport(sessions: []),
      createdAt: now,
      updatedAt: now,
    );
    await _local.upsertDraft(draft);

    try {
      final result = await _remote.parse(rawText: rawText);
      draft = draft.copyWith(
        importId: result.importId,
        status: ImportDraftStatus.reviewing,
        snapshot: result.parsed,
        updatedAt: DateTime.now(),
        lastError: null,
      );
      await _local.upsertDraft(draft);
      return draft;
    } catch (e) {
      draft = draft.copyWith(
        status: ImportDraftStatus.draft,
        lastError: e.toString(),
        updatedAt: DateTime.now(),
      );
      await _local.upsertDraft(draft);
      rethrow;
    }
  }

  @override
  Future<WorkoutImportDraft?> getDraft(String draftId) =>
      _local.findById(draftId);

  @override
  Future<List<WorkoutImportDraft>> listActiveDrafts(String userId) =>
      _local.findByStatus(userId, {
        ImportDraftStatus.draft,
        ImportDraftStatus.parsing,
        ImportDraftStatus.reviewing,
      });

  @override
  Future<void> saveReviewEdits(
    String draftId,
    ParsedWorkoutImport snapshot,
  ) async {
    final existing = await _local.findById(draftId);
    if (existing == null) return;
    await _local.upsertDraft(
      existing.copyWith(
        snapshot: snapshot,
        status: ImportDraftStatus.reviewing,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<WorkoutImportConfirmResult> confirm(String draftId) async {
    final draft = await _local.findById(draftId);
    if (draft == null) {
      throw StateError('Rascunho não encontrado');
    }
    if (draft.importId == null) {
      throw StateError('Importação remota ausente');
    }

    await _local.upsertDraft(
      draft.copyWith(
        status: ImportDraftStatus.confirming,
        updatedAt: DateTime.now(),
      ),
    );

    final result = await _remote.confirm(
      importId: draft.importId!,
      snapshot: draft.snapshot,
    );

    await _local.upsertDraft(
      draft.copyWith(
        status: ImportDraftStatus.confirmed,
        updatedAt: DateTime.now(),
      ),
    );

    return result;
  }

  @override
  Future<void> discard(String draftId) async {
    final draft = await _local.findById(draftId);
    if (draft == null) return;
    await _local.upsertDraft(
      draft.copyWith(
        status: ImportDraftStatus.discarded,
        updatedAt: DateTime.now(),
      ),
    );
    await _local.deleteDraft(draftId);
  }
}
