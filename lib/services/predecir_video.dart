// Version 4 - yolo [1, 34, 3549]
/*import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

/// Clase encargada de realizar la **predicción de gestos en frames de video**
/// utilizando un modelo YOLO convertido a TensorFlow Lite.
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
    // OJO: el asset debe llamarse exactamente como en pubspec
    _interpreter = await Interpreter.fromAsset('assets/ModeloV3best_float32.tflite', options: opts);
    //await cargarEtiquetas(); // <--- AÑADIDO AQUÍ - si se usa etiquetas dinámicas
    _loaded = true;
  }

  /// Indica si el modelo ya fue cargado correctamente.
  bool get isLoaded => _loaded;

  /// Ejecuta la predicción sobre un **frame de video**.
  /// Parámetros:
  /// - [frameBytes]: Imagen en bytes (JPEG extraído del video).
  /// - [threshold]: Umbral mínimo de confianza (por defecto 0.35).
  /// Flujo:
  /// 1. Decodifica la imagen (`image` package).
  /// 2. Redimensiona a `416x416` píxeles (input esperado por el modelo).
  /// 3. Normaliza los valores RGB entre `0.0` y `1.0`.
  /// 4. Ejecuta la inferencia con `_interpreter.run`.
  /// 5. Recorre las salidas `[1, 34, 3549]` para buscar la clase con mayor score.
  /// Retorna:
  /// - Devuelve el label más confiable del frame
  /// - La etiqueta asociada a la clase más confiable (según `etiquetas`).
  /// - `null` si ninguna predicción supera el umbral.
  Future<String?> runOnFrame(Uint8List frameBytes, {double threshold = 0.95}) async {  // Ajustado umbral (Precision) a 0.95
    if (!_loaded) return null;

    // Decodificar la imagen
    final img.Image? decoded = img.decodeImage(frameBytes);
    if (decoded == null) return null;

    // Input: 1x416x416x3 float32 normalizado 0..1 -> Redimensionar a 416x416 (tamaño de entrada del modelo)
    final img.Image resized = img.copyResize(decoded, width: 416, height: 416);

    // Construcción del tensor de entrada en formato List (más seguro y portable)
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

    // Inicializar salida esperada real del modelo: [1, 34, 3549] float32
    final output = List.generate(1, (_) => List.generate(34, (_) => List.filled(3549, 0.0)));

    // Ejecutar inferencia
    _interpreter.run(input, output);

    // Buscar la clase con mayor score entre todas las anclas
    int bestClass = -1;
    double bestScore = 0.0;

    for (int c = 0; c < 34; c++) {
      for (int a = 0; a < 3549; a++) {
        final s = output[0][c][a];
        if (s > bestScore) {
          bestScore = s;
          bestClass = c;
        }
      }
    }

    // Si no se encontró ninguna clase con score suficiente → null
    if (bestClass == -1 || bestScore < threshold) return null;
    // Mapear al label (etiquetas tiene 30; si tu modelo tiene 34, ajusta la lista)
    if (bestClass >= 0 && bestClass < etiquetas.length) {
      return etiquetas[bestClass];
    }
    // Si hay clases extras fuera de rango no listadas (ej. modelo > etiquetas disponibles)
    return null; // se puede devolver null o "UNK" (Unknown)
  }

  /// Libera los recursos del intérprete TFLite.
  void dispose() {
    if (_loaded) {
      _interpreter.close();
      _loaded = false;
    }
  }
}*/

// predecir_video.dart
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
img.Image letterbox(img.Image src, int targetW, int targetH, {int fill = 0xFF777777}) {
  final double scale = math.min(targetW / src.width, targetH / src.height);
  final int newW = (src.width * scale).round();
  final int newH = (src.height * scale).round();
  final img.Image resized = img.copyResize(src, width: newW, height: newH, interpolation: img.Interpolation.cubic);

  final img.Image out = img.Image(width: targetW, height: targetH);
  out.clear();
  final int dx = ((targetW - newW) / 2).round();
  final int dy = ((targetH - newH) / 2).round();
  img.compositeImage(
    out,
    resized,
    dstX: dx,
    dstY: dy,
    srcX: 0,
    srcY: 0,
    srcW: resized.width,
    srcH: resized.height,
    // Opcional: dstW, dstH si quieres redimensionar al copiar
  );
  return out;
}

class YoloPredictor {
  late Interpreter _interpreter;
  bool _loaded = false;

  Future<void> loadModel() async {
    final opts = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset('assets/ModeloV3best_float32.tflite', options: opts);
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  /// Ejecuta la predicción sobre un frame (bytes).
  /// Retorna Prediction(label, score) o Prediction(null, score) si score < threshold.
  Future<Prediction?> runOnFrame(Uint8List frameBytes, {double threshold = 0.75}) async {
    if (!_loaded) return null;

    final img.Image? decoded = img.decodeImage(frameBytes);
    if (decoded == null) return null;

    // 1) Letterbox a 416x416 (igual que en training si usaste YOLO con letterbox)
    final img.Image resized = letterbox(decoded, 416, 416, fill: 0xFF777777);

    // 2) Construir input normalizado 0..1
    // Mantengo la estructura de listas para compatibilidad con tu intérprete actual.
    final input = List.generate(1, (_) =>
        List.generate(416, (y) =>
            List.generate(416, (x) {
              final p = resized.getPixel(x, y);
              final r = resized.getPixel(x, y).r;  //final int r = pixel.r; // Canal rojo
              final g = resized.getPixel(x, y).g;  //final int g = pixel.g; // Canal verde
              final b = resized.getPixel(x, y).b;  //final int b = pixel.b; // Canal azul
              return [
                r / 255.0,
                g / 255.0,
                b / 255.0,
              ];
            })
        )
    );

    // 3) Inicializar salida: si tu .tflite tiene otra forma, ajusta aquí.
    // Nota: tu código anterior usaba [1,34,3549]. Si tu export actual es distinto,
    // ajusta los números o extrae la forma desde el intérprete.
    final output = List.generate(1, (_) => List.generate(34, (_) => List.filled(3549, 0.0)));

    _interpreter.run(input, output);

    // 4) Detectar si hay que aplicar sigmoid (heurística: valores fuera 0..1)
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
    for (int c = 0; c < output[0].length; c++) {
      for (int a = 0; a < output[0][c].length; a++) {
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

  void dispose() {
    if (_loaded) {
      _interpreter.close();
      _loaded = false;
    }
  }
}
