/*import 'dart:io';
import 'package:ffmpeg_kit_flutter_minimal/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

/// Extrae [framesPorSegundo] del video como imágenes JPG.
/// por defecto 20 fps, puedes cambiarlo desde el parámetro o editar el valor por defecto abajo.
Future<List<File>> extraerFrames(
    File video, {
      int framesPorSegundo = 10, //cambiado de 20
    }) async {
  final appDir = await getTemporaryDirectory();
  final framesDir = Directory('${appDir.path}/frames');

  if (framesDir.existsSync()) {
    for (var file in framesDir.listSync()) {
      if (file is File) file.deleteSync();
    }
  } else {
    framesDir.createSync(recursive: true);
  }

  final outputPattern = '${framesDir.path}/frame_%03d.jpg';
  final command = '-i "${video.path}" -vf fps=$framesPorSegundo "$outputPattern"';
  //Revisar Linea Anterior

  final session = await FFmpegKit.execute(command);

  final returnCode = await session.getReturnCode();
  final logs = await session.getAllLogsAsString();

  if (returnCode == null || !returnCode.isValueSuccess()) {
    print('FFmpeg falló con código $returnCode');
    print('FFmpeg logs: \n$logs');
    return [];
  }

  final frameFiles = framesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  print('Frames extraídos: ${frameFiles.length}');

  return frameFiles;
}*/

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

Future<List<File>> extraerFrames(BuildContext context, File video, {int framesPorSegundo = 10}) async {
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
