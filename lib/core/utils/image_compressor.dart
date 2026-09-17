import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Resizes and re-encodes a picked image to JPEG before upload, so large or
/// unusual-format photos (PNG, HEIC, WEBP, ...) don't bloat upload size and
/// storage, and thumbnails always decode a predictable, already-small file.
///
/// Works on bytes only (no dart:io) so it runs the same on mobile, desktop
/// and web.
class ImageCompressor {
  const ImageCompressor._();

  static const int maxDimension = 1280;
  static const int initialQuality = 90;
  static const int minQuality = 40;
  static const int qualityStep = 10;
  static const int maxBytes = 300 * 1024;

  static Uint8List compress(Uint8List bytes) {
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return bytes;
    }

    decoded = img.bakeOrientation(decoded);

    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
      );
    }

    int quality = initialQuality;
    Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(decoded, quality: quality),
    );

    // Most photos already fit comfortably under maxBytes at initialQuality;
    // this only kicks in for unusually busy/detailed photos.
    while (encoded.length > maxBytes && quality > minQuality) {
      quality -= qualityStep;
      encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    }

    return encoded;
  }
}
