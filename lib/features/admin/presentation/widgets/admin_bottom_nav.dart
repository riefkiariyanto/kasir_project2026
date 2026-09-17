import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/clay_nav_bar.dart';

class AdminNavItem {
  const AdminNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  static const int dashboardIndex = 0;
  static const int catalogIndex = 1;
  static const int transactionsIndex = 2;

  static const List<AdminNavItem> items = <AdminNavItem>[
    AdminNavItem(
      icon: Icons.dashboard_outlined,
      label: AppStrings.adminDashboardReport,
    ),
    AdminNavItem(
      icon: Icons.inventory_2_outlined,
      label: AppStrings.adminProducts,
    ),
    AdminNavItem(
      icon: Icons.receipt_long_outlined,
      label: AppStrings.adminTransactions,
    ),
  ];

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClayNavBar(
      icons: [for (final AdminNavItem item in items) item.icon],
      labels: [for (final AdminNavItem item in items) item.label],
      currentIndex: currentIndex,
      onSelected: onSelected,
    );
  }
}
