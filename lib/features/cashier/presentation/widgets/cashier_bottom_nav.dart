import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

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

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  static const List<CashierNavItem> items = <CashierNavItem>[
    CashierNavItem(icon: Icons.home_outlined, label: AppStrings.navHome),
    CashierNavItem(
      icon: Icons.receipt_long_outlined,
      label: AppStrings.navTransactions,
    ),
    CashierNavItem(
      icon: Icons.inventory_2_outlined,
      label: AppStrings.navOrders,
    ),
    CashierNavItem(icon: Icons.account_balance_wallet_outlined, label: AppStrings.navFinance),
  ];

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Material(
          color: AppColors.navBar,
          borderRadius: _radius,
          elevation: 8,
          shadowColor: AppColors.navShadow,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(items.length, (int index) {
              final CashierNavItem item = items[index];
              final bool isSelected = index == currentIndex;

              return InkWell(
                onTap: () => onSelected(index),
                borderRadius: _radius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 42,
                    vertical: 13,
                  ),
                  child: Icon(
                    item.icon,
                    size: 28,
                    semanticLabel: item.label,
                    color: isSelected
                        ? AppColors.navSelected
                        : AppColors.navUnselected,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
