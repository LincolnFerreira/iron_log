enum WeightUnit {
  kg,
  lbs,
  placa;

  String get label => name; // 'kg', 'lbs' or 'placa'

  static WeightUnit fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lbs':
        return WeightUnit.lbs;
      case 'placa':
        return WeightUnit.placa;
      default:
        return WeightUnit.kg;
    }
  }

  WeightUnit get next {
    const order = [WeightUnit.kg, WeightUnit.lbs, WeightUnit.placa];
    return order[(order.indexOf(this) + 1) % order.length];
  }
}
