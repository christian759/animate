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

      if (format == ExportFormat.gif) {
        onProgress?.call(0.66);
        
        final frameFiles = frameDir.listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path));
          
        img.Image? anim;
        
        for (int i = 0; i < frameFiles.length; i++) {
          final file = frameFiles[i];
          final bytes = await file.readAsBytes();
          final image = img.decodePng(bytes);
          if (image == null) continue;
          
          // Image package 4.x timing (frameDuration is in milliseconds)
          image.frameDuration = (1000 ~/ project.fps); 
          
          if (anim == null) {
            anim = image;
          } else {
            anim.addFrame(image);
          }
          onProgress?.call(0.66 + ((i + 1) / frameFiles.length) * 0.3);
        }
        
        if (anim != null) {
          final gifBytes = img.encodeGif(anim);
          final outputFile = p.join(tempDir.path, 'export_$exportId.gif');
          await File(outputFile).writeAsBytes(gifBytes);
          onProgress?.call(1.0);
          return outputFile;
        }
      }

      debugPrint('Video (MP4) export requires external native libraries and is currently unavailable without FFmpeg.');
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
