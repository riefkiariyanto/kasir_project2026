import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/clay_decoration.dart';

/// Floating clay pill of icon-only navigation buttons. The selected icon
/// sits in a soft bubble. Shared by the admin and cashier bottom navs.
class ClayNavBar extends StatelessWidget {
  const ClayNavBar({
    super.key,
    required this.icons,
    required this.labels,
    required this.currentIndex,
    required this.onSelected,
  }) : assert(icons.length == labels.length);

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(28));

  final List<IconData> icons;

  /// Accessibility labels, one per icon.
  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: ClayDecoration(
            color: AppColors.navBar,
            borderRadius: _radius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(icons.length, (int index) {
                  final bool isSelected = index == currentIndex;

                  return InkWell(
                    onTap: () => onSelected(index),
                    customBorder: const StadiumBorder(),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      // Four items at full padding overflow a phone width.
                      padding: EdgeInsets.symmetric(
                        horizontal: icons.length > 3 ? 18 : 30,
                        vertical: 10,
                      ),
                      decoration: isSelected
                          ? ShapeDecoration(
                              color: AppColors.navSelected.withValues(
                                alpha: 0.2,
                              ),
                              shape: const StadiumBorder(),
                            )
                          : null,
                      child: Icon(
                        icons[index],
                        size: 28,
                        semanticLabel: labels[index],
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
        ),
      ),
    );
  }
}
