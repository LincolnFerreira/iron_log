import 'package:flutter/material.dart';
import 'package:iron_log/core/app_colors.dart';

/// Tokens visuais do card de exercício (séries, campos e ações secundárias).
abstract final class ExerciseCardStyles {
  static const accent = Color(0xFF5B5FE9);
  static const accentBg = Color(0x0A5B5FE9);
  static const accentBorder = Color(0x525B5FE9);
  static const accentChipBg = Color(0x1A5B5FE9);

  /// Fallbacks light (preferir helpers resolvidos via [BuildContext]).
  static const fieldBorder = Color(0xFFDFE3EE);
  static const rowDivider = Color(0xFFF0F2F8);
  static const labelMuted = Color(0xFF8E96B3);
  static const textPrimary = Color(0xFF2D3548);

  static const fieldHeight = 44.0;
  static const compactFieldHeight = 32.0;
  static const fieldRadius = 12.0;
  static const compactFieldRadius = 8.0;
  static const checkboxSize = 24.0;
  static const compactCheckboxSize = 20.0;
  static const checkboxRadius = 7.0;
  static const seriesLabelWidth = 48.0;
  static const doneColumnWidth = 44.0;
  static const columnGap = 6.0;
  static const rowPaddingV = 8.0;
  static const compactRowPaddingV = 4.0;

  /// Distribuição da mini-tabela: tipo | peso | reps.
  static const typeColumnFlex = 5;
  static const weightColumnFlex = 6;
  static const repsColumnFlex = 4;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color resolvedFieldFill(
    BuildContext context, {
    bool compact = false,
  }) {
    final dark = isDark(context);
    if (compact) {
      return dark
          ? AppColors.primaryDark.withValues(alpha: 0.12)
          : accentBg;
    }
    return dark ? AppColors.dark30 : Colors.white;
  }

  static Color resolvedFieldBorder(BuildContext context) =>
      isDark(context) ? AppColors.dark40 : fieldBorder;

  static Color resolvedTextPrimary(BuildContext context) =>
      isDark(context) ? AppColors.textPrimaryDark : textPrimary;

  static Color resolvedLabelMuted(BuildContext context) =>
      isDark(context) ? AppColors.gray50 : labelMuted;

  static Color resolvedRowDivider(BuildContext context) =>
      isDark(context) ? AppColors.dark40.withValues(alpha: 0.7) : rowDivider;

  static Color resolvedDropdownMenu(BuildContext context) =>
      isDark(context) ? AppColors.dark30 : Colors.white;

  static const techniqueHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: accent,
  );

  static BoxDecoration techniqueBlockDecoration() {
    return BoxDecoration(
      color: accentBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: accentBorder.withValues(alpha: 0.35)),
    );
  }

  static const headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: labelMuted,
  );

  static TextStyle headerStyleOf(BuildContext context) => headerStyle.copyWith(
        color: resolvedLabelMuted(context),
      );

  static const seriesLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: labelMuted,
  );

  static const fieldTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const compactFieldTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle fieldTextStyleOf(
    BuildContext context, {
    bool compact = false,
  }) {
    return TextStyle(
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w500,
      color: resolvedTextPrimary(context),
    );
  }

  static const compactUnitHintStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: labelMuted,
  );

  static const unitHintStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: labelMuted,
  );

  static TextStyle unitHintStyleOf(
    BuildContext context, {
    bool compact = false,
  }) {
    return TextStyle(
      fontSize: compact ? 10 : 11,
      fontWeight: FontWeight.w400,
      color: resolvedLabelMuted(context),
    );
  }

  static InputDecoration fieldDecoration(
    BuildContext context, {
    String? hintText,
    bool compact = false,
  }) {
    final height = compact ? compactFieldHeight : fieldHeight;
    final textStyle = fieldTextStyleOf(context, compact: compact);
    final radius = compact ? compactFieldRadius : fieldRadius;
    final border = resolvedFieldBorder(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: textStyle.copyWith(color: resolvedLabelMuted(context)),
      isDense: true,
      filled: true,
      fillColor: resolvedFieldFill(context, compact: compact),
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 0,
      ),
      constraints: BoxConstraints(minHeight: height),
      border: _outlineBorder(
        compact ? Colors.transparent : border,
        radius,
      ),
      enabledBorder: _outlineBorder(
        compact ? Colors.transparent : border,
        radius,
      ),
      focusedBorder: _outlineBorder(
        compact
            ? accent.withValues(alpha: 0.4)
            : accent.withValues(alpha: 0.55),
        radius,
      ),
      focusedErrorBorder: _outlineBorder(border, radius),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, [double? radius]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius ?? fieldRadius),
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  static BoxDecoration fieldBoxDecoration({
    required BuildContext context,
    bool compact = false,
    bool focused = false,
  }) {
    final radius = compact ? compactFieldRadius : fieldRadius;
    if (compact) {
      return BoxDecoration(
        color: resolvedFieldFill(context, compact: true),
        borderRadius: BorderRadius.circular(radius),
        border: focused
            ? Border.all(color: accent.withValues(alpha: 0.4), width: 1)
            : null,
      );
    }
    return BoxDecoration(
      color: resolvedFieldFill(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: focused
            ? accent.withValues(alpha: 0.55)
            : resolvedFieldBorder(context),
        width: 1,
      ),
    );
  }

  /// TextField sem borda própria — a caixa externa ([fieldBoxDecoration]) define o tamanho.
  static InputDecoration inlineFieldDecoration(
    BuildContext context, {
    String? hintText,
    bool compact = false,
  }) {
    final textStyle = fieldTextStyleOf(context, compact: compact);
    return InputDecoration(
      hintText: hintText,
      hintStyle: textStyle.copyWith(color: resolvedLabelMuted(context)),
      isDense: true,
      filled: false,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: 0,
      ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
  }

  static BoxDecoration techniqueExecutionTableDecoration() {
    return BoxDecoration(
      color: accentBg.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: accentBorder.withValues(alpha: 0.2)),
    );
  }

  // --- Cluster child (linha vertical + indentação hierárquica) ---

  /// Largura da linha vertical lateral.
  static const clusterTreeLineWidth = 2.0;

  /// Cor da linha vertical que conecta pai → filhos.
  static Color get clusterTreeLineColor =>
      accent.withValues(alpha: 0.18);

  /// Indentação horizontal dos filhos (padding-left do container da árvore).
  static const clusterChildIndent = 14.0;

  /// Fundo suave de cada mini-row filho.
  static BoxDecoration clusterMiniRowDecoration() {
    return BoxDecoration(
      color: accentBg.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
    );
  }

  static BoxDecoration clusterProgressTrackDecoration() {
    return BoxDecoration(
      color: rowDivider,
      borderRadius: BorderRadius.circular(999),
    );
  }

  static BoxDecoration clusterProgressFillDecoration() {
    return BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(999),
    );
  }

  static ButtonStyle clusterRemoveButtonStyle() {
    const destructive = Color(0xFFE53935);
    return TextButton.styleFrom(
      minimumSize: const Size(double.infinity, 36),
      padding: const EdgeInsets.symmetric(vertical: 8),
      foregroundColor: destructive,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData checkboxTheme(BuildContext context) {
    final border = resolvedFieldBorder(context);
    return Theme.of(context).copyWith(
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(checkboxRadius),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }
}
