import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/category_repository.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: AppColors.cardShadow,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[const Color(0xFFEDEDED), AppColors.placeholder],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: _radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Center(
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
