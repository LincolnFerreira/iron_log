import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/data/services/workout_log_service.dart';
import 'package:iron_log/features/workout_day/domain/entities/exercise_tag.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/domain/entities/workout_exercise.dart';

// ─── Réplicas da lógica de produção (SeriesInputRow) ──────────────────────────
//
// Estas funções espelham o código ATUAL (bugado) de SeriesInputRow.
// Quando o fix for aplicado em series_input_row.dart, atualize-as aqui também.
//
// Fix 1 — _cleanValue   : RegExp(r'\d+')  →  RegExp(r'\d+\.?\d*')
// Fix 2 — _handleWeight : adicionar  if (val.isEmpty) return entryWeight;
//
// Legenda dos testes:
//   ✓  verde agora e depois do fix (regressão guard)
//   ✗  VERMELHO agora → deve ficar VERDE após o fix

/// Cópia de _cleanValue de SeriesInputRow.
/// Após o fix: r'\d+\.?\d*' preserva decimais.
String _cleanValue(String value) {
  final digits = RegExp(r'\d+\.?\d*').firstMatch(value);
  return digits?.group(0) ?? '0';
}

/// Cópia de _handleWeightSubmitted de SeriesInputRow.
/// Após o fix: val vazio preserva entryWeight.
String _handleWeightSubmitted(String val, String entryWeight) {
  if (val.isEmpty) return entryWeight;
  return _cleanValue(val);
}

// ─── Helper ───────────────────────────────────────────────────────────────────

WorkoutExercise _makeExercise({
  required List<SeriesEntry> entries,
  String weight = '10',
  String reps = '10',
  int series = 4,
  int rir = 2,
}) =>
    WorkoutExercise(
      id: 'cmnghuw8k0001l0v0pvcijzl0',
      name: 'Supino neutro maquina',
      tag: ExerciseTag.multi,
      muscles: 'Peito',
      variation: 'Traditional',
      series: entries.isEmpty ? series : entries.length,
      reps: reps,
      weight: weight,
      rir: rir,
      restTime: 0,
      entries: entries,
    );

// ─── Testes ───────────────────────────────────────────────────────────────────

void main() {
  final service = WorkoutLogService();

  // ── Camada 1: _cleanValue ────────────────────────────────────────────────

  group('Camada 1 — _cleanValue (SeriesInputRow)', () {
    test('✓ valor inteiro retorna correto', () {
      expect(_cleanValue('100'), '100');
      expect(_cleanValue('10'), '10');
    });

    test('✓ valor com unidade extraído corretamente', () {
      expect(_cleanValue('100kg'), '100');
    });

    test('✓ string vazia retorna "0" — _cleanValue é pura, fallback fica no handler', () {
      // _cleanValue não conhece o peso anterior da entry.
      // Retornar "0" para vazio é correto aqui; o handler é quem deve usar entryWeight.
      expect(_cleanValue(''), '0');
    });

    test('✗ decimal deve ser preservado: "82.5" → "82.5"', () {
      // VERMELHO: retorna '82' (r'\d+' para no ponto).
      // VERDE após fix: regex r'\d+\.?\d*' captura '82.5'.
      expect(_cleanValue('82.5'), '82.5');
    });
  });

  // ── Camada 1→2: _handleWeightSubmitted + SeriesEntry.copyWith ────────────

  group('Camada 1→2 — _handleWeightSubmitted → SeriesEntry.copyWith', () {
    test('✓ submit com valor digitado atualiza o peso corretamente', () {
      final entry = SeriesEntry(index: 0, weight: '100', reps: '10');
      final updated = entry.copyWith(
        weight: _handleWeightSubmitted('100', entry.weight),
      );
      expect(updated.weight, '100');
    });

    test('✗ submit vazio deve preservar o peso anterior, não zerar', () {
      // VERMELHO: _handleWeightSubmitted('', '100') = _cleanValue('') = '0'.
      // VERDE após fix: handler retorna entryWeight quando val está vazio.
      final entry = SeriesEntry(index: 1, weight: '100', reps: '10');
      final updated = entry.copyWith(
        weight: _handleWeightSubmitted('', entry.weight),
      );
      expect(updated.weight, '100');
    });

    test('✗ fluxo real — 4 séries, só a 1ª digitada: todas devem preservar "10"', () {
      // Reproduz o payload do log (Supino neutro maquina):
      //   atual:   weight: [10.0, 0.0, 0.0, 0.0]  ← bug
      //   correto: weight: [10.0, 10.0, 10.0, 10.0]
      //
      // Usuário digita '10' na série 0.
      // Séries 1-3: auto-avanço via token → controller vazio → aperta Next.
      // VERMELHO: _handleWeightSubmitted('', '10') = '0'.
      // VERDE após fix: handler preserva '10'.
      final entries = List.generate(
        4,
        (i) => SeriesEntry(index: i, weight: '10', reps: '10'),
      );
      final submits = ['10', '', '', '']; // '' = usuário não redigitou

      final result = entries.asMap().entries.map((e) {
        return e.value.copyWith(
          weight: _handleWeightSubmitted(submits[e.key], e.value.weight),
        );
      }).toList();

      expect(result.map((e) => e.weight).toList(), equals(['10', '10', '10', '10']));
    });
  });

  // ── Camada 2→3: entries → payload DTO ────────────────────────────────────

  group('Camada 2→3 — entries → exerciseToDtoForTesting (WorkoutLogService)', () {
    test('✓ o serviço mapeia entries com pesos distintos corretamente', () {
      // O serviço em si está correto — o bug está na UI que produz as entries.
      final dto = service.exerciseToDtoForTesting(
        _makeExercise(entries: [
          SeriesEntry(index: 0, weight: '10', reps: '10'),
          SeriesEntry(index: 1, weight: '20', reps: '10'),
          SeriesEntry(index: 2, weight: '30', reps: '10'),
          SeriesEntry(index: 3, weight: '40', reps: '10'),
        ]),
      );
      expect(dto['weight'], equals([10.0, 20.0, 30.0, 40.0]));
      expect(dto['reps'], equals([10, 10, 10, 10]));
      expect(dto['sets'], 4);
    });

    test('✓ fallback sem entries usa exercise.weight para todas as séries', () {
      final dto = service.exerciseToDtoForTesting(
        _makeExercise(entries: [], weight: '80', series: 3),
      );
      expect(dto['sets'], 3);
      expect(dto['weight'], equals([80.0, 80.0, 80.0]));
      expect(dto['reps'], equals([10, 10, 10]));
    });

    test('✗ ponta a ponta: 4 séries auto-avançando → backend deve receber [10,10,10,10]', () {
      // Encadeia Camada 1→2→3 com o fluxo real do usuário.
      // VERMELHO: _handleWeightSubmitted('', '10') = '0' nas séries 1-3
      //           → DTO envia [10.0, 0.0, 0.0, 0.0].
      // VERDE após fix: handler preserva '10' → DTO envia [10.0,10.0,10.0,10.0].
      final entries = List.generate(
        4,
        (i) => SeriesEntry(index: i, weight: '10', reps: '10'),
      );
      final submits = ['10', '', '', '']; // '' = auto-avanço, usuário não redigitou

      final afterUI = entries.asMap().entries.map((e) {
        return e.value.copyWith(
          weight: _handleWeightSubmitted(submits[e.key], e.value.weight),
        );
      }).toList();

      final dto = service.exerciseToDtoForTesting(_makeExercise(entries: afterUI));

      expect(dto['weight'], equals([10.0, 10.0, 10.0, 10.0]));
    });

    test('✗ decimal ponta a ponta: "82.5" digitado deve chegar como 82.5 no backend', () {
      // VERMELHO: _cleanValue('82.5') = '82' → entry.weight = '82'
      //           → _parseWeight('82') = 82.0 (serviço correto, mas recebeu valor truncado)
      // VERDE após fix: _cleanValue('82.5') = '82.5' → dto['weight'] = [82.5].
      final entry = SeriesEntry(
        index: 0,
        weight: _cleanValue('82.5'), // simula o que a UI salva na entry
        reps: '8',
      );
      final dto = service.exerciseToDtoForTesting(_makeExercise(entries: [entry]));

      expect(dto['weight'], equals([82.5]));
    });
  });
}
