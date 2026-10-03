import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

/// Service to capture a widget as image and share it with Nido branding
class ShareService {
  static ShareService? _instance;
  static ShareService get instance => _instance ??= ShareService._();
  ShareService._();

  /// Capture a widget identified by [repaintKey] and share it with branding overlay.
  Future<void> shareWithBranding({
    required BuildContext context,
    required GlobalKey repaintKey,
    String caption = '',
  }) async {
    try {
      // Capture the widget
      final boundary =
          repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final originalBytes = byteData.buffer.asUint8List();

      // Compose final image with branding
      final brandedBytes = await _addBranding(
        context: context,
        originalBytes: originalBytes,
        width: image.width.toDouble(),
        height: image.height.toDouble(),
      );

      if (kIsWeb) {
        // On web, share as text with caption
        await SharePlus.instance.share(
          ShareParams(
            text: caption.isNotEmpty
                ? '$caption\n\n— Nido App 🪺'
                : 'Compartido desde Nido App 🪺',
          ),
        );
      } else {
        // On mobile, share the image
        final xFile = XFile.fromData(
          brandedBytes,
          mimeType: 'image/png',
          name: 'nido_share.png',
        );
        await SharePlus.instance.share(
          ShareParams(files: [xFile], text: caption.isNotEmpty ? caption : ''),
        );
      }
    } catch (e) {
      debugPrint('ShareService error: $e');
      // Fallback: share as text
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: caption.isNotEmpty
                ? '$caption\n\n— Nido App 🪺'
                : 'Compartido desde Nido App 🪺',
          ),
        );
      } catch (_) {}
    }
  }

  /// Add Nido branding watermark to the bottom of the image
  Future<Uint8List> _addBranding({
    required BuildContext context,
    required Uint8List originalBytes,
    required double width,
    required double height,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Decode original image
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;

      final brandingHeight = 72.0;
      final totalHeight = height + brandingHeight;

      // Draw original image
      canvas.drawImage(srcImage, Offset.zero, Paint());

      // Draw branding bar at bottom
      final brandRect = Rect.fromLTWH(0, height, width, brandingHeight);
      final brandPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, height),
          Offset(width, height + brandingHeight),
          [const Color(0xFFFF6B9D), const Color(0xFFFF8FAB)],
        );
      canvas.drawRect(brandRect, brandPaint);

      // Draw Nido logo text
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(text: '🪺 ', style: TextStyle(fontSize: 22, height: 1.0)),
            TextSpan(
              text: 'Nido',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            TextSpan(
              text: '  ·  nido.app',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha(200),
                height: 1.0,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - 32);
      textPainter.paint(
        canvas,
        Offset(16, height + (brandingHeight - textPainter.height) / 2),
      );

      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(
        width.toInt(),
        totalHeight.toInt(),
      );
      final finalData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return finalData?.buffer.asUint8List() ?? originalBytes;
    } catch (e) {
      debugPrint('Branding error: $e');
      return originalBytes;
    }
  }
}
