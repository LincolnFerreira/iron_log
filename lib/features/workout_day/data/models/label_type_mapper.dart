/// Converts between different representations of series labels and types
abstract class LabelTypeMapper {
  /// Converts a backend label string to the integer type used by [SeriesEntry]
  /// - 0: Warm-up
  /// - 1: Feeder
  /// - 2: Top Set (default)
  /// - 3: Back-Off
  static int labelToType(String? label) {
    if (label == null) return 2; // default to Top Set

    switch (label.toLowerCase()) {
      case 'warm-up':
      case 'warmup':
      case 'aquecimento':
        return 0;
      case 'feeder':
      case 'prep':
      case 'preparação':
        return 1;
      case 'back-off':
      case 'backoff':
      case 'back off':
        return 3;
      case 'top set':
      case 'topset':
      case 'trabalho':
      default:
        return 2;
    }
  }

  /// Converts type integer back to display label
  static String typeToLabel(int type) {
    switch (type) {
      case 0:
        return 'Warm-up';
      case 1:
        return 'Feeder';
      case 3:
        return 'Back-Off';
      case 2:
      default:
        return 'Top Set';
    }
  }
}
