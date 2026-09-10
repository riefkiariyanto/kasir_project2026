import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/brand_title.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.onOpenTransaction,
    required this.onOpenOrders,
  });

  final VoidCallback onOpenTransaction;
  final VoidCallback onOpenOrders;

  void _logout(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: <Widget>[
                  BrandTitle(fontSize: 28),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(UserRole.admin.icon, size: 18),
                    label: Text(UserRole.admin.label),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text(AppStrings.adminDashboardReport),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.adminReports);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text(AppStrings.adminProducts),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.adminCatalog);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text(AppStrings.adminTransactions),
              onTap: () {
                Navigator.of(context).pop();
                onOpenOrders();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text(AppStrings.adminEmployees),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.adminEmployees);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text(AppStrings.adminSettings),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.adminSettings);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(AppStrings.logout),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
