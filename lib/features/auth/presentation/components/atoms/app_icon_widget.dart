import 'package:flutter/material.dart';
import 'package:iron_log/core/components/app_logo.dart';

class AppIconWidget extends StatelessWidget {
  const AppIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLogo(
      width: 112,
      borderRadius: 22,
      padding: EdgeInsets.all(6),
      backgroundColor: Colors.white,
    );
  }
}
