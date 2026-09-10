import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.panelFill,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.panelBorder),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Icon(
              Icons.point_of_sale,
              size: 48,
              color: AppColors.onPanel,
            ),
          ),
        ),
        SizedBox(height: 20),
        Text(
          AppStrings.loginTitle,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: AppColors.onPanel,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          AppStrings.loginSubtitle,
          style: TextStyle(fontSize: 14, color: AppColors.onPanelSubtle),
        ),
      ],
    );
  }
}
