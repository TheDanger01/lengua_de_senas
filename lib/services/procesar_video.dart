import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

/// Extrae [framesPorSegundo] del video como imágenes JPG.
/// por defecto 20 fps, puedes cambiarlo desde el parámetro o editar el valor por defecto abajo.
Future<List<File>> extraerFrames(
    File video, {
      int framesPorSegundo = 20,
    }) async {
  final appDir = await getTemporaryDirectory();
  final framesDir = Directory('${appDir.path}/frames');

  if (!framesDir.existsSync()) {
    framesDir.createSync(recursive: true);
  } else {
    // Limpia frames anteriores
    for (var f in framesDir.listSync()) {
      f.deleteSync();
    }
  }

  final outputPattern = '${framesDir.path}/frame_%03d.jpg';
  final command = "-i ${video.path} -vf fps=$framesPorSegundo $outputPattern";

  await FFmpegKit.execute(command); // Usa ffmpeg_kit_flutter correctamente

  final frameFiles = framesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.jpg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  return frameFiles;
}

