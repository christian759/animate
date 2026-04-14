import 'package:flutter/material.dart';
import '../models/models.dart';

class CanvasPainter extends CustomPainter {
  final AnimationFrame? currentFrame;
  final AnimationFrame? previousFrame;
  final List<Offset?>? activePoints;
  final Color? currentColor;
  final double? strokeWidth;
  final bool showOnionSkin;

  CanvasPainter({
    this.currentFrame,
    this.previousFrame,
    this.activePoints,
    this.currentColor,
    this.strokeWidth,
    this.showOnionSkin = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Onion Skin (Previous Frame)
    if (showOnionSkin && previousFrame != null) {
      for (var layer in previousFrame!.layers) {
        if (!layer.isVisible) continue;
        _drawLayer(canvas, layer, size, opacity: 0.15);
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
    if (activePoints != null && activePoints!.isNotEmpty && currentColor != null && strokeWidth != null) {
      final paint = Paint()
        ..color = currentColor!
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth!
        ..style = PaintingStyle.stroke;

      final path = Path();
      bool first = true;
      for (var point in activePoints!) {
        if (point == null) continue;
        if (first) {
          path.moveTo(point.dx, point.dy);
          first = false;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
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

  void _drawPath(Canvas canvas, DrawnPath drawnPath, {double opacity = 1.0}) {
    if (drawnPath.points.isEmpty) return;

    final paint = Paint()
      ..color = drawnPath.isEraser 
          ? Colors.transparent 
          : drawnPath.color.withOpacity(drawnPath.color.opacity * opacity)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = drawnPath.strokeWidth
      ..style = PaintingStyle.stroke;
    
    if (drawnPath.isEraser) {
        paint.blendMode = BlendMode.clear;
    }

    final path = Path();
    bool first = true;
    for (var point in drawnPath.points) {
      if (point == null) continue;
      if (first) {
        path.moveTo(point.dx, point.dy);
        first = false;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return true; // Simplified for now, but optimizations can be added based on properties
  }
}
