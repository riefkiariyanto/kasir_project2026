import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.fontSize = 26, this.color, this.text});

  final double fontSize;
  final Color? color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text ?? AppStrings.brandName,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? AppColors.onSurface,
      ),
    );
  }
}
