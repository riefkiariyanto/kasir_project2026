import 'package:flutter/material.dart';

import '../../../../core/theme/clay_decoration.dart';

/// Raised clay card holding the login form, over the background photo.
class LoginCard extends StatelessWidget {
  const LoginCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ClayDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
