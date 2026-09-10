import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  static const OutlineInputBorder _enabledBorder = OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.fieldBorder),
  );

  static const OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderRadius: _radius,
    borderSide: BorderSide(color: AppColors.onPanel, width: 1.5),
  );

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.onPanel),
      cursorColor: AppColors.onPanel,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.onPanelMuted),
        prefixIcon: Icon(icon, color: AppColors.onPanelMuted),
        filled: true,
        fillColor: AppColors.fieldFill,
        enabledBorder: _enabledBorder,
        focusedBorder: _focusedBorder,
      ),
    );
  }
}
