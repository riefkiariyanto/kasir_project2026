import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkNotifier,
      builder: (BuildContext context, bool isDark, _) {
        return IconButton(
          onPressed: AppColors.toggle,
          tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: color,
          ),
        );
      },
    );
  }
}
