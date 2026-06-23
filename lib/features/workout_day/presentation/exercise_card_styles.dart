import 'package:flutter/material.dart';

/// Tokens visuais do card de exercício (séries, campos e ações secundárias).
abstract final class ExerciseCardStyles {
  static const accent = Color(0xFF5B5FE9);
  static const accentBg = Color(0x0A5B5FE9);
  static const accentBorder = Color(0x525B5FE9);
  static const accentChipBg = Color(0x1A5B5FE9);
  static const fieldBorder = Color(0xFFDFE3EE);
  static const rowDivider = Color(0xFFF0F2F8);
  static const labelMuted = Color(0xFF8E96B3);
  static const textPrimary = Color(0xFF2D3548);

  static const fieldHeight = 42.0;
  static const compactFieldHeight = 30.0;
  static const fieldRadius = 12.0;
  static const compactFieldRadius = 8.0;
  static const checkboxSize = 24.0;
  static const compactCheckboxSize = 20.0;
  static const checkboxRadius = 7.0;
  static const seriesLabelWidth = 52.0;
  static const doneColumnWidth = 56.0;
  static const columnGap = 8.0;
  static const rowPaddingV = 8.0;
  static const compactRowPaddingV = 4.0;

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

  static InputDecoration fieldDecoration({
    String? hintText,
    bool compact = false,
  }) {
    final height = compact ? compactFieldHeight : fieldHeight;
    final textStyle = compact ? compactFieldTextStyle : fieldTextStyle;
    final radius = compact ? compactFieldRadius : fieldRadius;
    return InputDecoration(
      hintText: hintText,
      hintStyle: textStyle.copyWith(color: labelMuted),
      isDense: true,
      filled: true,
      fillColor: compact ? accentBg : Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 0,
      ),
      constraints: BoxConstraints(minHeight: height),
      border: _outlineBorder(
        compact ? Colors.transparent : fieldBorder,
        radius,
      ),
      enabledBorder: _outlineBorder(
        compact ? Colors.transparent : fieldBorder,
        radius,
      ),
      focusedBorder: _outlineBorder(
        compact
            ? accent.withValues(alpha: 0.4)
            : accent.withValues(alpha: 0.55),
        radius,
      ),
      focusedErrorBorder: _outlineBorder(fieldBorder, radius),
    );
  }

  /// Dropdown de tipo de série: [isDense] + padding vertical para caber em [fieldHeight]
  /// sem encolher o texto como o [fieldDecoration] genérico.
  static InputDecoration dropdownDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      constraints: const BoxConstraints(minHeight: fieldHeight),
      border: _outlineBorder(fieldBorder),
      enabledBorder: _outlineBorder(fieldBorder),
      focusedBorder: _outlineBorder(accent.withValues(alpha: 0.55)),
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, [double? radius]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius ?? fieldRadius),
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  static BoxDecoration fieldBoxDecoration({
    bool compact = false,
    bool focused = false,
  }) {
    if (compact) {
      return BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(compactFieldRadius),
        border: focused
            ? Border.all(color: accent.withValues(alpha: 0.4), width: 1)
            : null,
      );
    }
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(fieldRadius),
      border: Border.all(
        color: focused
            ? accent.withValues(alpha: 0.55)
            : fieldBorder,
        width: 1,
      ),
    );
  }

  /// TextField sem borda própria — a caixa externa ([fieldBoxDecoration]) define o tamanho.
  static InputDecoration inlineFieldDecoration({
    String? hintText,
    bool compact = false,
  }) {
    final textStyle = compact ? compactFieldTextStyle : fieldTextStyle;
    return InputDecoration(
      hintText: hintText,
      hintStyle: textStyle.copyWith(color: labelMuted),
      isDense: true,
      filled: false,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 4 : 11,
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
    return Theme.of(context).copyWith(
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: const BorderSide(color: fieldBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(checkboxRadius),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
      ),
    );
  }
}
