import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SketchFilterService {
  /// Transforms an image into a hand-drawn sketch (black lines on transparent background).
  static Uint8List? applySketchFilter(Uint8List inputData) {
    try {
      img.Image? image = img.decodeImage(inputData);
      if (image == null) return null;

      // 1. Grayscale for better edge detection
      img.Image grayscale = img.grayscale(image);

      // 2. Sobel Edge Detection
      // Returns an image where edges are bright and flat areas are dark
      img.Image edges = img.sobel(grayscale, amount: 2.0);

      // 3. Create a new image for the sketch (transparent background)
      final sketch = img.Image(
        width: edges.width,
        height: edges.height,
        numChannels: 4, // RGBA
      );

      // 4. Thresholding and Inversion with Transparency
      // We want to turn "edged" pixels (bright in Sobel) into black (0,0,0,255)
      // and "non-edged" pixels (dark in Sobel) into transparent (0,0,0,0)
      for (final frame in edges.frames) {
        for (final pixel in frame) {
          final luma = pixel.luminance;
          
          if (luma > 40) { // Threshold for "edge-ness"
            // It's an edge -> make it black
            sketch.setPixelRgba(pixel.x, pixel.y, 0, 0, 0, 255);
          } else {
            // Not an edge -> make it transparent
            sketch.setPixelRgba(pixel.x, pixel.y, 0, 0, 0, 0);
          }
        }
      }

      // 5. Encode back to PNG
      return Uint8List.fromList(img.encodePng(sketch));
    } catch (e) {
      print('Sketch filter error: $e');
      return null;
    }
  }
}
