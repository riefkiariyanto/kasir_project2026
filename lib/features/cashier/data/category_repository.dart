import 'package:flutter/material.dart';

class ProductCategory {
  const ProductCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

class CategoryRepository {
  const CategoryRepository();

  static final List<ProductCategory> _categories = <ProductCategory>[
    const ProductCategory(name: 'Manicure', icon: Icons.back_hand_outlined),
    const ProductCategory(name: 'Pedicure', icon: Icons.spa_outlined),
    const ProductCategory(name: 'Nail Art', icon: Icons.auto_awesome_outlined),
    const ProductCategory(name: 'Extension', icon: Icons.straighten_outlined),
    const ProductCategory(name: 'Gel Polish', icon: Icons.colorize_outlined),
    const ProductCategory(name: 'Refill', icon: Icons.refresh_outlined),
    const ProductCategory(name: 'Perawatan', icon: Icons.healing_outlined),
    const ProductCategory(name: 'Aksesori', icon: Icons.diamond_outlined),
    const ProductCategory(
      name: 'Paket Hemat',
      icon: Icons.card_giftcard_outlined,
    ),
  ];

  List<ProductCategory> fetchAll() => List<ProductCategory>.from(_categories);

  void add(ProductCategory category) {
    final bool exists = _categories.any(
      (ProductCategory existing) =>
          existing.name.toLowerCase() == category.name.toLowerCase(),
    );
    if (!exists) {
      _categories.add(category);
    }
  }

  void delete(String name) {
    _categories.removeWhere(
      (ProductCategory category) =>
          category.name.toLowerCase() == name.toLowerCase(),
    );
  }
}
