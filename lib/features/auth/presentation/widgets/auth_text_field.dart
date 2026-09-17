import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/clay_decoration.dart';

/// Login input pressed into the clay card (sunken), like the app's other
/// text fields.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppTheme.fieldRadius),
  );

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ClayDecoration(
        color: AppColors.panelSurface,
        borderRadius: _radius,
        sunken: true,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: TextStyle(color: AppColors.onSurface),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.onSurfaceMuted),
          prefixIcon: Icon(icon, color: AppColors.onSurfaceMuted),
          filled: false,
        ),
      ),
    );
  }
}
