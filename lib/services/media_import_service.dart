import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'sketch_filter_service.dart';

class MediaImportService {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image and returns its sketched version.
  Future<Uint8List?> pickAndSketchImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return SketchFilterService.applySketchFilter(bytes);
  }

  /// Picks a video and returns a list of sketched frames.
  /// This uses MediaKit to seek through the video and take screenshots.
  Future<List<Uint8List>?> pickAndSketchVideo({
    required double targetFps,
    void Function(double progress)? onProgress,
  }) async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;

    final player = Player();
    final List<Uint8List> sketchedFrames = [];

    try {
      await player.open(Media(video.path));
      
      // Wait for duration to be loaded
      await _waitForDuration(player);
      final duration = player.state.duration;
      if (duration.inMilliseconds == 0) return null;

      final intervalMs = (1000 / targetFps).round();
      int currentMs = 0;

      while (currentMs < duration.inMilliseconds) {
        await player.seek(Duration(milliseconds: currentMs));
        // Small delay to allow seek to finish and frame to render
        await Future.delayed(const Duration(milliseconds: 100));
        
        final screenshot = await player.screenshot();
        if (screenshot != null) {
          final sketch = SketchFilterService.applySketchFilter(screenshot);
          if (sketch != null) {
            sketchedFrames.add(sketch);
          }
        }
        
        currentMs += intervalMs;
        onProgress?.call(currentMs / duration.inMilliseconds);
      }

      return sketchedFrames;
    } catch (e) {
      print('Video import error: $e');
      return null;
    } finally {
      await player.dispose();
    }
  }

  Future<void> _waitForDuration(Player player) async {
    int attempts = 0;
    while (player.state.duration.inMilliseconds == 0 && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }
}
