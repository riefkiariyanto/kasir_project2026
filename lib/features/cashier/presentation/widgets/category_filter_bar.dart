import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final bool isAll = index == 0;
          final String label = isAll
              ? AppStrings.categoryAll
              : categories[index - 1];
          final bool isSelected = isAll ? selected == null : selected == label;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(isAll ? null : label),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.onPanel : AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
