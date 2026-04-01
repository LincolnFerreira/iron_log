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
    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.blue30,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),

      textTheme: _textTheme(AppColors.textPrimaryDark),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
      ),
      extensions: <ThemeExtension<dynamic>>[_darkThemeExtensions],
    );
  }

  // fontFamily: 'Inter',
  //           textTheme: const TextTheme(
  //             displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
  //             displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
  //             displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
  //             headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
  //             headlineMedium: TextStyle(
  //               fontSize: 28,
  //               fontWeight: FontWeight.w400,
  //             ),
  //             headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
  //             titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
  //             titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
  //             titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  //             bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //             bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  //             bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  //             labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  //             labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  //             labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  //           ),

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
