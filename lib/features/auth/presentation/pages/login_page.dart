import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../widgets/employee_access_button.dart';
import '../widgets/labeled_divider.dart';
import '../widgets/login_form.dart';
import '../widgets/login_card.dart';
import '../widgets/login_header.dart';
import '../widgets/rotated_background.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const double _maxContentWidth = 420;

  void _openRoute(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    // Clay colours are read while building, so rebuild when the theme
    // toggle on this page flips dark mode.
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkNotifier,
      builder: (BuildContext context, bool isDark, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const RotatedBackground(asset: AppAssets.loginBackground),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: ThemeToggleButton(color: AppColors.onPanel),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const LoginHeader(),
                      const SizedBox(height: 32),
                      LoginCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            LoginForm(
                              onSuccess: () =>
                                  _openRoute(context, AppRoutes.admin),
                            ),
                            const SizedBox(height: 20),
                            const LabeledDivider(label: AppStrings.orDivider),
                            const SizedBox(height: 20),
                            EmployeeAccessButton(
                              onPressed: () =>
                                  _openRoute(context, AppRoutes.cashier),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.appWatermark,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onPanel.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
