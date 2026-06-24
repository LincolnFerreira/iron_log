import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/effort_type.dart';
import '../../domain/entities/parsed_workout_import.dart';

class ImportSetRow extends StatelessWidget {
  const ImportSetRow({
    super.key,
    required this.set,
    this.onWeightChanged,
    this.onRepsChanged,
  });

  final ParsedImportSet set;
  final ValueChanged<double?>? onWeightChanged;
  final ValueChanged<int?>? onRepsChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Chip(
            label: Text(set.effortType.labelPt),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextFormField(
              initialValue: set.weight?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'kg',
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              onChanged: (v) {
                final normalized = v.replaceAll(',', '.');
                onWeightChanged?.call(double.tryParse(normalized));
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: TextFormField(
              initialValue: set.reps?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'reps',
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => onRepsChanged?.call(int.tryParse(v)),
            ),
          ),
        ],
      ),
    );
  }
}
