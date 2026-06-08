enum TechniqueType {
  normal,
  warmup,
  drop,
  cluster,
  restPause,
  superset;

  String get apiValue {
    switch (this) {
      case TechniqueType.normal:
        return 'NORMAL';
      case TechniqueType.warmup:
        return 'WARMUP';
      case TechniqueType.drop:
        return 'DROP';
      case TechniqueType.cluster:
        return 'CLUSTER';
      case TechniqueType.restPause:
        return 'REST_PAUSE';
      case TechniqueType.superset:
        return 'SUPERSET';
    }
  }

  static TechniqueType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'WARMUP':
        return TechniqueType.warmup;
      case 'DROP':
        return TechniqueType.drop;
      case 'CLUSTER':
        return TechniqueType.cluster;
      case 'REST_PAUSE':
        return TechniqueType.restPause;
      case 'SUPERSET':
        return TechniqueType.superset;
      case 'NORMAL':
      default:
        return TechniqueType.normal;
    }
  }

  String get displayLabel {
    switch (this) {
      case TechniqueType.normal:
        return '';
      case TechniqueType.warmup:
        return 'AQUECIMENTO';
      case TechniqueType.drop:
        return 'DROP SET';
      case TechniqueType.cluster:
        return 'CLUSTER SET';
      case TechniqueType.restPause:
        return 'REST PAUSE';
      case TechniqueType.superset:
        return 'SUPERSET';
    }
  }

  bool get isGrouped =>
      this != TechniqueType.normal;
}
