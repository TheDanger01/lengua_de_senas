import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/predecir_video.dart';
import '../services/procesar_video.dart';
import '../widgets/mostrar_resultado.dart';
import '../ui/gestos_reconocibles.dart';

/// Pantalla principal del traductor de lenguaje de señas por video.
///
/// Funcionalidades principales:
/// 1. Grabación de video (máx. 15 segundos) usando la cámara del dispositivo
/// 2. Procesamiento del video mediante modelo YOLO para detectar gestos
/// 3. Traducción de gestos a texto legible
/// 4. Visualización de resultados con tokens individuales
/// 5. Acceso al catálogo de gestos reconocibles
///
/// Flujo de trabajo:
/// 1. Usuario presiona "Grabar video" → captura video de señas
/// 2. Usuario presiona "Traducir" → procesa el video frame por frame
/// 3. Sistema muestra progreso en tiempo real
/// 4. Resultados se muestran como texto y tokens individuales
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

/// Estado de la pantalla principal que gestiona el ciclo de vida completo
/// del proceso de traducción de señas.
class _PantallaPrincipalState extends State<PantallaPrincipal> {
  /// SERVICIO Y DEPENDENCIAS
  /// Instancia del predictor YOLO encargado de cargar y ejecutar el modelo.
  final YoloPredictor _predictor = YoloPredictor();

  // ESTADO DE VIDEO
  /// Archivo de video capturado por el usuario.
  File? _video;
  // ESTADO DE PROCESAMIENTO
  /// Indica si el sistema está procesando el video actualmente.
  bool _procesando = false;
  /// Progreso del procesamiento del video (0.0 → 1.0).
  double _progreso = 0.0;
  /// Indica si el video ya fue procesado (para evitar reprocesar).
  bool _procesado = false;

  // RESULTADOS DE TRADUCCIÓN
  /// Tokens de texto resultantes de la traducción del video.
  List<String> _tokens = [];

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  // Inicializa y carga el modelo de predicción.
  Future<void> _initModel() async {
    await _predictor.loadModel();
    if (!mounted) return;
    setState(() {}); // refrescar estado
  }

  // LOGICA DE GRABACION
  /// Graba un video usando la cámara del dispositivo.
  /// - Usa `image_picker` para abrir la cámara.
  /// - Limita la duración a 15 segundos.
  /// - Guarda la ruta del video en [_video].
  Future<void> _grabarVideo() async {
    final picker = ImagePicker();
    final x = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 15) // Limitar a 15 segundos
    );
    if (x == null) return;
    setState(() {
      _video = File(x.path);
      _tokens = [];
      _procesado = false;
    });
  }

  // LOGICA DE TRADUCCION
  /// Procesa el video y traduce los gestos a texto.
  ///
  /// Proceso:
  /// 1. Valida que exista video y modelo cargado
  /// 2. Extrae frames del video (5 FPS)
  /// 3. Ejecuta YOLO en cada frame
  /// 4. Filtra detecciones por confianza (>55%)
  /// 5. Aplica filtro de consecutividad (mínimo 2 frames)
  /// 6. Actualiza progreso en tiempo real
  ///
  /// Parámetros configurables en [procesarVideo]:
  /// - fps: Frames por segundo a analizar (5 FPS = balance rendimiento/precisión)
  /// - minConsecutive: Frames consecutivos mínimos para validar un gesto (2)
  /// - threshold: Umbral de confianza mínimo (0.55 = 55%)
  Future<void> _traducir() async {
    // Validaciones previas
    if (_video == null || !_predictor.isLoaded) return;

    // Inicializa estado de procesamiento
    setState(() { _procesando = true; _progreso = 0.0; _tokens = []; _procesado = false; });

    /*final res = await procesarVideo(_video!.path, _predictor, onProgress: (p) {
      setState(() { _progreso = p; });
    });*/// Final res -- ORIGINAL ANTERIOR Forma 1
    //Forma 2 Procesar
    final res = await procesarVideo(
      _video!.path,
      _predictor,
      onProgress: (p) { setState(() { _progreso = p; }); },
      fps: 5,
      minConsecutive: 2,
      threshold: 0.55,
    );


    // Actualiza estado con resultados finales
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
    final texto = _tokens.join(' ');

    // Calcular displayText según el estado actual (_video, _procesando, _procesado, _progreso)
    String displayText;
    if (_video == null) {
      displayText = '— (Sin Video)'; //Recuerda grabar un video
    } else if (_procesando) {
      /*// Si quieres mostrar progreso en el texto
      displayText = _progreso < 1.0
          ? 'Procesando Video... ${(_progreso * 100).toStringAsFixed(1)}%'
          : 'Video con procesamiento completado.';*/
      displayText = '— (Procesando Video...)'; // Mostrar solo texto fijo durante procesamiento
    } else if (!_procesado) {
      // Hay video, pero todavía no se presionó traducir (no procesado)
      displayText = '— (Pulse Traducir)'; // Recuerda presionar Traducir
    } else {
      // Ya se procesó
      if (texto.isEmpty) {
        displayText = '— NO SE ENCONTRÓ NINGÚN GESTO CONFIABLE EN EL VIDEO - POR FAVOR GRABE OTRO VIDEO'; // no se detectaron tokens
      } else {
        displayText = texto; // la traducción real
      }
    }

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
            /*(Mostrar Ruta -no necesario-)if (_video != null) Text('Video: ${_video!.path}', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),*/

            /// Barra de progreso durante el procesamiento
            if (_procesando) LinearProgressIndicator(value: _progreso),
            const SizedBox(height: 12),

            /// Widget que muestra los resultados de la traducción
            Expanded(
              child: MostrarResultados(
                tokens: _tokens,
                displayText: displayText,
              ),
            ),

            /// Boton Seccion Ejemplos Gestos Reconocibles
            const SizedBox(height: 12), //separador arriba
            SizedBox(
             width: double.infinity, // Ancho completo
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GestosReconociblesPage(),),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Ver Gestos Reconocibles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F42C1), //Púrpura
                  foregroundColor: Colors.white, //Blanco
                  textStyle: const TextStyle(fontSize: 15),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}