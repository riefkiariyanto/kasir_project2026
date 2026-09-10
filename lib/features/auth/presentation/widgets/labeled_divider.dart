import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class LabeledDivider extends StatelessWidget {
  const LabeledDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: AppColors.fieldBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onPanelSubtle,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.fieldBorder)),
      ],
    );
  }
}
