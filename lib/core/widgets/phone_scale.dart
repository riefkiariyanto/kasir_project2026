import 'package:flutter/widgets.dart';

/// Shrinks the whole UI on phones by laying it out on a larger logical
/// canvas and scaling that down, so text, spacing, icons, radii and dialogs
/// all get smaller by the same factor. Screens were sized for tablets;
/// tablets (shortest side 600dp+) are left untouched.
class PhoneScale extends StatelessWidget {
  const PhoneScale({super.key, required this.child});

  static const double scale = 0.82;
  static const double _tabletShortestSide = 600;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    if (media.size.shortestSide >= _tabletShortestSide) {
      return child;
    }

    final Size canvas = media.size / scale;
    return MediaQuery(
      data: media.copyWith(
        size: canvas,
        devicePixelRatio: media.devicePixelRatio * scale,
        padding: media.padding / scale,
        viewPadding: media.viewPadding / scale,
        viewInsets: media.viewInsets / scale,
        systemGestureInsets: media.systemGestureInsets / scale,
      ),
      child: FittedBox(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: canvas, child: child),
      ),
    );
  }
}
