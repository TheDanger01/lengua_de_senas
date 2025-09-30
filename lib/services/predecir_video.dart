// Version 4 - yolo [1, 34, 3549]
// predecir_video.dart --> Version 2
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

class Prediction {
  final String? label;
  final double score; // 0.0 .. 1.0
  Prediction(this.label, this.score);
}

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

/// Letterbox: mantiene proporciones y centra la imagen en un fondo.
/// Rellena con color `fill` (ARGB).
img.Image letterbox(img.Image src, int targetW, int targetH, {int fill = 0xFF727272}) { // RGB(114, 114, 114) - YOLOv8 estándar
  final double scale = math.min(targetW / src.width, targetH / src.height);
  final int newW = (src.width * scale).round();
  final int newH = (src.height * scale).round();
  final img.Image resized = img.copyResize(src, width: newW, height: newH, interpolation: img.Interpolation.cubic);

  final img.Image out = img.Image(width: targetW, height: targetH);
  // Rellenar con el color especificado
  //out.clear();
  out.clear(img.ColorRgba8(
      (fill >> 16) & 0xFF,  // R
      (fill >> 8) & 0xFF,   // G
      fill & 0xFF,          // B
      (fill >> 24) & 0xFF   // A
  ));
  final int dx = ((targetW - newW) / 2).round();
  final int dy = ((targetH - newH) / 2).round();
  img.compositeImage(
    out,
    resized,
    dstX: dx,
    dstY: dy,
    //srcX: 0,
    //srcY: 0,
    //srcW: resized.width,
    //srcH: resized.height,
  );
  return out;
}

/// Clase encargada de realizar la **predicción de gestos en frames de video**
/// Utilizando un modelo YOLO convertido a TensorFlow Lite.
/// Flujo general:
/// 1. Cargar el modelo `.tflite` desde los assets.
/// 2. Preprocesar cada frame (decodificación y resize a 416x416).
/// 3. Ejecutar inferencia con el modelo YOLO en TensorFlow Lite.
/// 4. Retornar la etiqueta más confiable que supere el umbral definido.
class YoloPredictor {
  late Interpreter _interpreter; // Motor de inferencia TFLite
  bool _loaded = false;          // Estado de carga del modelo

  /// Carga el modelo TFLite desde los assets del proyecto.
  /// - Usa 4 threads para aprovechar CPUs multinúcleo.
  /// - El nombre del archivo debe coincidir con el declarado en `pubspec.yaml`.
  Future<void> loadModel() async {
    final opts = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset('assets/ModeloV5_150Epoch_float32.tflite', options: opts);
    //await cargarEtiquetas(); // <--- AÑADIDO AQUÍ - si se usa etiquetas dinámicas
    _loaded = true;
  }

  /// Indica si el modelo ya fue cargado correctamente.
  bool get isLoaded => _loaded;

  /// Ejecuta la predicción sobre un frame (bytes).
  /// Retorna Prediction(label, score) o Prediction(null, score) si score < threshold.
  /// /// Parámetros:
  //   /// - [frameBytes]: Imagen en bytes (JPEG extraído del video).
  //   /// - [threshold]: Umbral mínimo de confianza (por defecto 0.55-Ajustable).
  //   /// Flujo:
  //   /// 1. Decodifica la imagen (`image` package).
  //   /// 2. Redimensiona a `416x416` píxeles (input esperado por el modelo).
  //   /// 3. Normaliza los valores RGB entre `0.0` y `1.0`.
  //   /// 4. Ejecuta la inferencia con `_interpreter.run`.
  //   /// 5. Recorre las salidas `[1, 34, 3549]` para buscar la clase con mayor score.
  //   /// Retorna:
  //   /// - Devuelve el label más confiable del frame
  //   /// - La etiqueta asociada a la clase más confiable (según `etiquetas`).
  //   /// - `null` si ninguna predicción supera el umbral.
  Future<Prediction?> runOnFrame(Uint8List frameBytes, {double threshold = 0.75}) async {
    if (!_loaded) return null;

    // Decodificar la imagen
    final img.Image? decoded = img.decodeImage(frameBytes);
    if (decoded == null) return null;

    // 1) Letterbox a 416x416 [Depende Del Modelo](igual que en training si usaste YOLO con letterbox)
    final img.Image resized = letterbox(decoded, 416, 416, fill: 0xFF727272);
    // Alternativa sin letterbox (puede distorsionar):
    //final img.Image resized = img.copyResize(decoded, width: 416, height: 416);


    // 2) Construir input normalizado 0..1
    // Construcción del tensor de entrada en formato List (más seguro y portable)
    // Mantengo la estructura de listas para compatibilidad con tu intérprete actual.
    final input = List.generate(1, (_) =>
        List.generate(416, (y) =>
            List.generate(416, (x) {
              final p = resized.getPixel(x, y);
              return [
                p.r / 255.0,
                p.g / 255.0,
                p.b / 255.0,
              ];
            })
        )
    );

    // 3) Inicializar salida: si tu .tflite tiene otra forma, ajusta aquí.
    // Nota: tu código anterior usaba [1,34,3549]. Si tu export actual es distinto,
    // ajusta los números o extrae la forma desde el intérprete.
    final output = List.generate(1, (_) => List.generate(34, (_) => List.filled(3549, 0.0)));

    // Ejecutar inferencia
    _interpreter.run(input, output);

    // 4) Detectar si hay que aplicar sigmoid (heurística: valores fuera 0..1)
    // Parte Nueva: comprobar si los valores ya están entre 0 y 1
    bool requiresActivation = false;
    outer:
    for (int c = 0; c < output[0].length; c++) {
      for (int a = 0; a < output[0][c].length; a++) {
        final v = output[0][c][a];
        if (v < 0.0 || v > 1.0) { requiresActivation = true; break outer; }
      }
    }

    // 5) Buscar la mejor clase y su score
    int bestClass = -1;
    double bestScore = 0.0;
    for (int c = 0; c < output[0].length; c++) { //34 clases
      for (int a = 0; a < output[0][c].length; a++) { //3549 anclas
        double s = output[0][c][a];
        if (requiresActivation) s = _sigmoid(s);
        if (s > bestScore) {
          bestScore = s;
          bestClass = c;
        }
      }
    }

    // DEBUG: opcional (quita en release)
    // print('DEBUG predict: bestClass=$bestClass bestScore=${(bestScore*100).toStringAsFixed(1)}% requiresActivation=$requiresActivation');

    // 6) Umbral: si no cumple, devolvemos null pero con el score.
    if (bestClass == -1 || bestScore < threshold) {
      return Prediction(null, bestScore);
    }

    // 7) Mapear etiqueta (segura: comprobar rango)
    if (bestClass >= 0 && bestClass < etiquetas.length) {
      return Prediction(etiquetas[bestClass], bestScore);
    }

    // Si clase fuera de etiquetas, devolver null (o 'UNK' si quieres)
    return Prediction(null, bestScore);
  }

  /// Libera los recursos del intérprete TFLite.
  void dispose() {
    if (_loaded) {
      _interpreter.close();
      _loaded = false;
    }
  }
}
