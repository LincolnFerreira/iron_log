import 'series_entry.dart';
import 'technique_type.dart';

class TechniqueBlock {
  final String? id;
  final TechniqueType type;
  final int order;
  final String? label;
  final int? restBetweenMiniSets;
  final List<SeriesEntry> entries;
  final bool terminatedEarly;

  const TechniqueBlock({
    this.id,
    required this.type,
    required this.order,
    this.label,
    this.restBetweenMiniSets,
    this.entries = const [],
    this.terminatedEarly = false,
  });

  TechniqueBlock copyWith({
    String? id,
    TechniqueType? type,
    int? order,
    String? label,
    int? restBetweenMiniSets,
    List<SeriesEntry>? entries,
    bool? terminatedEarly,
  }) {
    return TechniqueBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      order: order ?? this.order,
      label: label ?? this.label,
      restBetweenMiniSets: restBetweenMiniSets ?? this.restBetweenMiniSets,
      entries: entries ?? this.entries,
      terminatedEarly: terminatedEarly ?? this.terminatedEarly,
    );
  }

  bool get showHeader => type.isGrouped;
}
