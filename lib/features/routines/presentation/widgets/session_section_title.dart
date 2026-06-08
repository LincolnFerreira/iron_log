import 'package:flutter/material.dart';
import 'session_screen_styles.dart';

class SessionSectionTitle extends StatelessWidget {
  final String text;
  const SessionSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: SessionScreenStyles.sectionLabel(context),
    );
  }
}
