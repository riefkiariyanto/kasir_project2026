import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class TranslucentPanel extends StatelessWidget {
  const TranslucentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelFill,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
