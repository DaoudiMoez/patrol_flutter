import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import '../../core/utils/logger.dart';

class MapScreenshotService {
  /// Captures a screenshot of a widget wrapped with RepaintBoundary
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      // Wait a moment for rendering
      await Future.delayed(const Duration(milliseconds: 500));

      RenderRepaintBoundary? boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        AppLogger.error('RenderRepaintBoundary not found');
        return null;
      }

      // Capture at high resolution
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        AppLogger.error('Failed to convert image to bytes');
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      AppLogger.info('Map screenshot captured: ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      AppLogger.error('Error capturing widget screenshot', e);
      return null;
    }
  }

  /// Converts bytes to base64 string for API upload
  String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Captures map with route
  Future<Uint8List?> captureMapWithRoute({
    required GlobalKey mapKey,
  }) async {
    try {
      AppLogger.info('Capturing map screenshot...');

      // Give time for map to render completely
      await Future.delayed(const Duration(seconds: 1));

      final screenshot = await captureWidget(mapKey);

      if (screenshot != null) {
        AppLogger.info('Map screenshot captured successfully: ${screenshot.length} bytes');
      }

      return screenshot;
    } catch (e) {
      AppLogger.error('Error capturing map with route', e);
      return null;
    }
  }
}