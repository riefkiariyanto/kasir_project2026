import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Full-screen popup that previews a product photo (network URL or raw
/// bytes) with pinch/drag zoom, dismissible by tapping outside or the
/// close button.
class ImageViewerDialog {
  const ImageViewerDialog._();

  static Future<void> show(
    BuildContext context, {
    String? imageUrl,
    Uint8List? imageBytes,
  }) {
    if ((imageUrl == null || imageUrl.trim().isEmpty) && imageBytes == null) {
      return Future<void>.value();
    }
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: imageBytes != null
                          ? Image.memory(imageBytes, fit: BoxFit.contain)
                          : Image.network(imageUrl!, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
