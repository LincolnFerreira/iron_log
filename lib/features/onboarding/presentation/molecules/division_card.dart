import 'package:flutter/material.dart';
import 'package:iron_log/features/onboarding/model/division_type.dart';

class DivisionCard extends StatelessWidget {
  final DivisionType type;
  final bool selected;
  final VoidCallback onTap;

  const DivisionCard({
    required this.type,
    required this.selected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: selected
                  ? const Color.fromARGB(255, 217, 0, 255)
                  : Colors.grey.shade400,
              strokeAlign: BorderSide.strokeAlignInside,

              width: .4,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.black),
                    ),
                    SizedBox(height: 4),
                    Text(
                      type.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black),
                    ),
                  ],
                ),
                if (selected) Icon(Icons.check_circle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
