import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, this.onTap, this.aspectRatio = 6.5});

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  final VoidCallback? onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: AppColors.cardShadow,
        ),
        child: Material(
          color: AppColors.placeholder,
          borderRadius: _radius,
          child: InkWell(onTap: onTap, borderRadius: _radius),
        ),
      ),
    );
  }
}
