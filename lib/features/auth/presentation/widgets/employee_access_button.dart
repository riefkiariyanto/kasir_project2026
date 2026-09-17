import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

class EmployeeAccessButton extends StatelessWidget {
  const EmployeeAccessButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
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
