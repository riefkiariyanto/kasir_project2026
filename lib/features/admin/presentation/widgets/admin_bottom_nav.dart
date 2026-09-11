import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

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

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  static const List<AdminNavItem> items = <AdminNavItem>[
    AdminNavItem(icon: Icons.home_outlined, label: AppStrings.adminHomeMenu),
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
              final AdminNavItem item = items[index];
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
