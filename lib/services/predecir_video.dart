// Version 4 - yolo [1, 34, 3549]
import 'dart:typed_data';
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
  Future<String?> runOnFrame(Uint8List frameBytes, {double threshold = 0.35}) async {
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
}