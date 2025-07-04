import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';

final FlutterFFmpeg _ffmpeg = FlutterFFmpeg();

/// Extrae [framesPorSegundo] del video como imágenes JPG
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
    framesDir.listSync().forEach(
      (f) => f.deleteSync(),
    ); // limpia frames previos
  }

  // ⚙️ Edita esta línea para cambiar cuántos frames por segundo deseas extraer
  final outputPattern = '${framesDir.path}/frame_%03d.jpg';
  final command = "-i ${video.path} -vf fps=$framesPorSegundo $outputPattern";

  await _ffmpeg.execute(command);

  final frameFiles =
      framesDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return frameFiles;
}
