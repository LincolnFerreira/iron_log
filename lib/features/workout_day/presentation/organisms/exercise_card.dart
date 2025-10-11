import 'package:flutter/material.dart';
import '../atoms/custom_badge.dart';
import '../molecules/metrics_row.dart';
import '../molecules/series_selector.dart';

class ExerciseCard extends StatefulWidget {
  final String name;
  final String tag;
  final Color tagColor;
  final String muscles;
  final String variation;
  final int series;
  final String reps;
  final String weight;
  final int rir;
  final int restTime;

  const ExerciseCard({
    super.key,
    required this.name,
    required this.tag,
    required this.tagColor,
    required this.muscles,
    required this.variation,
    required this.series,
    required this.reps,
    required this.weight,
    required this.rir,
    required this.restTime,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  late int _series;
  late String _reps;
  late String _weight;
  late int _rir;
  late int _restTime;
  SeriesType? _selectedSeriesType;

  @override
  void initState() {
    super.initState();
    _series = widget.series;
    _reps = widget.reps;
    _weight = widget.weight;
    _rir = widget.rir;
    _restTime = widget.restTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and tag
          Row(
            children: [
              // Drag handle
              const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8),
              CustomBadge(
                text: widget.tag,
                backgroundColor: widget.tagColor.withOpacity(0.1),
                textColor: widget.tagColor,
              ),
              const Spacer(),
              // Menu button
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.muscles,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),

          // Variation Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Variação: ${widget.variation}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metrics
          MetricsRow(
            metrics: [
              MetricItem(label: 'Séries', value: _series.toString()),
              MetricItem(label: 'Reps', value: _reps),
              MetricItem(label: 'Carga', value: _weight),
            ],
          ),
          const SizedBox(height: 12),
          MetricsRow(
            metrics: [
              MetricItem(label: 'RIR', value: _rir.toString()),
              MetricItem(label: 'Descanso', value: '${_restTime}s'),
            ],
          ),
          const SizedBox(height: 16),

          // Series Type Selector
          SeriesSelector(
            seriesTypes: const [
              SeriesType.warmUp,
              SeriesType.feeder,
              SeriesType.topSet,
              SeriesType.backOff,
            ],
            selectedType: _selectedSeriesType,
            onTypeSelected: (type) {
              setState(() {
                _selectedSeriesType = type;
              });
            },
          ),
          const SizedBox(height: 16),

          // Notes Field
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Observações...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 2,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
