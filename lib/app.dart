import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/data/store_repository.dart';
import 'core/routing/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/pages/admin_catalog_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/presentation/pages/admin_employees_page.dart';
import 'features/admin/presentation/pages/admin_reports_page.dart';
import 'features/admin/presentation/pages/admin_settings_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/cashier/presentation/pages/cashier_page.dart';
import 'features/cashier/presentation/pages/transaction_page.dart';

class KasirApp extends StatefulWidget {
  const KasirApp({super.key});

  @override
  State<KasirApp> createState() => _KasirAppState();
}

class _KasirAppState extends State<KasirApp> {
  @override
  void initState() {
    super.initState();
    StoreRepository().fetch();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkNotifier,
      builder: (BuildContext context, bool isDark, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: isDark ? AppTheme.dark : AppTheme.light,
          initialRoute: AppRoutes.login,
          routes: <String, WidgetBuilder>{
            AppRoutes.login: (_) => const LoginPage(),
            AppRoutes.admin: (_) => const AdminDashboardPage(),
            AppRoutes.adminCatalog: (_) => const AdminCatalogPage(),
            AppRoutes.adminReports: (_) => const AdminReportsPage(),
            AppRoutes.adminEmployees: (_) => const AdminEmployeesPage(),
            AppRoutes.adminSettings: (_) => const AdminSettingsPage(),
            AppRoutes.cashier: (_) => const CashierPage(),
            AppRoutes.transaction: (_) => const TransactionPage(),
          },
        );
      },
    );
  }
}
