/// Extension methods for String manipulation
extension StringExtensions on String {
  /// Converts a string to Title Case (capitalize first letter of each word)
  /// Example: "bench press" → "Bench Press"
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
