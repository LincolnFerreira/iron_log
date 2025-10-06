import 'package:flutter/material.dart';

// molecules/metodology_card.dart

class MetodologyCard extends StatelessWidget {
  final String title;
  final String description;
  final int value;
  final int? groupValue;
  final ValueChanged<int?> onChanged;

  const MetodologyCard({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(value == groupValue ? null : value);
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: value == groupValue ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.4, // aumenta o tamanho do Radio
                child: Radio<int>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
