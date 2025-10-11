import 'package:flutter/material.dart';
import '../atoms/custom_input_field.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onChanged;

  const SearchBar({
    super.key,
    this.controller,
    this.hintText = 'Buscar...',
    this.onFilterPressed,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomInputField(
        controller: controller,
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: onFilterPressed,
          icon: const Icon(Icons.filter_list),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
