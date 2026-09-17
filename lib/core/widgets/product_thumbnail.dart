import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared product image renderer used by both the admin catalog and the
/// cashier transaction screen, so a product photo looks and loads the same
/// everywhere it appears. Supports a network URL, a bundled asset, a local
/// file path, or raw bytes fresh from the image picker (used for previewing
/// a photo before it's uploaded).
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    this.imageAsset,
    this.previewBytes,
    this.borderRadius,
    this.targetWidth = 200,
  });

  final String? imageAsset;
  final Uint8List? previewBytes;
  final BorderRadius? borderRadius;

  /// Expected display width in logical pixels, used to cap the decoded
  /// image resolution so scrolling a grid of thumbnails doesn't decode
  /// full-size photos into memory.
  final int targetWidth;

  Widget _buildPlaceholder(IconData icon) {
    return ColoredBox(
      color: AppColors.panelSurface,
      child: Icon(icon, color: AppColors.onSurfaceMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int cacheWidth =
        (targetWidth * MediaQuery.devicePixelRatioOf(context)).round();
    final Uint8List? bytes = previewBytes;
    final String? asset = imageAsset;

    Widget image;
    if (bytes != null) {
      image = Image.memory(
        bytes,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
      );
    } else if (asset == null || asset.trim().isEmpty) {
      image = _buildPlaceholder(Icons.image_outlined);
    } else if (asset.startsWith('assets/')) {
      image = Image.asset(
        asset,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                _buildPlaceholder(Icons.broken_image_outlined),
      );
    } else if (asset.startsWith('http')) {
      image = Image.network(
        asset,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                _buildPlaceholder(Icons.broken_image_outlined),
      );
    } else {
      image = Image.file(
        File(asset),
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                _buildPlaceholder(Icons.broken_image_outlined),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: image,
      ),
    );
  }
}
