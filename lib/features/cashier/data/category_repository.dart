import 'package:flutter/material.dart';

import '../../../core/data/api_client.dart';

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconKey,
  });

  final String id;
  final String name;
  final IconData icon;
  final String iconKey;

  static const Map<String, IconData> _iconByKey = <String, IconData>{
    'back_hand_outlined': Icons.back_hand_outlined,
    'spa_outlined': Icons.spa_outlined,
    'auto_awesome_outlined': Icons.auto_awesome_outlined,
    'straighten_outlined': Icons.straighten_outlined,
    'colorize_outlined': Icons.colorize_outlined,
    'refresh_outlined': Icons.refresh_outlined,
    'healing_outlined': Icons.healing_outlined,
    'diamond_outlined': Icons.diamond_outlined,
    'card_giftcard_outlined': Icons.card_giftcard_outlined,
    'category_outlined': Icons.category_outlined,
  };

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final String iconKey = json['icon_key'] as String? ?? 'category_outlined';
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: iconKey,
      icon: _iconByKey[iconKey] ?? Icons.category_outlined,
    );
  }
}

class CategoryRepository {
  const CategoryRepository({this.api = const ApiClient()});

  final ApiClient api;

  Future<List<ProductCategory>> fetchAll() async {
    final List<dynamic> data = await api.get('/api/categories') as List<dynamic>;
    return data
        .map((dynamic e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(String name) async {
    await api.post('/api/categories', <String, dynamic>{
      'name': name,
      'iconKey': 'category_outlined',
    });
  }

  Future<void> delete(String id) async {
    await api.delete('/api/categories/$id');
  }
}
