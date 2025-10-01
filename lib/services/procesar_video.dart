// Version Nueva - yolo [1, 34, 3549]
/*import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'predecir_video.dart';

/// Definición de tipo para una función de progreso.
/// Se usa para reportar el avance del procesamiento de video
/// en un rango entre `0.0` y `1.0`.
typedef Progress = void Function(double progress);

/// Procesa un video **frame por frame** a 3 FPS para traducir lengua de señas.
/// - Usa [`video_player`](https://pub.dev/packages/video_player) para obtener la duración real del video.
/// - Usa [`video_thumbnail`](https://pub.dev/packages/video_thumbnail) para extraer frames en formato JPEG.
/// - Llama al modelo [YoloPredictor] para predecir en cada frame.
/// - Evita agregar repeticiones consecutivas de la misma predicción.
/// - Retorna la lista de tokens (predicciones de gestos).
/// Parámetros:
/// - [videoPath]: Ruta local del archivo de video.
/// - [predictor]: Instancia del modelo cargado para ejecutar predicciones.
/// - [onProgress]: Callback opcional para informar el progreso (0.0–1.0).
/// Retorna:
/// - Una lista de tokens (`List<String>`) representando los gestos detectados.
Future<List<String>> procesarVideo(String videoPath, YoloPredictor predictor, {Progress? onProgress}) async {
  // 1) Obtener duración exacta con video_player
  final controller = VideoPlayerController.networkUrl(Uri.file(videoPath));
  await controller.initialize();
  final durationMs = controller.value.duration.inMilliseconds;
  await controller.dispose();

  // Si el video es inválido o no tiene duración, retornar vacío
  if (durationMs <= 0) return [];

  // Configuración: 3 FPS -> cada frame cada ~333 ms
  const fps = 3;
  final stepMs = (1000 / fps).round();
  final totalFrames = (durationMs / stepMs).ceil();

  final List<String> tokens = [];
  String? ultimo; // último token agregado (para evitar repeticiones consecutivas)

  // 2) Extraer frames y procesarlos uno por uno con video_thumbnail
  for (int i = 0; i < totalFrames; i++) {
    final timeMs = i * stepMs;

    // Extraer frame en el instante indicado
    // video_thumbnail maneja internamente MediaMetadataRetriever
    final Uint8List? frameBytes = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.PNG,  // Formato PNG para mejor calidad O jpeg
      timeMs: timeMs,
      quality: 100, // calidad media para optimizar rendimiento
    );

    // Si el frame no pudo extraerse, avanzar en progreso y continuar
    if (frameBytes == null) {
      onProgress?.call(i / totalFrames);
      continue;
    }

    // Ejecutar predicción del modelo sobre el frame
    final String? pred = await predictor.runOnFrame(frameBytes);

    // Agregar token si es válido y diferente del anterior
    if (pred != null && pred.isNotEmpty) {
      if (ultimo == null || ultimo != pred) {
        tokens.add(pred);
        ultimo = pred;
      }
    }

    // Reportar progreso del procesamiento
    onProgress?.call((i + 1) / totalFrames);
  }

  // Retornar lista final de tokens (traducción de señas)
  return tokens;
}*/

//*FORMA 2// procesar_video.dart -->
import 'dart:typed_data';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'predecir_video.dart';

typedef Progress = void Function(double progress);

/// Procesa el video frame por frame con:
/// - extracción PNG (sin compresión),
/// - filtrado por threshold (ej 0.75),
/// - confirmación por frames consecutivos (minConsecutive).
Future<List<String>> procesarVideo(
    String videoPath,
    YoloPredictor predictor, {
      Progress? onProgress,
      int fps = 5, // subir de 3 a 5 puede ayudar si las señas son rápidas
      int minConsecutive = 2, // cuántos frames iguales se requieren para aceptar
      double threshold = 0.55, // confianza mínima
    }) async {
  // 1) Obtener duración exacta con video_player
  final controller = VideoPlayerController.file(File(videoPath));
  await controller.initialize();
  final durationMs = controller.value.duration.inMilliseconds;
  await controller.dispose();

  if (durationMs <= 0) return [];

  final stepMs = (1000 / fps).round();
  final totalFrames = (durationMs / stepMs).ceil();

  final List<String> tokens = [];
  String? candidate; // etiqueta candidato que estamos contando
  int candidateCount = 0;

  for (int i = 0; i < totalFrames; i++) {
    final timeMs = i * stepMs;

    final Uint8List? frameBytes = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.PNG, // PNG reduce artefactos
      timeMs: timeMs,
      quality: 100,
    );

    if (frameBytes == null) {
      onProgress?.call(i / totalFrames);
      continue;
    }

    // Ejecutar predicción; devuelve Prediction(label, score) o (null, score)
    final Prediction? pred = await predictor.runOnFrame(frameBytes, threshold: threshold);

    // Si pred es null o label==null -> no hay pred válida en este frame
    if (pred == null || pred.label == null) {
      // reset candidato (rompemos la cadena consecutiva)
      candidate = null;
      candidateCount = 0;
    } else {
      final String lbl = pred.label!;
      final double score = pred.score;

      // Si es el mismo candidato, incrementa; si no, reinicia
      if (candidate == lbl) {
        candidateCount += 1;
      } else {
        candidate = lbl;
        candidateCount = 1;
      }

      // Si alcanzamos la confirmación por consecutivos, aceptar
      if (candidateCount >= minConsecutive) {
        // Evitar agregar repetidos consecutivos en tokens
        if (tokens.isEmpty || tokens.last != candidate) {
          tokens.add(candidate!);
        }
        // Para evitar agregar la misma etiqueta una y otra vez sin "nueva confirmación",
        // reiniciamos el candidato para requerir otra confirmación más adelante.
        candidate = null;
        candidateCount = 0;
      }
    }

    onProgress?.call((i + 1) / totalFrames);
  }

  // Al finalizar, asegurar progreso 100%
  onProgress?.call(1.0);
  return tokens;
}
