enum SuggestionAction { increase, maintain, decrease }

extension SuggestionActionX on SuggestionAction {
  static SuggestionAction fromString(String value) {
    switch (value) {
      case 'increase':
        return SuggestionAction.increase;
      case 'decrease':
        return SuggestionAction.decrease;
      default:
        return SuggestionAction.maintain;
    }
  }
}

class SuggestionResult {
  final double suggestedWeight;
  final int? suggestedReps;
  final SuggestionAction action;
  final String explanation;

  const SuggestionResult({
    required this.suggestedWeight,
    this.suggestedReps,
    required this.action,
    required this.explanation,
  });

  bool get hasData => suggestedWeight > 0;

  factory SuggestionResult.fromJson(Map<String, dynamic> json) {
    return SuggestionResult(
      suggestedWeight: (json['suggestedWeight'] as num?)?.toDouble() ?? 0.0,
      suggestedReps: json['suggestedReps'] as int?,
      action: SuggestionActionX.fromString(json['action'] as String? ?? 'maintain'),
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
