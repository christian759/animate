import 'package:image/image.dart' as img;

void main() {
  final encoder = img.GifEncoder();
  final image = img.Image(width: 10, height: 10);
  final gif = encoder.encode(image);
  print('Encoded size: ${gif.length}');
}
