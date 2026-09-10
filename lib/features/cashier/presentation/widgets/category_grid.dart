import 'package:flutter/material.dart';

import '../../data/category_repository.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onCategoryTap,
    this.maxCardWidth = 110,
  });

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onCategoryTap;
  final double maxCardWidth;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCardWidth,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (BuildContext context, int index) {
        final ProductCategory category = categories[index];

        return CategoryCard(
          category: category,
          onTap: () => onCategoryTap(category),
        );
      },
    );
  }
}
