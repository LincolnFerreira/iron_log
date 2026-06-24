import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_import/data/mappers/effort_type_mapper.dart';
import 'package:iron_log/features/workout_import/domain/entities/effort_type.dart';

void main() {
  test('maps warmup effort to serie fields', () {
    final fields = EffortTypeMapper.toSerieLogFields(EffortType.warmup);
    expect(fields['setType'], 'warmup');
    expect(fields['label'], 'Warm-up');
  });

  test('maps failure effort', () {
    final fields = EffortTypeMapper.toSerieLogFields(EffortType.failure);
    expect(fields['isFailure'], true);
    expect(fields['setType'], 'failure');
  });
}
