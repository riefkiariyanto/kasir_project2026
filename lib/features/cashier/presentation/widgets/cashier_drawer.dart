import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/user_role.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/brand_title.dart';

class CashierDrawer extends StatelessWidget {
  const CashierDrawer({
    super.key,
    required this.onNewSale,
    required this.onOpenOrders,
  });

  final VoidCallback onNewSale;
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
                    avatar: Icon(UserRole.pegawai.icon, size: 18),
                    label: Text(UserRole.pegawai.label),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text(AppStrings.cashierNewSale),
              onTap: () {
                Navigator.of(context).pop();
                onNewSale();
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text(AppStrings.adminOrdersNav),
              onTap: () {
                Navigator.of(context).pop();
                onOpenOrders();
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
