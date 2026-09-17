import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Rounded surface lit from above: a soft shadow beneath, a hairline of
/// light on its top edge and a faint shade on its bottom edge.
///
/// [BoxDecoration] can't paint inner (inset) shadows, so this does.
/// Colours are read from the palette at build time, so rebuild on theme
/// changes (every page listens to [AppColors.darkNotifier]).
class ClayDecoration extends Decoration {
  ClayDecoration({
    Color? color,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.sunken = false,
    this.shadow = true,
  }) : color = color ?? AppColors.surface,
       _palette = AppColors.palette;

  final Color color;
  final BorderRadius borderRadius;

  /// Pressed into the page instead of raised: no outer shadow, and the
  /// edge light and shade swap sides. For inputs.
  final bool sunken;

  /// False when something else already casts the outer shadow.
  final bool shadow;

  final ClayPalette _palette;

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      Path()..addRRect(borderRadius.toRRect(rect));

  @override
  bool get isComplex => true;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _ClayPainter(this);
}

class _ClayPainter extends BoxPainter {
  _ClayPainter(this.decoration);

  final ClayDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    if (size == null || size.isEmpty) {
      return;
    }
    final Rect rect = offset & size;
    final RRect rrect = decoration.borderRadius.toRRect(rect);
    final ClayPalette palette = decoration._palette;

    if (decoration.shadow && !decoration.sunken) {
      for (final BoxShadow shadow in palette.raisedShadows) {
        canvas.drawRRect(
          rrect.shift(shadow.offset),
          Paint()
            ..color = shadow.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
        );
      }
    }

    canvas.drawRRect(rrect, Paint()..color = decoration.color);

    canvas.save();
    canvas.clipRRect(rrect);
    // An inner band shows on the edge the shape is shifted away from, so a
    // downward shift lights the top edge; sunken flips it.
    final double direction = decoration.sunken ? -1 : 1;
    _paintInnerShadow(
      canvas,
      rect,
      rrect,
      palette.innerHighlight,
      Offset(0, 2 * direction),
      blur: 1.5,
    );
    _paintInnerShadow(
      canvas,
      rect,
      rrect,
      palette.innerShade,
      Offset(0, -3 * direction),
      blur: 4,
    );
    canvas.restore();
  }

  void _paintInnerShadow(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    Color color,
    Offset shift, {
    required double blur,
  }) {
    final Path band = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(blur * 4))
      ..addRRect(rrect.shift(shift));
    canvas.drawPath(
      band,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }
}
