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
