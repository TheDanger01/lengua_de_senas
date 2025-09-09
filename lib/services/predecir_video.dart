// Version 4 - yolo [1, 34, 1029]

import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

class YoloPredictor {
  late Interpreter _interpreter;
  bool _loaded = false;

  Future<void> loadModel() async {
    final opts = InterpreterOptions()..threads = 4;
    // OJO: el asset debe llamarse exactamente como en pubspec
    _interpreter = await Interpreter.fromAsset('assets/ModeloV3best_float32.tflite', options: opts);
    //await cargarEtiquetas(); // <--- AÑADIDO AQUÍ
    //_interpreter = await Interpreter.fromAsset('assets/ModeloV1.tflite',
    //_interpreter = await Interpreter.fromAsset('assets/ModeloV2.tflite',
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  /// Devuelve el label más confiable del frame (o null si nada supera el umbral).
  Future<String?> runOnFrame(Uint8List frameBytes, {double threshold = 0.35}) async {
    if (!_loaded) return null;

    final img.Image? decoded = img.decodeImage(frameBytes);
    if (decoded == null) return null;

    // Input: 1x640x640x3 float32 normalizado 0..1
    final img.Image resized = img.copyResize(decoded, width: 416, height: 416);

    // Construimos como listas (más simple y seguro; si quieres máximo rendimiento, migramos a Float32List directos).
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

    // Salida real de tu modelo: [1, 84, 8400]
    final output = List.generate(1, (_) => List.generate(34, (_) => List.filled(3549, 0.0)));

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

    if (bestClass == -1 || bestScore < threshold) return null;
    // Mapear al label (etiquetas tiene 30; si tu modelo tiene 34, ajusta la lista)
    if (bestClass >= 0 && bestClass < etiquetas.length) {
      return etiquetas[bestClass];
    }
    // Si hay clases extra no listadas, podrías devolver null o "UNK"
    return null;
  }

  void dispose() {
    if (_loaded) {
      _interpreter.close();
      _loaded = false;
    }
  }
}