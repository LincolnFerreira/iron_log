enum EffortType { warmup, feeder, work, failure, uncertain }

enum ConfidenceLevel { high, medium, low, undetermined }

enum ImportDraftStatus {
  draft,
  parsing,
  reviewing,
  confirming,
  confirmed,
  discarded,
}

extension EffortTypeX on EffortType {
  String get apiValue => name;

  static EffortType fromApi(String? value) {
    return EffortType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EffortType.uncertain,
    );
  }

  String get labelPt {
    switch (this) {
      case EffortType.warmup:
        return 'Aquecimento';
      case EffortType.feeder:
        return 'Preparatória';
      case EffortType.work:
        return 'Válida';
      case EffortType.failure:
        return 'Falha';
      case EffortType.uncertain:
        return 'Incerto';
    }
  }
}

extension ConfidenceLevelX on ConfidenceLevel {
  static ConfidenceLevel fromApi(String? value) {
    if (value == null) return ConfidenceLevel.undetermined;
    return ConfidenceLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ConfidenceLevel.undetermined,
    );
  }
}
