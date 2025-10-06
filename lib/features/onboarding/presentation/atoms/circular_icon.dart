import 'package:flutter/material.dart';

class CircularIcon extends StatelessWidget {
  final IconData icon;
  const CircularIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color.fromARGB(83, 209, 196, 233),
      ),
      child: Icon(icon, color: Colors.deepPurple),
    );
  }
}
