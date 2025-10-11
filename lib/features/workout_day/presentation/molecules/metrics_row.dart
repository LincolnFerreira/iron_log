import 'package:flutter/material.dart';

class MetricsRow extends StatelessWidget {
  final List<MetricItem> metrics;

  const MetricsRow({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: metrics.asMap().entries.map((entry) {
        final index = entry.key;
        final metric = entry.value;
        final isLast = index == metrics.length - 1;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(metric.value, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MetricItem {
  final String label;
  final String value;

  const MetricItem({required this.label, required this.value});
}
