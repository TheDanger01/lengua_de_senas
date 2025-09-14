import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/predecir_video.dart';
import '../services/procesar_video.dart';
import '../widgets/mostrar_resultado.dart';

/// Pantalla principal de la aplicación.
/// Permite:
/// - Grabar un video con la cámara.
/// - Procesar el video usando un modelo de predicción (YOLO + post-procesamiento).
/// - Mostrar la traducción de la lengua de señas en texto.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

/// Estado asociado a [PantallaPrincipal].
/// Contiene la lógica para grabar video, ejecutar la traducción
/// y mostrar el progreso de procesamiento.
class _PantallaPrincipalState extends State<PantallaPrincipal> {
  /// Instancia del predictor YOLO encargado de cargar y ejecutar el modelo.
  final YoloPredictor _predictor = YoloPredictor();

  /// Archivo de video capturado por el usuario.
  File? _video;
  /// Indica si el sistema está procesando el video actualmente.
  bool _procesando = false;
  /// Progreso del procesamiento del video (0.0 → 1.0).
  double _progreso = 0.0;
  /// Tokens de texto resultantes de la traducción del video.
  List<String> _tokens = [];
  /// Indica si el video ya fue procesado (para evitar reprocesar).
  bool _procesado = false;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  /// Inicializa y carga el modelo de predicción.
  Future<void> _initModel() async {
    await _predictor.loadModel();
    if (!mounted) return;
    setState(() {}); // refrescar estado
  }

  /// Graba un video usando la cámara del dispositivo.
  /// - Usa `image_picker` para abrir la cámara.
  /// - Limita la duración a 15 segundos.
  /// - Guarda la ruta del video en [_video].
  Future<void> _grabarVideo() async {
    final picker = ImagePicker();
    final x = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 15)
    );
    if (x == null) return;
    setState(() {
      _video = File(x.path);
      _tokens = [];
      _procesado = false;
    });
  }

  /// Traduce el video cargado mediante el modelo.
  /// - Verifica que haya un video y que el modelo esté cargado.
  /// - Muestra el progreso del procesamiento con [_progreso].
  /// - Al finalizar, actualiza [_tokens] con los resultados.
  Future<void> _traducir() async {
    if (_video == null || !_predictor.isLoaded) return;

    setState(() { _procesando = true; _progreso = 0.0; _tokens = []; _procesado = false; });

    final res = await procesarVideo(_video!.path, _predictor, onProgress: (p) {
      setState(() { _progreso = p; });
    });

    setState(() {
      _tokens = res;
      _procesando = false;
      _progreso = 1.0;
      _procesado = true;
    });
  }

  @override
  /// Libera los recursos del predictor cuando la pantalla se destruye.
  void dispose() {
    _predictor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listo = _predictor.isLoaded; /// Verifica si el modelo está listo para usarse.

    return Scaffold(
      appBar: AppBar(
            title: const Text('Traductor de Señas por Video',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF007BFF), //Azul
          foregroundColor: Colors.white, //Blanco
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Botones principales: grabar video y traducir
            Row(
              children: [
                Expanded(
                  // Botón para grabar video
                  child: ElevatedButton.icon(
                    onPressed: listo && !_procesando ? _grabarVideo : null,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Grabar video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF), //Azul
                      foregroundColor: Colors.white, //Blanco
                      textStyle: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Botón para traducir el video grabado
                  child: ElevatedButton.icon(
                    onPressed: listo && !_procesando && _video != null ? _traducir : null,
                    icon: const Icon(Icons.translate),
                    label: const Text('Traducir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745), //Verde
                      foregroundColor: Colors.white, //Blanco
                      textStyle: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Información del video seleccionado
            if (_video != null) ...[
              if (_procesando) ...[
                Text(
                  _progreso < 1.0
                      ? 'Procesando Video... ${(_progreso * 100).toStringAsFixed(1)}%'
                      : 'Video Con Procesamiento completado.',
                )
              ]else if (_procesado) ...[
                const Text('Video Grabado y Procesado',
                style: TextStyle(fontWeight: FontWeight.bold)),
              ]else if (_procesado == false) ...[
                const Text('Video Grabado',
                style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ],
            const SizedBox(height: 12),
            //(Mostrar Ruta)if (_video != null) Text('Video: ${_video!.path}', maxLines: 1, overflow: TextOverflow.ellipsis),
            //const SizedBox(height: 12),

            /// Barra de progreso durante el procesamiento
            if (_procesando) LinearProgressIndicator(value: _progreso),
            const SizedBox(height: 12),

            /// Widget que muestra los resultados de la traducción
            Expanded(child: MostrarResultados(tokens: _tokens)),
          ],
        ),
      ),
    );
  }
}