import 'dart:io';
import 'package:image_picker/image_picker.dart';

Future<File?> grabarVideo() async {
  final picker = ImagePicker();

  // Abre la cámara para grabar video
  final XFile? videoFile = await picker.pickVideo(
    source: ImageSource.camera,
    maxDuration: Duration(seconds: 10), // duración máxima del video
    //preferredCameraDevice: CameraDevice.back,
  );

  if (videoFile == null) return null;

  return File(videoFile.path);
}
