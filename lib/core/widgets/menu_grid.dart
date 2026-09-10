import 'package:flutter/material.dart';

import 'menu_tile.dart';

class MenuGrid extends StatelessWidget {
  const MenuGrid({super.key, required this.items});

  final List<MenuTile> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 600 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: items,
        );
      },
    );
  }
}
