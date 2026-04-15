import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';
import '../ui/canvas_painter.dart';

enum ExportFormat { mp4, gif, pngSequence }

class ExportService {
  static Future<String?> exportProject({
    required AnimationProject project,
    required ExportFormat format,
    Size resolution = const Size(1080, 1080),
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final exportId = DateTime.now().millisecondsSinceEpoch;
    final frameDir = Directory(p.join(tempDir.path, 'anim_frames_$exportId'));
    await frameDir.create();

    try {
      // 1. Render all frames to images
      for (int i = 0; i < project.frames.length; i++) {
        final frame = project.frames[i];
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final size = resolution;
        
        final painter = CanvasPainter(
          currentFrame: frame,
          showOnionSkin: false,
        );
        
        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        final image = await picture.toImage(size.width.toInt(), size.height.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        image.dispose();
        
        if (byteData == null) continue;
        
        final frameFile = File(p.join(frameDir.path, 'frame_${i.toString().padLeft(5, '0')}.png'));
        await frameFile.writeAsBytes(byteData.buffer.asUint8List());
        
        onProgress?.call((i + 1) / (project.frames.length * 1.5));
      }

      if (format == ExportFormat.pngSequence) {
        return frameDir.path;
      }

      debugPrint('FFmpeg has been removed. Video/GIF export is currently unavailable.');
      return null;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    } finally {
      try {
        if (await frameDir.exists()) {
          await frameDir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('Cleanup error: $e');
      }
    }
  }
}
