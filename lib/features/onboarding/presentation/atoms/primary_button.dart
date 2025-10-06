import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool enabled;

  const PrimaryButton({
    required this.text,
    this.onPressed,
    super.key,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,

      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 66),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: enabled ? Colors.white : Colors.grey,
        ),
        backgroundColor: enabled
            ? Theme.of(context).primaryColor
            : Colors.grey.shade300,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: enabled ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}
