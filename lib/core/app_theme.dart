import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData.light(useMaterial3: true).copyWith(
      primaryTextTheme: TextTheme(),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.blue80,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),

      textTheme: _textTheme(AppColors.textPrimaryLight),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
      ),
      extensions: <ThemeExtension<dynamic>>[_lightThemeExtensions],
    );
  }

  static ThemeData get dark {
    return ThemeData.dark(useMaterial3: true).copyWith(
      // ← adiciona useMaterial3
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark, // blue40 = #99B7FF
        onPrimary: AppColors.gray100, // texto sobre primary
        secondary: AppColors.blue30,
        onSecondary: AppColors.gray100,
        surface: AppColors.surfaceDark, // dark20
        onSurface: AppColors.textPrimaryDark, // white
        surfaceContainerHighest:
            AppColors.dark30, // ← para inputs, cards elevados
        onSurfaceVariant: AppColors.gray40, // textos secundários
        outline: AppColors.dark40, // bordas
        error: AppColors.error,
        onError: AppColors.white,
      ),
      textTheme: _textTheme(AppColors.textPrimaryDark),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
      ),
      // InputDecoration global para TextFields e Dropdowns
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark30,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.dark40),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.dark40),
        ),
        labelStyle: const TextStyle(color: AppColors.gray50),
        hintStyle: TextStyle(color: AppColors.gray50.withOpacity(0.6)),
      ),
      // PopupMenu herda surfaceDark
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.dark30,
        surfaceTintColor: Colors.transparent,
      ),
      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
      ),
      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.dark30,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: <ThemeExtension<dynamic>>[_darkThemeExtensions],
    );
  }

  static TextTheme _textTheme(Color textColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,

        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontFamily: "Barlow",
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );
  }

  static final _lightThemeExtensions = CustomThemeExtensions(
    successContainer: AppColors.success.withOpacity(0.2),
    warningContainer: AppColors.warning.withOpacity(0.2),
    errorContainer: AppColors.error.withOpacity(0.2),
    infoContainer: AppColors.info.withOpacity(0.2),
  );

  static final _darkThemeExtensions = CustomThemeExtensions(
    successContainer: AppColors.success.withOpacity(0.3),
    warningContainer: AppColors.warning.withOpacity(0.3),
    errorContainer: AppColors.error.withOpacity(0.3),
    infoContainer: AppColors.info.withOpacity(0.3),
  );
}

class CustomThemeExtensions extends ThemeExtension<CustomThemeExtensions> {
  final Color successContainer;
  final Color warningContainer;
  final Color errorContainer;
  final Color infoContainer;

  const CustomThemeExtensions({
    required this.successContainer,
    required this.warningContainer,
    required this.errorContainer,
    required this.infoContainer,
  });

  @override
  ThemeExtension<CustomThemeExtensions> copyWith() => this;

  @override
  ThemeExtension<CustomThemeExtensions> lerp(
    covariant ThemeExtension<CustomThemeExtensions>? other,
    double t,
  ) => this;
}
