import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/clay_nav_bar.dart';

class CashierNavItem {
  const CashierNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class CashierBottomNav extends StatelessWidget {
  const CashierBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  static const List<CashierNavItem> items = <CashierNavItem>[
    CashierNavItem(icon: Icons.home_outlined, label: AppStrings.navHome),
    CashierNavItem(
      icon: Icons.receipt_long_outlined,
      label: AppStrings.navTransactions,
    ),
    CashierNavItem(
      icon: Icons.history_outlined,
      label: AppStrings.adminTransactions,
    ),
    CashierNavItem(
      icon: Icons.account_balance_wallet_outlined,
      label: AppStrings.navFinance,
    ),
  ];

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ClayNavBar(
      icons: [for (final CashierNavItem item in items) item.icon],
      labels: [for (final CashierNavItem item in items) item.label],
      currentIndex: currentIndex,
      onSelected: onSelected,
    );
  }
}
