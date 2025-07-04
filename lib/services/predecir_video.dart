import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

late Interpreter interpreter;

Future<void> cargarModelo() async {
  interpreter = await Interpreter.fromAsset('modelo_lengua_senas.tflite');
}

Future<String> predecirFraseDesdeFrames(List<File> frames) async {
  if (interpreter == null) await cargarModelo();

  List<String> predicciones = [];
  for (final frameFile in frames) {
    final resultado = await predecirGestoDesdeImagen(frameFile);
    if (predicciones.isEmpty || predicciones.last != resultado) {
      predicciones.add(resultado);
    }
  }

  return predicciones.join(' ');
}

Future<String> predecirGestoDesdeImagen(File frameFile) async {
  // Leer la imagen
  final bytes = await frameFile.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) return 'Desconocido';

  // Redimensionar la imagen a 224x224
  final resized = img.copyResize(image, width: 224, height: 224);

  // Construir el tensor de entrada con formato [1, 224, 224, 3]
  // tipo double y normalizado a [0,1]
  List<List<List<List<double>>>> input = List.generate(
    1,
        (_) => List.generate(
      224,
          (y) => List.generate(
        224,
            (x) {
          int pixel = resized.getPixel(x, y);
          double r = img.getRed(pixel) / 255.0;
          double g = img.getGreen(pixel) / 255.0;
          double b = img.getBlue(pixel) / 255.0;
          return [r, g, b];
        },
      ),
    ),
  );

  // Crear arreglo para la salida con tamaño según número de etiquetas
  List<List<double>> output = List.generate(1, (_) => List.filled(etiquetas.length, 0.0));

  // Ejecutar inferencia
  interpreter.run(input, output);

  // Obtener índice con la mayor probabilidad
  final maxIndex = output[0].indexWhere(
        (v) => v == output[0].reduce((a, b) => a > b ? a : b),
  );

  return etiquetas[maxIndex];
}
