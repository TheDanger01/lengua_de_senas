// Version Nueva - yolo [1, 34, 3549]
import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'predecir_video.dart';

typedef Progress = void Function(double progress);

/// Procesa el video frame por frame a 3 FPS, omitiendo repeticiones consecutivas.
/// Devuelve la lista de tokens (traducción).
Future<List<String>> procesarVideo(String videoPath, YoloPredictor predictor, {Progress? onProgress}) async {
  // 1) Obtener duración exacta con video_player
  final controller = VideoPlayerController.networkUrl(Uri.file(videoPath));
  await controller.initialize();
  final durationMs = controller.value.duration.inMilliseconds;
  await controller.dispose();

  if (durationMs <= 0) return [];

  const fps = 3;
  final stepMs = (1000 / fps).round();
  final totalFrames = (durationMs / stepMs).ceil();

  final List<String> tokens = [];
  String? ultimo;

  // 2) Extraer frames con video_thumbnail
  for (int i = 0; i < totalFrames; i++) {
    final timeMs = i * stepMs;

    // video_thumbnail maneja internamente los recursos; no uses MediaMetadataRetriever directo
    final Uint8List? frameBytes = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs,
      quality: 75,
    );

    if (frameBytes == null) {
      onProgress?.call(i / totalFrames);
      continue;
    }

    final String? pred = await predictor.runOnFrame(frameBytes);

    if (pred != null && pred.isNotEmpty) {
      if (ultimo == null || ultimo != pred) {
        tokens.add(pred);
        ultimo = pred;
      }
    }

    onProgress?.call((i + 1) / totalFrames);
  }

  return tokens;
}