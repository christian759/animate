import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../models/models.dart';
import '../ui/canvas_painter.dart';

enum ExportFormat { mp4, gif, pngSequence }

class ExportService {
  static Future<String?> exportProject({
    required AnimationProject project,
    required ExportFormat format,
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory(p.join(tempDir.path, 'anim_export_${DateTime.now().millisecondsSinceEpoch}'));
    await exportDir.create();

    try {
      // 1. Render all frames to images
      final List<File> frameFiles = [];
      for (int i = 0; i < project.frames.length; i++) {
        final frame = project.frames[i];
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        
        // Use a standard 1080x1080 for high quality
        const size = Size(1080, 1080);
        
        final painter = CanvasPainter(
          currentFrame: frame,
          currentColor: Colors.black,
          strokeWidth: 1.0,
          showOnionSkin: false,
        );
        
        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        final image = await picture.toImage(size.width.toInt(), size.height.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData == null) continue;
        
        final frameFile = File(p.join(exportDir.path, 'frame_${i.toString().padLeft(4, '0')}.png'));
        await frameFile.writeAsBytes(byteData.buffer.asUint8List());
        frameFiles.add(frameFile);
        
        onProgress?.call((i + 1) / (project.frames.length * 2));
      }

      // 2. Encode to requested format
      final outputFile = p.join(tempDir.path, 'export_${DateTime.now().millisecondsSinceEpoch}.${format == ExportFormat.gif ? 'gif' : 'zip'}');
      
      if (format == ExportFormat.mp4) {
        // MP4 Export removed to avoid SDK 33 dependencies
        debugPrint('MP4 Export is currently disabled.');
        return null;
      } else if (format == ExportFormat.gif) {
        // Use image package for GIF encoding (v4.x API)
        if (frameFiles.isEmpty) return null;
        
        final firstFrameBytes = await frameFiles[0].readAsBytes();
        final animation = img.decodePng(firstFrameBytes);
        if (animation == null) return null;
        
        final centisecondDelay = (100 / project.fps).round();
        for (int i = 1; i < frameFiles.length; i++) {
          final bytes = await frameFiles[i].readAsBytes();
          final frame = img.decodePng(bytes);
          if (frame != null) {
            animation.addFrame(frame);
          }
          onProgress?.call(0.5 + (i + 1) / (project.frames.length * 2));
        }
        
        final gifBytes = img.GifEncoder(delay: centisecondDelay).encode(animation);
        final file = File(outputFile);
        await file.writeAsBytes(gifBytes);
        onProgress?.call(1.0);
        return outputFile;
      }

      return null;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    } finally {
      // Cleanup logic could go here
    }
  }
}
