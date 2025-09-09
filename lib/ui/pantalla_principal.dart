/*Formato Colores Antiguo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Traductor de Señas Chilenas',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando) CircularProgressIndicator(),
            if (!cargando && resultado.isNotEmpty)
              MostrarResultado(resultado: resultado),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: cargando ? null : _iniciarProceso,
                icon: Icon(Icons.videocam),
                label: Text('Grabar y traducir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/predecir_video.dart';
import '../services/procesar_video.dart';
import '../widgets/mostrar_resultado.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final YoloPredictor _predictor = YoloPredictor();

  File? _video;
  bool _procesando = false;
  double _progreso = 0.0;
  List<String> _tokens = [];

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    await _predictor.loadModel();
    if (!mounted) return;
    setState(() {}); // refrescar estado
  }

  Future<void> _grabarVideo() async {
    final picker = ImagePicker();
    final x = await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 15));
    if (x == null) return;
    setState(() {
      _video = File(x.path);
      _tokens = [];
    });
  }

  Future<void> _traducir() async {
    if (_video == null || !_predictor.isLoaded) return;

    setState(() { _procesando = true; _progreso = 0.0; _tokens = []; });

    final res = await procesarVideo(_video!.path, _predictor, onProgress: (p) {
      setState(() { _progreso = p; });
    });

    setState(() {
      _tokens = res;
      _procesando = false;
      _progreso = 1.0;
    });
  }

  @override
  void dispose() {
    _predictor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listo = _predictor.isLoaded;

    return Scaffold(
      appBar: AppBar(title: const Text('Traductor de Señas por Video')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: listo && !_procesando ? _grabarVideo : null,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Grabar video'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: listo && !_procesando && _video != null ? _traducir : null,
                    icon: const Icon(Icons.translate),
                    label: const Text('Traducir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_video != null) Text('Video: ${_video!.path}', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            if (_procesando) LinearProgressIndicator(value: _progreso),
            const SizedBox(height: 12),
            Expanded(child: MostrarResultados(tokens: _tokens)),
          ],
        ),
      ),
    );
  }
}
  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Traductor de Señas Chilenas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando) CircularProgressIndicator(),
            if (!cargando && resultado.isNotEmpty)
              MostrarResultado(resultado: resultado),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: cargando ? null : procesarVideo,
                icon: Icon(Icons.videocam),
                label: Text('Grabar y traducir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }*/