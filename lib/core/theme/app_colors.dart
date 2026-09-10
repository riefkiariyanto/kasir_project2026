import 'package:flutter/material.dart';

abstract final class AppColors {
  static final ValueNotifier<bool> darkNotifier = ValueNotifier<bool>(false);

  static bool get isDark => darkNotifier.value;

  static void setDark(bool value) => darkNotifier.value = value;

  static void toggle() => darkNotifier.value = !darkNotifier.value;

  static const Color seed = Colors.deepPurple;

  static Color get primary =>
      isDark ? const Color(0xFFC4B0EA) : Colors.deepPurple;

  static const List<Color> backgroundScrim = <Color>[
    Color(0x8C000000),
    Color(0xBF000000),
  ];

  static const Color panelFill = Color(0x33FFFFFF);
  static const Color panelBorder = Color(0x40FFFFFF);
  static const Color fieldFill = Color(0x1AFFFFFF);
  static const Color fieldBorder = Color(0x4DFFFFFF);
  static const Color onPanel = Color(0xFFFFFFFF);
  static const Color onPanelMuted = Color(0xCCFFFFFF);
  static const Color onPanelSubtle = Color(0xBFFFFFFF);

  static Color get surface =>
      isDark ? const Color(0xFF232326) : const Color(0xFFFFFFFF);
  static Color get onSurface =>
      isDark ? const Color(0xFFE7E7EA) : const Color(0xFF111111);
  static Color get placeholder =>
      isDark ? const Color(0xFF3E3E42) : const Color(0xFFDCDCDC);
  static const Color navBar = Color(0xFF3D444C);
  static const Color navShadow = Color(0x66000000);
  static const Color navSelected = Color(0xFFFFFFFF);
  static const Color navUnselected = Color(0x99FFFFFF);

  static Color get panelSurface =>
      isDark ? const Color(0xFF2E2E32) : const Color(0xFFE3E3E3);
  static Color get inputBorder =>
      isDark ? const Color(0xFF4C4C51) : const Color(0xFFD9D9D9);

  static Color get onSurfaceMuted =>
      isDark ? const Color(0xFFAAAAB0) : const Color(0xFF767676);
  static Color get divider =>
      isDark ? const Color(0xFF3E3E42) : const Color(0xFFEBEBEB);

  static List<BoxShadow> get cardShadow => isDark
      ? const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ];
  static const Color cardHighlight = Color(0x33FFFFFF);
}
