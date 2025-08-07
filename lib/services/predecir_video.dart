/* Version 1
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

late Interpreter interpreter;

/// Carga el modelo TFLite desde los assets
Future<void> cargarModelo() async {
  interpreter = await Interpreter.fromAsset('assets/modelov5.tflite');
}

/// Dada una lista de frames (imágenes), predice la frase completa
Future<String> predecirFraseDesdeFrames(List<File> frames) async {
  //if (interpreter == null)
  await cargarModelo();

  List<String> predicciones = [];

  for (final frameFile in frames) {
    final resultado = await predecirGestoDesdeImagen(frameFile);

    // Evitar repetir el mismo gesto consecutivo
    if (predicciones.isEmpty || predicciones.last != resultado) {
      predicciones.add(resultado);
    }
  }

  return predicciones.join(' ');
}

/// Procesa una imagen individual y predice el gesto asociado
Future<String> predecirGestoDesdeImagen(File frameFile) async {
  final bytes = await frameFile.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) return 'Desconocido';

  // Redimensionar la imagen a 224x224
  final resized = img.copyResize(image, width: 224, height: 224);

  // Formato requerido por el modelo: [1, 224, 224, 3]
  final input = List.generate(
    1,
    (_) => List.generate(
      224,
      (y) => List.generate(224, (x) {
        final pixel = resized.getPixel(x, y);
        return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
      }),
    ),
  );

  final output = List.generate(1, (_) => List.filled(etiquetas.length, 0.0));

  interpreter.run(input, output);

  final maxIndex = output[0].indexWhere(
    (v) => v == output[0].reduce((a, b) => a > b ? a : b),
  );

  return etiquetas[maxIndex];
} */

//Version 2
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

late Interpreter interpreter;

/// Carga el modelo TFLite desde los assets
Future<void> cargarModelo() async {
  interpreter = await Interpreter.fromAsset('assets/modeloV100.tflite');
}

/// Dada una lista de frames (imágenes), predice la frase completa
Future<String> predecirFraseDesdeFrames(List<File> frames) async {
  //if (interpreter == null)
  await cargarModelo();

  List<String> predicciones = [];
  String? ultimaLetra;

  for (final frameFile in frames) {
    final resultado = await predecirGestoDesdeImagen(frameFile);

    // Evitar repetir el mismo gesto consecutivo
    if (predicciones.isEmpty || predicciones.last != resultado) {
      predicciones.add(resultado);
    }

    ultimaLetra = resultado;
  }

  return predicciones.join(' ');
}

/// Procesa una imagen individual y predice el gesto asociado
Future<String> predecirGestoDesdeImagen(File frameFile) async {
  final bytes = await frameFile.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) return 'Desconocido';

  // Redimensionar la imagen a 224x224
  final resized = img.copyResize(image, width: 224, height: 224);

  // Formato requerido por el modelo: [1, 224, 224, 3]
  final input = List.generate(
    1,
        (_) => List.generate(
      224,
          (y) => List.generate(224, (x) {
        final pixel = resized.getPixel(x, y);
        return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
      }),
    ),
  );

  final output = List.generate(1, (_) => List.filled(etiquetas.length, 0.0));

  interpreter.run(input, output);

  final maxIndex = output[0].indexWhere(
        (v) => v == output[0].reduce((a, b) => a > b ? a : b),
  );

  return etiquetas[maxIndex];
}