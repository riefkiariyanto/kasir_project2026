import 'package:flutter/material.dart';

import '../data/store_repository.dart';
import '../theme/app_colors.dart';

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.fontSize = 26, this.color, this.text});

  final double fontSize;
  final Color? color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StoreInfo>(
      valueListenable: StoreRepository.store,
      builder: (BuildContext context, StoreInfo store, _) {
        final String shown = text ?? (store.name.isEmpty ? 'Toko' : store.name);
        return Text(
          shown,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: fontSize,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: color ?? AppColors.onSurface,
          ),
        );
      },
    );
  }
}
