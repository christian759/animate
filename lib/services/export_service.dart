import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
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
        
        // We need a size. For now, we'll use a standard 1080x1080 or the actual screen size if we had it.
        // Let's assume 1080x1080 for high quality.
        const size = Size(1080, 1080);
        
        final painter = CanvasPainter(
          currentFrame: frame,
          currentColor: Colors.black, // Doesn't matter for rendering existing paths
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
        
        onProgress?.call((i + 1) / (project.frames.length * 2)); // Rendering is the first half
      }

      // 2. Encode to requested format
      final outputFile = p.join(tempDir.path, 'export_${DateTime.now().millisecondsSinceEpoch}.${format == ExportFormat.mp4 ? 'mp4' : 'gif'}');
      
      if (format == ExportFormat.mp4) {
        final command = '-framerate ${project.fps} -i ${exportDir.path}/frame_%04d.png -c:v libx264 -pix_fmt yuv420p -y $outputFile';
        
        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          onProgress?.call(1.0);
          return outputFile;
        } else {
          return null;
        }
      } else if (format == ExportFormat.gif) {
        // Use image package for GIF encoding
        final animation = img.Animation();
        for (var file in frameFiles) {
          final bytes = await file.readAsBytes();
          final image = img.decodePng(bytes);
          if (image != null) {
            animation.addFrame(image);
            animation.frames.last.duration = (1000 / project.fps).round();
          }
        }
        
        final gifBytes = img.encodeGifAnimation(animation);
        if (gifBytes != null) {
          final file = File(outputFile);
          await file.writeAsBytes(gifBytes);
          onProgress?.call(1.0);
          return outputFile;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    } finally {
      // Cleanup temp frames
      // await exportDir.delete(recursive: true); // Leave this for debugging or production cleanup
    }
  }
}
