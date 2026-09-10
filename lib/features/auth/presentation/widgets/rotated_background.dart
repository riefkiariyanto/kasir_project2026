import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class RotatedBackground extends StatelessWidget {
  const RotatedBackground({
    super.key,
    required this.asset,
    this.quarterTurns = 3,
  });

  final String asset;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RotatedBox(
            quarterTurns: quarterTurns,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.backgroundScrim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
