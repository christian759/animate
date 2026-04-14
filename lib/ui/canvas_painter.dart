import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/models.dart';

class CanvasPainter extends CustomPainter {
  final AnimationFrame? currentFrame;
  final AnimationFrame? previousFrame;
  final List<Offset?>? activePoints;
  final Color? currentColor;
  final double? strokeWidth;
  final String? activeTool;
  final bool showOnionSkin;

  CanvasPainter({
    this.currentFrame,
    this.previousFrame,
    this.activePoints,
    this.currentColor,
    this.strokeWidth,
    this.activeTool,
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
      final paint = _createPaint(
        color: currentColor!,
        width: strokeWidth!,
        tool: activeTool ?? 'pen',
        isEraser: activeTool == 'eraser',
      );

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

  Paint _createPaint({
    required Color color,
    required double width,
    required String tool,
    bool isEraser = false,
    double globalOpacity = 1.0,
  }) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (isEraser) {
      paint
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear
        ..strokeWidth = width;
      return paint;
    }

    switch (tool) {
      case 'pencil':
        paint
          ..color = color.withOpacity(color.opacity * 0.6 * globalOpacity)
          ..strokeWidth = width * 0.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
        break;
      case 'brush':
        paint
          ..color = color.withOpacity(color.opacity * 0.8 * globalOpacity)
          ..strokeWidth = width * 1.5
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.2);
        break;
      case 'pen':
      default:
        paint
          ..color = color.withOpacity(color.opacity * globalOpacity)
          ..strokeWidth = width;
        break;
    }

    return paint;
  }

  void _drawLayer(Canvas canvas, AnimationLayer layer, Size size, {double opacity = 1.0}) {
    canvas.save();
    
    // Performance Optimization: Use Picture Cache
    if (layer.cachedPicture != null) {
      canvas.drawPicture(layer.cachedPicture!);
      canvas.restore();
      return;
    }

    // If cache is empty, record into a new picture
    final recorder = ui.PictureRecorder();
    final recordCanvas = Canvas(recorder);

    _renderLayerImmediate(recordCanvas, layer, size, opacity: 1.0); // Record at full opacity
    
    // Finalize picture
    layer.cachedPicture = recorder.endRecording();
    
    // Draw the newly cached picture
    canvas.drawPicture(layer.cachedPicture!);
    
    canvas.restore();
  }

  void _renderLayerImmediate(Canvas canvas, AnimationLayer layer, Size size, {double opacity = 1.0}) {
    // Apply Effects (Color Filters)
    switch (layer.effect) {
      case EffectType.grayscale:
        canvas.saveLayer(null, Paint()..colorFilter = const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]));
        break;
      case EffectType.sepia:
        canvas.saveLayer(null, Paint()..colorFilter = const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]));
        break;
      case EffectType.invert:
        canvas.saveLayer(null, Paint()..colorFilter = const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]));
        break;
      case EffectType.vintage:
         canvas.saveLayer(null, Paint()..colorFilter = ColorFilter.mode(
           Colors.deepOrangeAccent.withOpacity(0.1), BlendMode.softLight
         ));
         break;
      default:
        break;
    }

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

    // C. Draw Text Elements
    for (var textElement in layer.texts) {
      _drawText(canvas, textElement, opacity: opacity);
    }

    if (layer.effect != EffectType.none) {
      canvas.restore(); // Restore from saveLayer for effects
    }
  }

  void _drawPath(Canvas canvas, DrawnPath drawnPath, {double opacity = 1.0}) {
    if (drawnPath.points.isEmpty) return;

    final paint = _createPaint(
      color: drawnPath.color,
      width: drawnPath.strokeWidth,
      tool: drawnPath.tool,
      isEraser: drawnPath.isEraser,
      globalOpacity: opacity,
    );

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

  void _drawText(Canvas canvas, TextElement textElement, {double opacity = 1.0}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textElement.text,
        style: TextStyle(
          color: textElement.color.withOpacity(textElement.color.opacity * opacity),
          fontSize: textElement.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    canvas.save();
    canvas.translate(textElement.position.dx, textElement.position.dy);
    canvas.rotate(textElement.rotation);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return true; 
  }
}
