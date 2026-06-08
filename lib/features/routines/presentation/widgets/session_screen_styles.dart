import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';

/// Tokens visuais da tela Nova/Editar Sessão.
abstract final class SessionScreenStyles {
  static const screenBackground = Color(0xFFF6F7FB);
  static const labelColor = Color(0xFF8E9BBD);
  static const metaColor = Color(0xFF94A0BC);
  static const chipText = Color(0xFF52607F);
  static const chipBackground = Color(0xFFEEF1F7);
  static const emptyBackground = Color(0xFFEEF2FF);
  static const emptyBorder = Color(0x2E5F82FF);
  static const emptyText = Color(0xFF6F7EA7);
  static const emptySubtext = Color(0xFF97A4C6);
  static const cardIconBackground = Color(0xFFF2F5FC);
  static const addButtonBackground = Color(0xFFEEF2FF);
  static const addedBackground = Color(0xFFDFF7E6);
  static const addedForeground = Color(0xFF2EA44F);
  static const toastBackground = Color(0xFF1E2A42);
  static const divider = Color(0x0D1E2A42);

  static const spacingXs = 8.0;
  static const spacingSm = 12.0;
  static const spacingMd = 16.0;
  static const spacingLg = 24.0;
  static const spacingXl = 32.0;

  static const fieldHeight = 58.0;
  static const searchHeight = 54.0;
  static const fieldRadius = 16.0;
  static const cardRadius = 18.0;

  static TextStyle sectionLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: labelColor,
      letterSpacing: 0.04 * 13,
    );
  }

  static TextStyle sectionHeading(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    );
  }

  static InputDecoration nameFieldDecoration({
    required String hintText,
    String? errorText,
  }) {
    const borderColor = Color(0x241E2A42);

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF97A4C6),
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      errorText: errorText,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: AppColors.blue100, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  static BoxDecoration cardDecoration({bool selected = false}) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: [
        BoxShadow(
          color: const Color(0x0D1E2A42),
          blurRadius: 0,
          spreadRadius: 1,
        ),
      ],
      border: selected
          ? Border.all(color: AppColors.blue100.withValues(alpha: 0.22))
          : null,
    );
  }
}
