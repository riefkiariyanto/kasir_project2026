import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Converts a colour PNG with transparency into a pure black/white image a
/// thermal printer can reproduce.
///
/// esc_pos_utils_plus does its own conversion, but it thresholds at mid
/// grey: mid-tone colours (like a pink logo) come out as blank paper and
/// transparent pixels can print black. Doing it here — flattening onto
/// white and using a lighter cut-off — keeps coloured artwork solid and
/// legible.
img.Image toThermalImage(
  Uint8List pngBytes, {
  required int width,
  int threshold = 200,
}) {
  // The library's raster packing breaks when width isn't a multiple of 8.
  assert(width % 8 == 0, 'Thermal image width must be a multiple of 8.');

  final img.Image source = img
      .decodePng(pngBytes)!
      .convert(format: img.Format.uint8, numChannels: 4);
  final img.Image resized = img.copyResize(
    source,
    width: width,
    interpolation: img.Interpolation.average,
  );

  final img.Image output = img.Image(
    width: resized.width,
    height: resized.height,
  );
  for (final img.Pixel pixel in resized) {
    final double alpha = pixel.a / 255;
    final num luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
    final double onWhite = luminance * alpha + 255 * (1 - alpha);
    final int value = onWhite < threshold ? 0 : 255;
    output.setPixelRgb(pixel.x, pixel.y, value, value, value);
  }
  return output;
}
