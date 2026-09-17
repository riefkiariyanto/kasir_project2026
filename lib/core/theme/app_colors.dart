import 'package:flutter/material.dart';

/// One mode's worth of claymorphism colours, pastel pink to match the
/// Nails by Ara logo. [ClayPalette.light] and [ClayPalette.dark] are the
/// single source of truth for both [AppColors] (read while building
/// widgets) and the app theme (built once per mode).
class ClayPalette {
  const ClayPalette({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.panelSurface,
    required this.placeholder,
    required this.inputBorder,
    required this.divider,
    required this.navBar,
    required this.navSelected,
    required this.navUnselected,
    required this.dropShadow,
    required this.contactShadow,
    required this.innerHighlight,
    required this.innerShade,
  });

  final Color primary;
  final Color onPrimary;

  /// Page background, behind every clay surface.
  final Color background;

  /// Raised clay cards, dialogs, panels.
  final Color surface;
  final Color onSurface;
  final Color onSurfaceMuted;

  /// Recessed areas: inputs, filter strips, image placeholders.
  final Color panelSurface;
  final Color placeholder;
  final Color inputBorder;
  final Color divider;

  final Color navBar;
  final Color navSelected;
  final Color navUnselected;

  /// Soft ambient shadow below a raised surface.
  final Color dropShadow;

  /// Tight shadow where a surface meets the page.
  final Color contactShadow;

  /// Hairline of light along a surface's top edge.
  final Color innerHighlight;

  /// Faint shade along a surface's bottom edge.
  final Color innerShade;

  static const ClayPalette light = ClayPalette(
    primary: Color(0xFFD6408F),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFFBE9F2),
    surface: Color(0xFFFFF4F9),
    onSurface: Color(0xFF3B1C30),
    onSurfaceMuted: Color(0xFF8C6379),
    panelSurface: Color(0xFFF5DCE9),
    placeholder: Color(0xFFF1D2E2),
    inputBorder: Color(0xFFE9C2D6),
    divider: Color(0xFFF0D3E2),
    navBar: Color(0xFFFFF4F9),
    navSelected: Color(0xFFD6408F),
    navUnselected: Color(0xFF8C6379),
    dropShadow: Color(0x1F4A1D38),
    contactShadow: Color(0x144A1D38),
    innerHighlight: Color(0xCCFFFFFF),
    innerShade: Color(0x0F4A1D38),
  );

  static const ClayPalette dark = ClayPalette(
    primary: Color(0xFFF58CC4),
    onPrimary: Color(0xFF3B1030),
    background: Color(0xFF1E151B),
    surface: Color(0xFF2A1F27),
    onSurface: Color(0xFFF6E4EE),
    onSurfaceMuted: Color(0xFFC1A0B2),
    panelSurface: Color(0xFF33262F),
    placeholder: Color(0xFF3E2F39),
    inputBorder: Color(0xFF55404D),
    divider: Color(0xFF3E2F39),
    navBar: Color(0xFF2A1F27),
    navSelected: Color(0xFFF58CC4),
    navUnselected: Color(0xFFC1A0B2),
    dropShadow: Color(0x73000000),
    contactShadow: Color(0x4D000000),
    innerHighlight: Color(0x14FFFFFF),
    innerShade: Color(0x33000000),
  );

  List<BoxShadow> get raisedShadows => <BoxShadow>[
    BoxShadow(color: dropShadow, blurRadius: 16, offset: const Offset(0, 6)),
    BoxShadow(color: contactShadow, blurRadius: 3, offset: const Offset(0, 1)),
  ];
}

abstract final class AppColors {
  static final ValueNotifier<bool> darkNotifier = ValueNotifier<bool>(false);

  static bool get isDark => darkNotifier.value;

  static void setDark(bool value) => darkNotifier.value = value;

  static void toggle() => darkNotifier.value = !darkNotifier.value;

  static ClayPalette get palette =>
      isDark ? ClayPalette.dark : ClayPalette.light;

  static Color get primary => palette.primary;
  static Color get onPrimary => palette.onPrimary;
  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get onSurface => palette.onSurface;
  static Color get onSurfaceMuted => palette.onSurfaceMuted;
  static Color get panelSurface => palette.panelSurface;
  static Color get placeholder => palette.placeholder;
  static Color get inputBorder => palette.inputBorder;
  static Color get divider => palette.divider;
  static Color get navBar => palette.navBar;
  static Color get navSelected => palette.navSelected;
  static Color get navUnselected => palette.navUnselected;

  /// Darkens the login background photo so light content stays readable.
  static const List<Color> backgroundScrim = <Color>[
    Color(0x8C000000),
    Color(0xBF000000),
  ];

  /// Text and icons over photos or dark scrims (independent of theme).
  static const Color onPanel = Color(0xFFFFFFFF);
}
