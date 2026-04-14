import 'package:flutter/material.dart';
import '../models/models.dart';

class CanvasPainter extends CustomPainter {
  final AnimationFrame? currentFrame;
  final AnimationFrame? previousFrame;
  final List<Offset?>? activePoints;
  final Color currentColor;
  final double strokeWidth;
  final bool showOnionSkin;

  CanvasPainter({
    this.currentFrame,
    this.previousFrame,
    this.activePoints,
    required this.currentColor,
    required this.strokeWidth,
    this.showOnionSkin = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Onion Skin (Previous Frame)
    if (showOnionSkin && previousFrame != null) {
      for (var layer in previousFrame!.layers) {
        if (!layer.isVisible) continue;
        _drawLayer(canvas, layer, size, opacity: 0.2);
      }
    }

    // 2. Draw Current Frame Layers
    if (currentFrame != null) {
      for (var layer in currentFrame!.layers) {
        if (!layer.isVisible) continue;
        _drawLayer(canvas, layer, size, opacity: layer.opacity);
      }
    }

    // 3. Draw Active Stroke
    if (activePoints != null && activePoints!.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < activePoints!.length - 1; i++) {
        if (activePoints![i] != null && activePoints![i + 1] != null) {
          canvas.drawLine(activePoints![i]!, activePoints![i + 1]!, paint);
        }
      }
    }
  }

  void _drawLayer(Canvas canvas, AnimationLayer layer, Size size, {double opacity = 1.0}) {
    // A. Draw Background Bitmap (Sketch)
    if (layer.decodedImage != null) {
      final paint = Paint()..color = Colors.white.withOpacity(opacity);
      canvas.drawImageRect(
        layer.decodedImage!,
        Rect.fromLTWH(0, 0, layer.decodedImage!.width.toDouble(), layer.decodedImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }

    // B. Draw Paths
    for (var path in layer.paths) {
      _drawPath(canvas, path, opacity: opacity);
    }
  }

  void _drawPath(Canvas canvas, DrawnPath path, {double opacity = 1.0}) {
    final paint = Paint()
      ..color = path.isEraser 
          ? Colors.transparent 
          : path.color.withOpacity(path.color.opacity * opacity)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = path.strokeWidth
      ..style = PaintingStyle.stroke;
    
    if (path.isEraser) {
        paint.blendMode = BlendMode.clear;
    }

    for (int i = 0; i < path.points.length - 1; i++) {
      if (path.points[i] != null && path.points[i + 1] != null) {
        canvas.drawLine(path.points[i]!, path.points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return true; 
  }
}
