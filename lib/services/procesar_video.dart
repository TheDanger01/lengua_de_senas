// Verison 1 - Original
/*
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

Future<List<File>> extraerFrames(BuildContext context, File video, {int framesPorSegundo = 3}) async {
  final controller = VideoPlayerController.file(video);
  await controller.initialize();

  final screenshotController = ScreenshotController();
  final tempDir = await getTemporaryDirectory();
  final framesDir = Directory('${tempDir.path}/frames');

  if (framesDir.existsSync()) {
    for (var file in framesDir.listSync()) {
      if (file is File) file.deleteSync();
    }
  } else {
    framesDir.createSync(recursive: true);
  }

  final duration = controller.value.duration;
  final totalFrames = (duration.inMilliseconds / (1000 / framesPorSegundo)).floor();
  List<File> frames = [];

  // Usamos un Scaffold y capturamos el widget
  final videoWidget = Screenshot(
    controller: screenshotController,
    child: AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    ),
  );

  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(builder: (_) => Positioned.fill(child: Material(child: videoWidget)));
  overlay.insert(overlayEntry);

  for (int i = 0; i < totalFrames; i++) {
    final position = Duration(milliseconds: (i * (1000 ~/ framesPorSegundo)));
    await controller.seekTo(position);
    await Future.delayed(Duration(milliseconds: 100));

    final bytes = await screenshotController.capture();
    if (bytes != null) {
      final file = File('${framesDir.path}/frame_$i.jpg');
      await file.writeAsBytes(bytes);
      frames.add(file);
    }
  }

  overlayEntry.remove();
  controller.dispose();

  print('Frames extraídos: ${frames.length}');
  return frames;
}
*/
// Version 2 - google_mlkit_pose_detection: ^0.14.0
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image/image.dart' as img;

// Detector de pose (global para reusar)
final poseDetector = PoseDetector(
  options: PoseDetectorOptions(
    //mode: PoseDetectionMode.accurate, // más preciso
    model: PoseDetectionModel.base,   // modelo base (rápido)
  ),
);

Future<List<File>> extraerFrames(BuildContext context, File video, {int framesPorSegundo = 3}) async {
  final controller = VideoPlayerController.file(video);
  await controller.initialize();

  final screenshotController = ScreenshotController();
  final tempDir = await getTemporaryDirectory();
  final framesDir = Directory('${tempDir.path}/frames');

  if (framesDir.existsSync()) {
    for (var file in framesDir.listSync()) {
      if (file is File) file.deleteSync();
    }
  } else {
    framesDir.createSync(recursive: true);
  }

  final duration = controller.value.duration;
  final totalFrames = (duration.inMilliseconds / (1000 / framesPorSegundo)).floor();
  List<File> frames = [];

  // Usamos un Scaffold y capturamos el widget
  final videoWidget = Screenshot(
    controller: screenshotController,
    child: AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    ),
  );

  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(builder: (_) => Positioned.fill(child: Material(child: videoWidget)));
  overlay.insert(overlayEntry);

  for (int i = 0; i < totalFrames; i++) {
    final position = Duration(milliseconds: (i * (1000 ~/ framesPorSegundo)));
    await controller.seekTo(position);
    await Future.delayed(Duration(milliseconds: 100));

    final bytes = await screenshotController.capture();
    if (bytes != null) {
      final fileRecortado = await _recortarMano(bytes, framesDir, i); //Añadido RecortarMano
      if (fileRecortado != null) {
        frames.add(fileRecortado);
      }else{
        final file = File('${framesDir.path}/frame_$i.jpg');
        await file.writeAsBytes(bytes);
        frames.add(file);
      }
    }
  }

  overlayEntry.remove();
  controller.dispose();

  print('Frames extraídos: ${frames.length}');
  return frames;
}
/// Detecta mano con Pose Detection y recorta antes de guardar
Future<File?> _recortarMano(
    List<int> bytes, Directory framesDir, int index) async {
  print('Intentando recortar mano en frame $index');
  final image = img.decodeImage(Uint8List.fromList(bytes));
  if (image == null) return null;

  // Guardar temporalmente para usar en PoseDetector
  final tempPath = '${framesDir.path}/temp_$index.jpg';
  final tempFile = File(tempPath)..writeAsBytesSync(bytes);

  final inputImage = InputImage.fromFile(tempFile);
  final poses = await poseDetector.processImage(inputImage);

  if (poses.isEmpty) return null;
  final pose = poses.first;

  // Landmarks mano derecha
  final wrist = pose.landmarks[PoseLandmarkType.rightWrist];
  final indexF = pose.landmarks[PoseLandmarkType.rightIndex];
  final thumb = pose.landmarks[PoseLandmarkType.rightThumb];

  if (wrist == null || indexF == null || thumb == null) return null;

  // Calcular bounding box
  final minX = [wrist.x, indexF.x, thumb.x].reduce((a, b) => a < b ? a : b);
  final maxX = [wrist.x, indexF.x, thumb.x].reduce((a, b) => a > b ? a : b);
  final minY = [wrist.y, indexF.y, thumb.y].reduce((a, b) => a < b ? a : b);
  final maxY = [wrist.y, indexF.y, thumb.y].reduce((a, b) => a > b ? a : b);

  final padding = 40;
  int x = (minX - padding).clamp(0, image.width - 1).toInt();
  int y = (minY - padding).clamp(0, image.height - 1).toInt();
  int w = (maxX - minX + 2 * padding).clamp(1, image.width - x).toInt();
  int h = (maxY - minY + 2 * padding).clamp(1, image.height - y).toInt();

  // Recortar y redimensionar
  final cropped = img.copyCrop(
    image,
    x: x,
    y: y,
    width: w,
    height: h,
  );
  final resized = img.copyResize(cropped, width: 224, height: 224);

  // Guardar frame recortado
  final finalFile = File('${framesDir.path}/frame_$index.jpg');
  await finalFile.writeAsBytes(img.encodeJpg(resized));

  // Eliminar archivo temporal
  tempFile.deleteSync();

  return finalFile;
}
/*// Version 3 - hand_landmarker: ^2.1.0
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:image/image.dart' as img;

late HandLandmarker handLandmarker;  // instancia global para reutilizar

Future<void> inicializarHandLandmarker() async {
  handLandmarker = await HandLandmarker.create(
    modelPath: 'hand_landmarker.task',  // Asegúrate de tener el modelo correcto en assets
    runningMode: RunningMode.video,
    numHands: 1,
  );
}

Future<List<File>> extraerFrames(BuildContext context, File video, {int framesPorSegundo = 3}) async {
  final controller = VideoPlayerController.file(video);
  await controller.initialize();

  final screenshotController = ScreenshotController();
  final tempDir = await getTemporaryDirectory();
  final framesDir = Directory('${tempDir.path}/frames');

  if (framesDir.existsSync()) {
    for (var file in framesDir.listSync()) {
      if (file is File) file.deleteSync();
    }
  } else {
    framesDir.createSync(recursive: true);
  }

  final duration = controller.value.duration;
  final totalFrames = (duration.inMilliseconds / (1000 / framesPorSegundo)).floor();
  List<File> frames = [];

  // Usamos un Scaffold y capturamos el widget
  final videoWidget = Screenshot(
    controller: screenshotController,
    child: AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    ),
  );

  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(builder: (_) => Positioned.fill(child: Material(child: videoWidget)));
  overlay.insert(overlayEntry);

  for (int i = 0; i < totalFrames; i++) {
    final position = Duration(milliseconds: (i * (1000 ~/ framesPorSegundo)));
    await controller.seekTo(position);
    await Future.delayed(Duration(milliseconds: 100));

    final bytes = await screenshotController.capture();
    if (bytes != null) {
      final fileRecortado = await _recortarMano(bytes, framesDir, i); //Añadido RecortarMano
      if (fileRecortado != null) {
        frames.add(fileRecortado);
      }else{
        final file = File('${framesDir.path}/frame_$i.jpg');
        await file.writeAsBytes(bytes);
        frames.add(file);
      }
    }
  }

  overlayEntry.remove();
  controller.dispose();

  print('Frames extraídos: ${frames.length}');
  return frames;
}
/// Detecta mano con Pose Detection y recorta antes de guardar
Future<File?> _recortarMano(
    List<int> bytes, Directory framesDir, int index) async {
  print('Intentando recortar mano en frame $index');
  final image = img.decodeImage(Uint8List.fromList(bytes));
  if (image == null) return null;

  // Convierte a InputImage para hand_landmarker
  final inputImage = InputImage.fromBytes(
    bytes: Uint8List.fromList(bytes),
    inputImageData: InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: InputImageRotation.rotation0deg,
      inputImageFormat: InputImageFormat.bgra8888,
      planeData: [], // No planes si usas BGRA o RGBA directo
    ),
  );

  // Ejecuta la detección
  final results = await handLandmarker.detectForVideo(inputImage, DateTime.now().millisecondsSinceEpoch);

  if (results.isEmpty) return null;

  final hand = results.first;
  if (hand.landmarks.isEmpty) return null;

  // Extraer bounding box de landmarks de la mano
  double minX = hand.landmarks.map((p) => p.x).reduce((a, b) => a < b ? a : b);
  double maxX = hand.landmarks.map((p) => p.x).reduce((a, b) => a > b ? a : b);
  double minY = hand.landmarks.map((p) => p.y).reduce((a, b) => a < b ? a : b);
  double maxY = hand.landmarks.map((p) => p.y).reduce((a, b) => a > b ? a : b);

  final padding = 40;
  int x = (minX * image.width - padding).clamp(0, image.width - 1).toInt();
  int y = (minY * image.height - padding).clamp(0, image.height - 1).toInt();
  int w = ((maxX - minX) * image.width + 2 * padding).clamp(1, image.width - x).toInt();
  int h = ((maxY - minY) * image.height + 2 * padding).clamp(1, image.height - y).toInt();

  // Recortar y redimensionar
  final cropped = img.copyCrop(
    image,
    x: x,
    y: y,
    width: w,
    height: h,
  );
  final resized = img.copyResize(cropped, width: 224, height: 224);

  // Guardar frame recortado
  final finalFile = File('${framesDir.path}/frame_$index.jpg');
  await finalFile.writeAsBytes(img.encodeJpg(resized));

  return finalFile;
}*/
