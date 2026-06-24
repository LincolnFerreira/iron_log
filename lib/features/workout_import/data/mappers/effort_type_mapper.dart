import '../../domain/entities/effort_type.dart';

class EffortTypeMapper {
  static Map<String, dynamic> toSerieLogFields(EffortType type, {bool? isFailure}) {
    final failure = isFailure == true || type == EffortType.failure;
    switch (type) {
      case EffortType.warmup:
        return {'label': 'Warm-up', 'setType': 'warmup', 'isFailure': failure};
      case EffortType.feeder:
        return {'label': 'Feeder', 'setType': 'feeder', 'isFailure': failure};
      case EffortType.work:
        return {'label': 'Top Set', 'setType': 'work', 'isFailure': failure};
      case EffortType.failure:
        return {'label': null, 'setType': 'failure', 'isFailure': true};
      case EffortType.uncertain:
        return {'label': null, 'setType': 'uncertain', 'isFailure': failure};
    }
  }
}
