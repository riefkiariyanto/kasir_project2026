import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
