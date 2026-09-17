import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(AppAssets.logo, width: 330, fit: BoxFit.contain);
  }
}
