import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'clay_decoration.dart';

abstract final class AppTheme {
  static const double buttonRadius = 18;
  static const double fieldRadius = 18;
  static const double dialogRadius = 28;

  static final ThemeData light = _build(ClayPalette.light, Brightness.light);
  static final ThemeData dark = _build(ClayPalette.dark, Brightness.dark);

  static ThemeData _build(ClayPalette p, Brightness brightness) {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          surface: p.surface,
          onSurface: p.onSurface,
          surfaceContainerHighest: p.panelSurface,
          outline: p.inputBorder,
          outlineVariant: p.divider,
        );

    final RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );

    // Solid tint: Material scales shadow opacity itself.
    final Color shadowTint = p.dropShadow.withAlpha(255);
    final ButtonStyle raised = ButtonStyle(
      elevation: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.disabled) ? 0 : 3,
      ),
      shadowColor: WidgetStatePropertyAll<Color>(shadowTint),
      backgroundBuilder: _buttonRim,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: buttonShape,
        ).merge(raised),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: buttonShape,
        ).merge(raised),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.primary,
          side: BorderSide.none,
          shape: buttonShape,
        ).merge(raised),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.panelSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: shadowTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primary,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        elevation: 2,
        pressElevation: 2,
        shadowColor: shadowTint,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 3,
        highlightElevation: 3,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: shadowTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.onSurface,
        contentTextStyle: TextStyle(color: p.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  /// Lit top edge and shaded bottom edge, drawn over the button's fill.
  static Widget _buttonRim(
    BuildContext context,
    Set<WidgetState> states,
    Widget? child,
  ) {
    if (states.contains(WidgetState.disabled)) {
      return child!;
    }
    // Softer than on cards: a full-strength white rim on a coloured
    // button reads as glow.
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: Opacity(
            opacity: 0.45,
            child: DecoratedBox(
              decoration: ClayDecoration(
                color: Colors.transparent,
                shadow: false,
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
            ),
          ),
        ),
        child!,
      ],
    );
  }
}
