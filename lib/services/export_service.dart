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

      // 2. Encode to requested format using FFmpeg
      final outputExt = format == ExportFormat.gif ? 'gif' : 'mp4';
      final outputFile = p.join(tempDir.path, 'export_$exportId.$outputExt');
      
      String ffmpegCommand;
      if (format == ExportFormat.gif) {
        ffmpegCommand = '-y -framerate ${project.fps} -i ${frameDir.path}/frame_%05d.png -vf "scale=720:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $outputFile';
      } else {
        // Video export with potential audio
        final hasAudio = project.audioPath != null && File(project.audioPath!).existsSync();
        
        if (hasAudio) {
          ffmpegCommand = '-y -framerate ${project.fps} -i ${frameDir.path}/frame_%05d.png -i "${project.audioPath}" '
              '-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest $outputFile';
        } else {
          ffmpegCommand = '-y -framerate ${project.fps} -i ${frameDir.path}/frame_%05d.png '
              '-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p $outputFile';
        }
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
        return null;
      }
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
