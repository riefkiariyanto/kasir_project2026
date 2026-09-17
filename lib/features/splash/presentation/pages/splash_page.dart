import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

/// Shown right after Android 12+'s native splash (which always masks the
/// icon into a circle — an OS-enforced constraint, not something this app
/// controls). This screen takes over almost immediately and shows the full
/// logo with no masking, so the "circle wrapper" only flashes briefly.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image(
          image: AssetImage(AppAssets.logo),
          width: 240,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
