import 'package:flutter/material.dart';

class SectionDescriptionText extends StatelessWidget {
  final String text;
  const SectionDescriptionText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.black),
    );
  }
}
