import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iron_log/core/services/speech_to_text_service.dart';
import 'package:iron_log/features/workout_day/data/parsers/voice_to_workout_parser.dart';
import 'package:iron_log/features/workout_day/data/models/voice_parsed_result.dart';
import 'package:iron_log/core/database/app_database.dart';
import 'package:iron_log/features/workout_day/data/repositories/local_workout_repository.dart';
import 'package:iron_log/core/services/auth_service.dart';
import 'package:iron_log/features/workout_day/presentation/providers/workout_day_provider.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/weight_unit.dart';

enum VoiceInputStatus {
  idle,
  recording,
  transcribing,
  preview,
  saving,
  saved,
  error,
}

class VoiceInputState {
  final VoiceInputStatus status;
  final String transcript;
  final List<ParsedExercise> parsed; // original parser output
  final List<ResolvedParsedExercise> resolved; // mapping to session exercises
  final String? error;
  final bool isContinuous;
  final double amplitude;

  VoiceInputState({
    required this.status,
    this.transcript = '',
    this.parsed = const [],
    this.resolved = const [],
    this.error,
    this.isContinuous = false,
    this.amplitude = 0.0,
  });

  VoiceInputState copyWith({
    VoiceInputStatus? status,
    String? transcript,
    List<ParsedExercise>? parsed,
    List<ResolvedParsedExercise>? resolved,
    String? error,
    bool? isContinuous,
    double? amplitude,
  }) {
    return VoiceInputState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      parsed: parsed ?? this.parsed,
      resolved: resolved ?? this.resolved,
      error: error ?? this.error,
      isContinuous: isContinuous ?? this.isContinuous,
      amplitude: amplitude ?? this.amplitude,
    );
  }
}

class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  final SpeechToTextService _speech;
  final Ref _ref;
  StreamSubscription? _sub;
  StreamSubscription? _levelSub;
  SpeechToTextService? _activeSpeech;

  VoiceInputNotifier(this._ref, {SpeechToTextService? speech})
    : _speech = speech ?? SpeechToTextService(),
      super(VoiceInputState(status: VoiceInputStatus.idle));

  Future<void> startRecording({
    String locale = 'pt_BR',
    bool keepListening = false,
    bool simulate = false,
    String? simulationText,
  }) async {
    state = state.copyWith(
      status: VoiceInputStatus.recording,
      transcript: '',
      parsed: [],
      resolved: [],
      isContinuous: keepListening,
    );

    final service = simulate
        ? SpeechToTextService(simulate: true, simulationText: simulationText)
        : _speech;

    _activeSpeech = service;

    await service.init();
    _sub = service.onResult.listen((event) {
      state = state.copyWith(
        status: VoiceInputStatus.transcribing,
        transcript: event.text,
      );
    });

    // listen to amplitude/level stream (normalized in provider)
    _levelSub = service.onSoundLevel.listen((level) {
      // Normalize to 0..1 range (heuristic)
      final norm = (level / 12.0).clamp(0.0, 1.0);
      state = state.copyWith(amplitude: norm);
    });
    await service.startListening(
      localeId: locale,
      keepListening: keepListening,
    );
  }

  Future<void> stopRecording() async {
    await _activeSpeech?.stopListening();
    await _sub?.cancel();
    await _levelSub?.cancel();
    final transcript = state.transcript;

    try {
      // DEBUG BREAKPOINT: log incoming transcript before parsing
      // Use console logs as a breakpoint substitute so you can inspect
      // what's arriving from the ASR in CI/dev runs.
      print('DEBUG: stopRecording() transcript=<$transcript>');

      final parsed = VoiceToWorkoutParser.parse(transcript);

      // DEBUG: log parsed output
      print('DEBUG: parser returned ${parsed.length} exercise(s)');
      for (var i = 0; i < parsed.length; i++) {
        final p = parsed[i];
        print(
          'DEBUG: parsed[$i] name=${p.name} weights=${p.weights} reps=${p.reps} notes=${p.notes}',
        );
      }

      // Attempt to auto-resolve against current session exercises
      final resolved = _attemptResolve(parsed, transcript);

      // DEBUG: log resolution results
      print('DEBUG: resolution returned ${resolved.length} item(s)');
      for (var i = 0; i < resolved.length; i++) {
        final r = resolved[i];
        print(
          'DEBUG: resolved[$i] name=${r.parsed.name} isResolved=${r.isResolved} matchedId=${r.matchedExerciseId} matchedName=${r.matchedExerciseName} candidates=${r.candidates}',
        );
      }

      state = state.copyWith(
        status: VoiceInputStatus.preview,
        parsed: parsed,
        resolved: resolved,
        isContinuous: false,
        amplitude: 0.0,
      );
    } catch (e) {
      print('DEBUG: stopRecording() parser error: $e');
      state = state.copyWith(
        status: VoiceInputStatus.error,
        error: e.toString(),
      );
    } finally {
      // dispose temporary simulation service if one was used
      if (_activeSpeech != null && _activeSpeech != _speech) {
        try {
          _activeSpeech?.dispose();
        } catch (_) {}
      }
      _activeSpeech = null;
    }
  }

  /// Attempt to resolve parsed exercises to session exercises using context
  List<ResolvedParsedExercise> _attemptResolve(
    List<ParsedExercise> parsed,
    String transcript,
  ) {
    final List<ResolvedParsedExercise> result = [];

    // Read current session exercises from provider (if available)
    final asyncExercises = _ref.read(workoutDayExercisesProvider);
    final List<WorkoutExercise> sessionExercises =
        asyncExercises is AsyncData<List<WorkoutExercise>>
        ? asyncExercises.value
        : [];

    final normalizedTranscript = _normalize(transcript);

    for (final p in parsed) {
      final r = ResolvedParsedExercise(parsed: p, candidates: []);

      // Try alias match
      final match = _matchByAlias(normalizedTranscript, sessionExercises);
      if (match != null) {
        r.matchedExerciseId = match.id;
        r.matchedExerciseName = match.name;
      } else {
        // Try index-based match
        final indexMatch = _matchByIndex(
          normalizedTranscript,
          sessionExercises,
        );
        if (indexMatch != null) {
          r.matchedExerciseId = indexMatch.id;
          r.matchedExerciseName = indexMatch.name;
        } else {
          // build candidate list for user selection
          r.candidates = sessionExercises
              .map((e) => {'id': e.id, 'name': e.name})
              .toList();
        }
      }

      result.add(r);
    }

    return result;
  }

  String _normalize(String s) {
    final lower = s.toLowerCase();
    // Basic diacritics removal for Portuguese (small set)
    final map = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
    };
    var out = lower;
    map.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    return out;
  }

  List<String> _generateAliases(String name) {
    final n = _normalize(name);
    final words = n.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final aliases = <String>{n};
    if (words.isNotEmpty) aliases.add(words.first);
    if (words.length > 1) aliases.add('${words[0]} ${words[1]}');
    return aliases.toList();
  }

  WorkoutExercise? _matchByAlias(
    String transcript,
    List<WorkoutExercise> exercises,
  ) {
    final t = _normalize(transcript);
    for (final ex in exercises) {
      final aliases = _generateAliases(ex.name);
      for (final a in aliases) {
        if (t.contains(a)) return ex;
      }
    }
    return null;
  }

  WorkoutExercise? _matchByIndex(
    String transcript,
    List<WorkoutExercise> exercises,
  ) {
    final t = _normalize(transcript);
    // numeric index
    final numMatch = RegExp(r'\b(\d+)\b').firstMatch(t);
    if (numMatch != null) {
      final idx = int.tryParse(numMatch.group(1)!) ?? -1;
      if (idx > 0 && idx <= exercises.length) return exercises[idx - 1];
    }

    // textual first/second/third
    final wordsMap = {
      'primeiro': 1,
      'segundo': 2,
      'terceiro': 3,
      'quarto': 4,
      'quinto': 5,
    };
    for (final key in wordsMap.keys) {
      if (t.contains(key)) {
        final idx = wordsMap[key]!;
        if (idx > 0 && idx <= exercises.length) return exercises[idx - 1];
      }
    }

    return null;
  }

  /// Assign a specific session exercise to a parsed result index.
  void assignExercise(int parsedIndex, String exerciseId, String exerciseName) {
    final current = state;
    final resolved = List<ResolvedParsedExercise>.from(current.resolved);
    if (parsedIndex < 0 || parsedIndex >= resolved.length) return;
    final item = resolved[parsedIndex];
    item.matchedExerciseId = exerciseId;
    item.matchedExerciseName = exerciseName;
    state = state.copyWith(resolved: resolved);
  }

  Future<String> confirmAndSave({
    String? sessionId,
    String? routineId,
    DateTime? startedAt,
    DateTime? endedAt,
  }) async {
    state = state.copyWith(status: VoiceInputStatus.saving);

    final db = AppDatabase();
    final repo = LocalWorkoutRepository(db);

    // Try to get current user id from AuthService (firebase UID or profile id)
    final auth = AuthService();
    final currentUser = auth.currentUser;
    final userId = currentUser?.uid ?? '';

    try {
      // If there are session exercises available, require resolution for each parsed entry
      final asyncExercises = _ref.read(workoutDayExercisesProvider);
      final sessionExercises =
          asyncExercises is AsyncData<List<WorkoutExercise>>
          ? asyncExercises.value
          : [];

      if (sessionExercises.isNotEmpty) {
        final unresolved = state.resolved.where((r) => !r.isResolved).toList();
        if (unresolved.isNotEmpty) {
          throw Exception(
            'Existem exercícios não mapeados. Por favor, selecione antes de salvar.',
          );
        }
      }

      // Save passing the resolved mapping and the session template id
      final sid = await repo.saveWorkoutLocal(
        userId: userId,
        sessionTemplateId: sessionId,
        routineId: routineId,
        startedAt: startedAt ?? DateTime.now(),
        endedAt: endedAt ?? DateTime.now(),
        exercises: state.resolved,
      );

      state = state.copyWith(status: VoiceInputStatus.saved);
      return sid;
    } catch (e) {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        error: e.toString(),
      );
      rethrow;
    } finally {
      try {
        db.close();
      } catch (_) {}
    }
  }

  Future<void> reRecord() async {
    // Reset state to allow a new recording session
    state = VoiceInputState(
      status: VoiceInputStatus.idle,
      isContinuous: false,
      amplitude: 0.0,
    );
  }

  /// Applies the parsed & resolved voice input to the visible screen inputs
  /// without persisting to the local database. This populates the exercises'
  /// `entries` so the UI fields are auto-filled for user verification.
  Future<void> applyParsedToInputs({
    String? sessionId,
    Map<int, List<SeriesEntry>>? seriesOverrides,
  }) async {
    state = state.copyWith(status: VoiceInputStatus.saving);

    // Read current session exercises from provider (if available)
    final asyncExercises = _ref.read(workoutDayExercisesProvider);
    final List<WorkoutExercise> sessionExercises =
        asyncExercises is AsyncData<List<WorkoutExercise>>
        ? asyncExercises.value
        : [];

    // If there are session exercises, require all parsed items to be mapped
    if (sessionExercises.isNotEmpty) {
      final unresolved = state.resolved.where((r) => !r.isResolved).toList();
      if (unresolved.isNotEmpty) {
        state = state.copyWith(
          status: VoiceInputStatus.error,
          error:
              'Existem exercícios não mapeados. Por favor, selecione antes de aplicar.',
        );
        throw Exception(
          'Existem exercícios não mapeados. Por favor, selecione antes de aplicar.',
        );
      }
    }

    try {
      final mode = _ref.read(workoutScreenModeProvider);
      final notifier = _ref.read(workoutDayExercisesProvider.notifier);

      for (var rIdx = 0; rIdx < state.resolved.length; rIdx++) {
        final resolved = state.resolved[rIdx];
        // Build SeriesEntry list from parsed weights/reps or overrides if provided
        final parsed = resolved.parsed;
        List<SeriesEntry> entries = [];
        if (seriesOverrides != null && seriesOverrides.containsKey(rIdx)) {
          entries = List<SeriesEntry>.from(seriesOverrides[rIdx]!);
        } else {
          for (var i = 0; i < parsed.weights.length; i++) {
            final w = parsed.weights[i];
            // Format weight as simple string (no trailing .0 when integer)
            final weightStr = (w % 1 == 0)
                ? w.toInt().toString()
                : w.toString();
            final repsStr = (parsed.reps.length > i)
                ? parsed.reps[i].toString()
                : '';
            entries.add(
              SeriesEntry(index: i, weight: weightStr, reps: repsStr),
            );
          }
        }

        if (resolved.isResolved) {
          final exId = resolved.matchedExerciseId!;
          final existing = sessionExercises.firstWhere(
            (e) => e.id == exId,
            orElse: () => null as WorkoutExercise,
          );

          final updated = existing.copyWith(
            entries: entries,
            series: entries.length,
            weight: entries.isNotEmpty ? entries[0].weight : existing.weight,
            reps: entries.isNotEmpty ? entries[0].reps : existing.reps,
            weightUnit: WeightUnit.fromString(parsed.weightUnit),
            notes: parsed.notes.isEmpty ? existing.notes : parsed.notes,
          );

          // Call provider method according to current screen mode
          if (mode == null) {
            notifier.updateExercise(exId, updated);
          } else if (mode.toString().contains('execution')) {
            notifier.updateExerciseExecution(exId, updated);
          } else if (mode.toString().contains('template')) {
            notifier.updateExerciseTemplate(exId, updated);
          } else if (mode.toString().contains('editing')) {
            notifier.updateExerciseLog(exId, updated);
          } else {
            notifier.updateExercise(exId, updated);
          }
        } else {
          // No session mapping available: create a new local exercise for preview
          final newId = DateTime.now().millisecondsSinceEpoch.toString();
          final newEx = WorkoutExercise(
            id: newId,
            name: parsed.name,
            tag: ExerciseTag.multi,
            muscles: '',
            variation: 'Traditional',
            series: entries.length,
            reps: entries.isNotEmpty ? entries[0].reps : '-',
            weight: entries.isNotEmpty ? entries[0].weight : '0',
            rir: 2,
            restTime: 120,
            weightUnit: WeightUnit.fromString(parsed.weightUnit),
            entries: entries,
            notes: parsed.notes.isEmpty ? null : parsed.notes,
          );
          notifier.addExercise(newEx);
        }
      }

      state = state.copyWith(status: VoiceInputStatus.saved);
    } catch (e) {
      state = state.copyWith(
        status: VoiceInputStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _levelSub?.cancel();
    try {
      _activeSpeech?.dispose();
    } catch (_) {}
    try {
      _speech.dispose();
    } catch (_) {}
    super.dispose();
  }
}

final voiceInputProvider =
    StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
      return VoiceInputNotifier(ref);
    });
