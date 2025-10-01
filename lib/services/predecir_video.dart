// Version 4 - yolo [1, 34, 3549]
// predecir_video.dart --> Version 2
/*import 'dart:typed_data';
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
/// 2. Preprocesar cada frame (decodificación y resize a [416x416 o 640x640]depende del modelo).
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
    _interpreter = await Interpreter.fromAsset('assets/ModeloV4_200Epoch_float32.tflite', options: opts);
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
  //   /// 2. Redimensiona a `416x416` o `640x640` píxeles (input esperado por el modelo).
  //   /// 3. Normaliza los valores RGB entre `0.0` y `1.0`.
  //   /// 4. Ejecuta la inferencia con `_interpreter.run`.
  //   /// 5. Recorre las salidas `[1, 34, 3549] o [1,34,8400]` para buscar la clase con mayor score.
  //   /// Retorna:
  //   /// - Devuelve el label más confiable del frame
  //   /// - La etiqueta asociada a la clase más confiable (según `etiquetas`).
  //   /// - `null` si ninguna predicción supera el umbral.
  Future<Prediction?> runOnFrame(Uint8List frameBytes, {double threshold = 0.55}) async {
    if (!_loaded) return null;

    // Decodificar la imagen
    final img.Image? decoded = img.decodeImage(frameBytes);
    if (decoded == null) return null;

    // 1) Letterbox a 416x416 o 640x640 [Depende Del Modelo](igual que en training si usaste YOLO con letterbox)
    final img.Image resized = letterbox(decoded, 640, 640, fill: 0xFF727272);
    // Alternativa sin letterbox (puede distorsionar):
    //final img.Image resized = img.copyResize(decoded, width: 640, height: 640);


    // 2) Construir input normalizado 0..1
    // Construcción del tensor de entrada en formato List (más seguro y portable)
    // Mantengo la estructura de listas para compatibilidad con tu intérprete actual.
    final input = List.generate(1, (_) =>
        List.generate(640, (y) =>
            List.generate(640, (x) {
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
    final output = List.generate(1, (_) => List.generate(34, (_) => List.filled(8400, 0.0)));

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
      for (int a = 0; a < output[0][c].length; a++) { //3549 o 8400 anclas
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
*/
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

class Prediction {
  final String? label;
  final double score;
  final BoundingBox? box; // AÑADIDO: información de ubicación

  Prediction(this.label, this.score, {this.box});
}

class BoundingBox {
  final double x, y, width, height;
  BoundingBox(this.x, this.y, this.width, this.height);
}

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

/// Letterbox optimizado: mantiene proporciones y centra la imagen
img.Image letterbox(img.Image src, int targetW, int targetH, {int fill = 0xFF727272}) {
  final double scale = math.min(targetW / src.width, targetH / src.height);
  final int newW = (src.width * scale).round();
  final int newH = (src.height * scale).round();

  final img.Image resized = img.copyResize(
      src,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear // Cubic es más lento, linear es suficiente
  );

  final img.Image out = img.Image(width: targetW, height: targetH);
  out.clear(img.ColorRgba8(
      (fill >> 16) & 0xFF,
      (fill >> 8) & 0xFF,
      fill & 0xFF,
      (fill >> 24) & 0xFF
  ));

  final int dx = ((targetW - newW) / 2).round();
  final int dy = ((targetH - newH) / 2).round();

  img.compositeImage(out, resized, dstX: dx, dstY: dy);
  return out;
}

class YoloPredictor {
  late Interpreter _interpreter;
  bool _loaded = false;

  // Cache para evitar realocaciones
  List<List<List<List<double>>>>? _inputBuffer;
  List<List<List<double>>>? _outputBuffer;

  int inputSize = 640;
  int numClasses = 30; // Clases de gestos (0-29)
  int numAnchors = 8400;

  Future<void> loadModel() async {
    final opts = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset(
        'assets/ModeloV4_200Epoch_float32.tflite',
        options: opts
    );

    // Preallocar buffers (OPTIMIZACIÓN: evita realocaciones en cada frame)
    _inputBuffer = List.generate(
        1, (_) => List.generate(
        inputSize, (_) => List.generate(
        inputSize, (_) => List.filled(3, 0.0)
    )
    )
    );

    // Verificar forma real del modelo
    // Tu modelo: [1, 34, 8400] donde 34 = 4_boxes + 30_classes
    final outputShape = _interpreter.getOutputTensor(0).shape;
    print('🔍 Forma de salida del modelo: $outputShape');

    if (outputShape.length >= 3) {
      // Formato transpuesto: [1, channels, anchors]
      final channels = outputShape[1]; // 34
      numAnchors = outputShape[2];     // 8400
      numClasses = channels - 4;       // 30
    }

    // Buffer en formato transpuesto [1, 34, 8400]
    _outputBuffer = List.generate(
        1, (_) => List.generate(
        34, (_) => List.filled(numAnchors, 0.0)
    )
    );

    _loaded = true;
  }

  bool get isLoaded => _loaded;

  /// Preprocessing optimizado usando buffer preallocado
  void _preprocessFrame(img.Image image) {
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final p = image.getPixel(x, y);
        _inputBuffer![0][y][x][0] = p.r / 255.0;
        _inputBuffer![0][y][x][1] = p.g / 255.0;
        _inputBuffer![0][y][x][2] = p.b / 255.0;
      }
    }
  }

  /// Non-Maximum Suppression simplificado para clasificación
  List<Prediction> _applyNMS(List<Prediction> predictions, double iouThreshold) {
    if (predictions.length <= 1) return predictions;

    predictions.sort((a, b) => b.score.compareTo(a.score));
    List<Prediction> keep = [];

    for (var pred in predictions) {
      bool shouldKeep = true;

      for (var kept in keep) {
        if (pred.label == kept.label && pred.box != null && kept.box != null) {
          // Calcular IoU si es necesario (para gestos, puede ser suficiente con threshold simple)
          final iou = _calculateIoU(pred.box!, kept.box!);
          if (iou > iouThreshold) {
            shouldKeep = false;
            break;
          }
        }
      }

      if (shouldKeep) keep.add(pred);
    }

    return keep;
  }

  double _calculateIoU(BoundingBox a, BoundingBox b) {
    final x1 = math.max(a.x - a.width / 2, b.x - b.width / 2);
    final y1 = math.max(a.y - a.height / 2, b.y - b.height / 2);
    final x2 = math.min(a.x + a.width / 2, b.x + b.width / 2);
    final y2 = math.min(a.y + a.height / 2, b.y + b.height / 2);

    if (x2 < x1 || y2 < y1) return 0.0;

    final intersection = (x2 - x1) * (y2 - y1);
    final union = a.width * a.height + b.width * b.height - intersection;

    return intersection / union;
  }

  /// Predicción optimizada para formato transpuesto [1, 34, 8400]
  Future<Prediction?> runOnFrame(
      Uint8List frameBytes,
      {double threshold = 0.55, bool returnAll = false}
      ) async {
    if (!_loaded) return null;

    final img.Image? decoded = img.decodeImage(frameBytes);
    if (decoded == null) return null;

    final img.Image resized = letterbox(decoded, inputSize, inputSize);

    // Preprocesar en buffer preallocado
    _preprocessFrame(resized);

    // Ejecutar inferencia
    _interpreter.run(_inputBuffer!, _outputBuffer!);

    // Detectar si necesita activación
    bool requiresActivation = false;
    outer:
    for (int ch = 0; ch < _outputBuffer![0].length; ch++) {
      for (int a = 0; a < _outputBuffer![0][ch].length; a++) {
        final v = _outputBuffer![0][ch][a];
        if (v < 0.0 || v > 1.0) {
          requiresActivation = true;
          break outer;
        }
      }
    }

    List<Prediction> candidates = [];

    // FORMATO TRANSPUESTO: [1, 34, 8400]
    // Índices 0-3: bounding boxes [x, y, w, h]
    // Índices 4-33: 30 clases de gestos
    for (int anchor = 0; anchor < numAnchors; anchor++) {
      // Extraer bounding box
      final boxX = _outputBuffer![0][0][anchor];
      final boxY = _outputBuffer![0][1][anchor];
      final boxW = _outputBuffer![0][2][anchor];
      final boxH = _outputBuffer![0][3][anchor];

      // Encontrar clase con mayor score
      int bestClass = -1;
      double bestScore = 0.0;

      // Las clases van del índice 4 al 33 (30 clases totales)
      // Índices: 4, 5, 6, ..., 32, 33 = 30 clases
      for (int c = 0; c < 30; c++) {  // CORREGIDO: exactamente 30 iteraciones
        double score = _outputBuffer![0][4 + c][anchor];
        if (requiresActivation) score = _sigmoid(score);

        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }

      // Filtrar por threshold
      if (bestScore >= threshold && bestClass >= 0 && bestClass < etiquetas.length) {
        candidates.add(Prediction(
            etiquetas[bestClass],
            bestScore,
            box: BoundingBox(boxX, boxY, boxW, boxH)
        ));
      }
    }

    if (candidates.isEmpty) return Prediction(null, 0.0);

    // Aplicar NMS si hay múltiples detecciones
    if (candidates.length > 1) {
      candidates = _applyNMS(candidates, 0.45);
    }

    // Retornar la mejor predicción
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first;
  }

  void dispose() {
    if (_loaded) {
      _interpreter.close();
      _loaded = false;
      _inputBuffer = null;
      _outputBuffer = null;
    }
  }
}