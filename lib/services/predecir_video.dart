import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/etiquetas.dart';

// MODELO DE DATOS
/// Representa una predicción con etiqueta, score y bounding box opcional.
class Prediction {
  final String? label; // Etiqueta Gesto Detectado. null si no hay predicción válida
  final double score; // Confianza De Prediccion (0.0 - 1.0)
  final BoundingBox? box; // AÑADIDO: información de ubicación

  Prediction(this.label, this.score, {this.box});
}

/// Define un rectángulo delimitador (bounding box) para ubicar un gesto.
///
/// Coordenadas en formato YOLO:
/// - [x], [y]: Centro del rectángulo
/// - [width], [height]: Dimensiones del rectángulo
///
/// Todas las coordenadas son relativas al tamaño de la imagen (0.0 a 1.0).
class BoundingBox {
  final double x, y, width, height;
  BoundingBox(this.x, this.y, this.width, this.height);
}

// FUNCIONES AUXILIARES
/// Función sigmoide para normalizar valores entre 0 y 1.
///
/// Convierte valores en el rango (-∞, +∞) al rango (0, 1).
/// Fórmula: σ(x) = 1 / (1 + e^(-x))
///
/// Usada cuando el modelo YOLO no tiene activación sigmoide incorporada
/// en su última capa (modelos sin post-procesamiento).
double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

/// Letterbox optimizado: mantiene proporciones y centra la imagen en un fondo. Rellena con color `fill` (ARGB).
/// Redimensiona una imagen manteniendo su relación de aspecto (letterboxing).
///
/// Proceso:
/// 1. Calcula el factor de escala para que la imagen quepa en [targetW x targetH]
/// 2. Redimensiona la imagen proporcionalmente
/// 3. Centra la imagen redimensionada en un canvas del tamaño objetivo
/// 4. Rellena los bordes vacíos con el color especificado
///
/// Parámetros:
/// - [src]: Imagen original a redimensionar
/// - [targetW]: Ancho objetivo en píxeles
/// - [targetH]: Alto objetivo en píxeles
/// - [fill]: Color de relleno en formato ARGB (por defecto: gris 0xFF727272)
///
/// Retorna:
/// - Imagen de exactamente [targetW x targetH] píxeles con la imagen original
///   centrada y escalada proporcionalmente
///
/// Ejemplo:
/// Una imagen de 1920x1080 en un canvas de 640x640:
/// - Factor de escala: 640/1920 = 0.333
/// - Tamaño escalado: 640x360
/// - Posición: centrada horizontalmente, con bandas grises arriba y abajo
img.Image letterbox(img.Image src, int targetW, int targetH, {int fill = 0xFF727272}) {
  // Calcula el factor de escala que mantiene la relación de aspecto
  final double scale = math.min(targetW / src.width, targetH / src.height);

  // Dimensiones de la imagen escalada
  final int newW = (src.width * scale).round();
  final int newH = (src.height * scale).round();

  // Redimensiona la imagen con interpolación lineal (balance velocidad/calidad)
  final img.Image resized = img.copyResize(
      src,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear // Cubic es más lento, linear es suficiente
  );

  // Rellenar con el color especificado
  final img.Image out = img.Image(width: targetW, height: targetH);
  out.clear(img.ColorRgba8(
      (fill >> 16) & 0xFF,
      (fill >> 8) & 0xFF,
      fill & 0xFF,
      (fill >> 24) & 0xFF
  ));

  // Calcula offset para centrar la imagen redimensionada
  final int dx = ((targetW - newW) / 2).round();
  final int dy = ((targetH - newH) / 2).round();

  // Compone la imagen redimensionada sobre el canvas
  img.compositeImage(out, resized, dstX: dx, dstY: dy);
  return out;
}

// CLASE PRINCIPAL
/// Predictor de gestos de lenguaje de señas usando modelo YOLO en TensorFlow Lite.
///
/// Arquitectura del modelo:
/// - Input: [1, 640, 640, 3] - Imagen RGB normalizada (0.0 a 1.0)
/// - Output: [1, 34, 8400] - Detecciones en formato transpuesto
///   - 34 canales = 4 (bounding box) + 30 (clases de gestos)
///   - 8400 anchors = puntos de detección en la imagen
///
/// Clases reconocibles:
/// - 26 letras del alfabeto (A-Z)
/// - 4 palabras comunes (HOLA, GRACIAS, TE AMO, POR FAVOR)
///
/// Flujo de uso:
/// ```dart
/// final predictor = YoloPredictor();
/// await predictor.loadModel(); // Cargar modelo una vez
///
/// // Procesar cada frame del video
/// for (var frameBytes in videoFrames) {
///   final prediction = await predictor.runOnFrame(frameBytes);
///   if (prediction?.label != null) {
///     print('Gesto detectado: ${prediction!.label}');
///   }
/// }
///
/// predictor.dispose(); // Liberar recursos
class YoloPredictor {
  late Interpreter _interpreter; // Motor de inferencia TFLite
  bool _loaded = false;         // Estado de carga del modelo

  // Cache para evitar realocaciones
  // Buffers preallocados para entrada y salida
  /// Dimensiones: [1, 640, 640, 3] = 1 imagen de 640x640 píxeles RGB
  List<List<List<List<double>>>>? _inputBuffer; // Entrada preallocada
  /// Dimensiones: [1, 34, 8400] = 1 batch, 34 canales, 8400 anchors
  List<List<List<double>>>? _outputBuffer; // Salida preallocada

  // Parámetros del modelo
  int inputSize = 640; // Tamaño de entrada (640x640 píxeles)
  int numClasses = 30; // Clases de gestos (0-29)
  int numAnchors = 8400; // Puntos de detección (anchors)

  // Carga Del Modelo
  /// Carga el modelo YOLO desde los assets y prepara buffers de memoria.
  ///
  /// Proceso:
  /// 1. Carga el archivo .tflite desde assets
  /// 2. Configura 4 threads para aprovechar CPUs multinúcleo
  /// 3. Inspecciona la forma de salida del modelo
  /// 4. Prealoca buffers de entrada/salida para optimizar rendimiento
  ///
  /// Configuración de threads:
  /// - 4 threads es óptimo para la mayoría de dispositivos móviles modernos
  /// - Ajustar según el hardware disponible si es necesario
  ///
  /// Buffers preallocados:
  /// - Evitan realocación de memoria en cada frame (mejora velocidad ~30%)
  /// - Reutilizados para todas las inferencias posteriores
  ///
  /// Throws:
  /// - Exception si el archivo .tflite no existe o está corrupto
  Future<void> loadModel() async {
    // Configurar opciones del intérprete
    final opts = InterpreterOptions()..threads = 4;
    // Cargar modelo desde assets
    _interpreter = await Interpreter.fromAsset(
        'assets/ModeloV4_200Epoch_float32.tflite',
        options: opts
    );

    // Preallocar buffer de entrada [1, 640, 640, 3]
    _inputBuffer = List.generate(
        1, (_) => List.generate(
        inputSize, (_) => List.generate(
        inputSize, (_) => List.filled(3, 0.0)
    )
    )
    );

    // Verificar forma real del modelo
    // Inspeccionar forma de salida del modelo
    // Modelo: [1, 34, 8400] donde 34 = 4_boxes + 30_classes
    final outputShape = _interpreter.getOutputTensor(0).shape;
    print('Forma de salida del modelo: $outputShape');

    // Validar y extraer dimensiones
    if (outputShape.length >= 3) {
      // Formato transpuesto: [1, channels, anchors]
      final channels = outputShape[1]; // 34 = 4 bbox + 30 clases
      numAnchors = outputShape[2];     // 8400 puntos de detección
      numClasses = channels - 4;       // 30 clases
    }

    // Buffer en formato transpuesto (Buufer de Salida)[1, 34, 8400]
    _outputBuffer = List.generate(
        1, (_) => List.generate(
        34, (_) => List.filled(numAnchors, 0.0)
    )
    );

    _loaded = true;
  }

  /// Indica si el modelo ya fue cargado correctamente.
  bool get isLoaded => _loaded;

  // PROCESAMIENTO DE FRAMES
  /// Preprocesa una imagen en el buffer de entrada preallocado.
  ///
  /// Proceso:
  /// 1. Itera sobre cada píxel de la imagen [640x640]
  /// 2. Extrae componentes RGB
  /// 3. Normaliza valores de [0-255] a [0.0-1.0]
  /// 4. Escribe directamente en [_inputBuffer] (sin copias adicionales)
  ///
  /// Optimización:
  /// - Usa buffer preallocado para evitar allocaciones
  /// - Normalización en línea durante la iteración
  /// - Acceso directo sin estructuras intermedias
  ///
  /// Parámetros:
  /// - [image]: Imagen ya redimensionada a [inputSize x inputSize]
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

  // POST-PROCESAMIENTO
  /// Aplica Non-Maximum Suppression para eliminar detecciones duplicadas.
  ///
  /// Problema que resuelve:
  /// YOLO puede detectar el mismo gesto múltiples veces con bounding boxes
  /// ligeramente diferentes. NMS mantiene solo la detección más confiable.
  ///
  /// Algoritmo:
  /// 1. Ordena predicciones por confianza (mayor a menor)
  /// 2. Itera sobre cada predicción
  /// 3. Compara con predicciones ya aceptadas de la misma clase
  /// 4. Si IoU > umbral, descarta la predicción (es duplicada)
  /// 5. Si IoU ≤ umbral, acepta la predicción (es única)
  ///
  /// Parámetros:
  /// - [predictions]: Lista de predicciones candidatas
  /// - [iouThreshold]: Umbral de IoU (típicamente 0.45)
  ///   - Valores bajos = más estricto (elimina más duplicados)
  ///   - Valores altos = más permisivo (mantiene más detecciones)
  ///
  /// Retorna:
  /// - Lista filtrada sin duplicados
  List<Prediction> _applyNMS(List<Prediction> predictions, double iouThreshold) {
    if (predictions.length <= 1) return predictions;

    // Ordenar por confianza descendente
    predictions.sort((a, b) => b.score.compareTo(a.score));
    List<Prediction> keep = [];

    for (var pred in predictions) {
      bool shouldKeep = true;

      // Comparar con predicciones ya aceptadas
      for (var kept in keep) {
        // Solo comparar si es la misma clase y ambas tienen bounding box
        if (pred.label == kept.label && pred.box != null && kept.box != null) {
          // Calcular IoU si es necesario (para gestos, puede ser suficiente con threshold simple)
          final iou = _calculateIoU(pred.box!, kept.box!);
          // Si el solapamiento es alto, es duplicado
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

  /// Calcula el Intersection over Union (IoU) entre dos bounding boxes.
  ///
  /// IoU mide qué tanto se solapan dos rectángulos:
  /// - IoU = 0.0: No se tocan (0% de solapamiento)
  /// - IoU = 0.5: Se solapan 50%
  /// - IoU = 1.0: Son idénticos (100% de solapamiento)
  ///
  /// Fórmula:
  /// IoU = Área de intersección / Área de unión
  ///
  /// Parámetros:
  /// - [a], [b]: Bounding boxes a comparar
  ///
  /// Retorna:
  /// - Valor entre 0.0 y 1.0 indicando el grado de solapamiento
  double _calculateIoU(BoundingBox a, BoundingBox b) {
    // Calcular coordenadas de la intersección
    final x1 = math.max(a.x - a.width / 2, b.x - b.width / 2);
    final y1 = math.max(a.y - a.height / 2, b.y - b.height / 2);
    final x2 = math.min(a.x + a.width / 2, b.x + b.width / 2);
    final y2 = math.min(a.y + a.height / 2, b.y + b.height / 2);

    // Si no hay intersección, retornar 0
    if (x2 < x1 || y2 < y1) return 0.0;

    // Calcular áreas
    final intersection = (x2 - x1) * (y2 - y1);
    final union = a.width * a.height + b.width * b.height - intersection;

    return intersection / union;
  }

  // INFERENCIA PRINCIPAL
  /// Ejecuta la predicción sobre un frame (bytes).
  /// Ejecuta la predicción sobre un frame de video.
  ///
  /// Pipeline completo:
  /// 1. **Validación**: Verifica que el modelo esté cargado
  /// 2. **Decodificación**: Convierte bytes JPEG a imagen
  /// 3. **Letterboxing**: Redimensiona a 640x640 manteniendo proporción
  /// 4. **Preprocesamiento**: Normaliza RGB a [0.0-1.0]
  /// 5. **Inferencia**: Ejecuta modelo YOLO
  /// 6. **Activación**: Aplica sigmoide si es necesario
  /// 7. **Parseo**: Extrae predicciones del formato [1, 34, 8400]
  /// 8. **Filtrado**: Aplica threshold de confianza
  /// 9. **NMS**: Elimina detecciones duplicadas
  /// 10. **Retorno**: Devuelve la mejor predicción
  ///
  /// Formato de salida del modelo:
  /// [1, 34, 8400] donde:
  /// - Índices 0-3: Bounding box [x, y, width, height]
  /// - Índices 4-33: Scores de 30 clases de gestos
  /// - 8400: Número de anchors (puntos de detección)
  ///
  /// Parámetros:
  /// - [frameBytes]: Frame del video en formato JPEG
  /// - [threshold]: Confianza mínima para aceptar una detección (0.55 = 55%)
  /// - [returnAll]: Si true, retorna todas las detecciones (útil para debug)
  ///
  /// Retorna:
  /// - [Prediction] con el gesto más confiable
  /// - null si no hay detecciones o el modelo no está cargado
  Future<Prediction?> runOnFrame(
      Uint8List frameBytes,
      {double threshold = 0.55, bool returnAll = false}
      ) async {
    // 1. Validar que el modelo esté cargado
    if (!_loaded) return null;

    // 2. Decodificar la imagen
    final img.Image? decoded = img.decodeImage(frameBytes);
    if (decoded == null) return null;

    // 3. Letterbox a 640x640
    final img.Image resized = letterbox(decoded, inputSize, inputSize);

    // 4. Preprocesar en buffer preallocado
    _preprocessFrame(resized);

    // 5. INTERFERENCIA Ejecutar MODELO
    _interpreter.run(_inputBuffer!, _outputBuffer!);

    // 6. Detectar si necesita activación (sigmoide)
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

    // 7. PREDICCIONES Buscar todas las predicciones que superen el umbral
    List<Prediction> candidates = [];

    // FORMATO TRANSPUESTO: [1, 34, 8400]
    // Índices 0-3: bounding boxes [x, y, w, h]
    // Índices 4-33: 30 clases de gestos
    // Iterar sobre cada anchor (punto de detección)
    for (int anchor = 0; anchor < numAnchors; anchor++) {
      // Extraer bounding box (Indices 0-3)
      final boxX = _outputBuffer![0][0][anchor];
      final boxY = _outputBuffer![0][1][anchor];
      final boxW = _outputBuffer![0][2][anchor];
      final boxH = _outputBuffer![0][3][anchor];

      // Encontrar clase con mayor score (índices 4-33)
      int bestClass = -1;
      double bestScore = 0.0;

      // Las clases van del índice 4 al 33 (30 clases totales)
      // Índices: 4, 5, 6, ..., 32, 33 = 30 clases
      for (int c = 0; c < 30; c++) {  // CORREGIDO: exactamente 30 iteraciones
        // Extraer score de la clase actual
        double score = _outputBuffer![0][4 + c][anchor];
        // Aplicar sigmoide si es necesario
        if (requiresActivation) score = _sigmoid(score);

        // Actualizar mejor clase si el score es mayor
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }

      // 8. Filtrar por threshold
      // Solo aceptar predicciones que:
      // 1. Superen el threshold de confianza
      // 2. Tengan un índice de clase válido
      // 3. La clase exista en la lista de etiquetas
      if (bestScore >= threshold && bestClass >= 0 && bestClass < etiquetas.length) {
        candidates.add(Prediction(
            etiquetas[bestClass],
            bestScore,
            box: BoundingBox(boxX, boxY, boxW, boxH)
        ));
      }
    }

    // 9. MANEJO DE CASOS SIN DETECCIONES
    // Si no hay candidatos, retornar null
    if (candidates.isEmpty) return Prediction(null, 0.0);

    // 10. NMS (Non-Maximum Suppression)
    // Aplicar NMS si hay múltiples detecciones
    if (candidates.length > 1) {
      candidates = _applyNMS(candidates, 0.45);
    }

    // 11. RETORNAR MEJOR PREDICCIÓN
    // Ordenar por confianza descendente
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.first;
  }

  // LIBERACION DE RECURSOS
  /// Libera todos los recursos del predictor.
  ///
  /// Debe llamarse cuando ya no se necesite el predictor para:
  /// - Cerrar el intérprete de TensorFlow Lite
  /// - Liberar memoria de los buffers
  /// - Evitar memory leaks
  ///
  /// Después de llamar a dispose(), el predictor no puede usarse nuevamente
  /// a menos que se llame a [loadModel] otra vez.
  void dispose() {
    if (_loaded) {
      _interpreter.close();
      _loaded = false;
      _inputBuffer = null;
      _outputBuffer = null;
    }
  }
}