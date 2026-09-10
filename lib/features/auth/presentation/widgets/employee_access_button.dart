import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class EmployeeAccessButton extends StatelessWidget {
  const EmployeeAccessButton({super.key, required this.onPressed});

  static final ButtonStyle _style = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    foregroundColor: AppColors.onPanel,
    backgroundColor: AppColors.fieldFill,
    side: const BorderSide(color: AppColors.fieldBorder),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: _style,
      icon: const Icon(Icons.badge_outlined, size: 20),
      label: const Text(
        AppStrings.employeeButton,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
