import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/clay_decoration.dart';

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, this.onTap, this.aspectRatio = 6.5});

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

  final VoidCallback? onTap;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: ClayDecoration(borderRadius: _radius),
        child: Material(
          color: AppColors.placeholder,
          borderRadius: _radius,
          child: InkWell(onTap: onTap, borderRadius: _radius),
        ),
      ),
    );
  }
}
