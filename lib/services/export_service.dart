import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
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
    final exportId = DateTime.now().millisecondsSinceEpoch;
    final frameDir = Directory(p.join(tempDir.path, 'anim_frames_$exportId'));
    await frameDir.create();

    try {
      // 1. Render all frames to images one by one
      // This part is memory efficient because we don't keep images in memory
      for (int i = 0; i < project.frames.length; i++) {
        final frame = project.frames[i];
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        
        // High quality output
        const size = Size(1080, 1080);
        
        final painter = CanvasPainter(
          currentFrame: frame,
          showOnionSkin: false,
        );
        
        painter.paint(canvas, size);
        final picture = recorder.endRecording();
        final image = await picture.toImage(size.width.toInt(), size.height.toInt());
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        // Release image memory early
        image.dispose();
        
        if (byteData == null) continue;
        
        final frameFile = File(p.join(frameDir.path, 'frame_${i.toString().padLeft(5, '0')}.png'));
        await frameFile.writeAsBytes(byteData.buffer.asUint8List());
        
        onProgress?.call((i + 1) / (project.frames.length * 1.5)); // First 2/3 of wait is rendering
      }

      if (format == ExportFormat.pngSequence) {
        // Just return the directory path if they wanted a sequence (could zip it)
        return frameDir.path;
      }

      // 2. Encode to requested format using FFmpeg
      final outputExt = format == ExportFormat.gif ? 'gif' : 'mp4';
      final outputFile = p.join(tempDir.path, 'export_$exportId.$outputExt');
      
      // FFmpeg command strategy:
      // -i frame_%05d.png : sequential input
      // -framerate : project fps
      // -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" : even dimensions for mp4
      // -c:v libx264 -pix_fmt yuv420p : standard mp4 compatibility
      
      String ffmpegCommand;
      if (format == ExportFormat.gif) {
        ffmpegCommand = '-y -framerate ${project.fps} -i ${frameDir.path}/frame_%05d.png -vf "scale=720:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $outputFile';
      } else {
        ffmpegCommand = '-y -framerate ${project.fps} -i ${frameDir.path}/frame_%05d.png -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p $outputFile';
      }

      debugPrint('Running FFmpeg: $ffmpegCommand');
      
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        onProgress?.call(1.0);
        return outputFile;
      } else {
        final logs = await session.getLogs();
        debugPrint('FFmpeg failed with return code $returnCode');
        for (var log in logs) {
          debugPrint(log.getMessage());
        }
        return null;
      }
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    } finally {
      // Cleanup frame files after encoding
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
