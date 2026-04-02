enum WeightUnit {
  kg,
  lbs;

  String get label => name; // 'kg' or 'lbs'

  static WeightUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lbs':
        return WeightUnit.lbs;
      default:
        return WeightUnit.kg;
    }
  }
}
