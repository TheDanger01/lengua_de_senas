import 'package:flutter/material.dart';
import '../services/grabar_video.dart';
import '../services/procesar_video.dart';
import '../services/predecir_video.dart';
import '../widgets/mostrar_resultado.dart';
import 'dart:io';

class PantallaPrincipal extends StatefulWidget {
  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  String resultado = '';
  bool cargando = false;

  Future<void> _iniciarProceso() async {
    setState(() => cargando = true);

    // Paso 1: Grabar video
    File? video = await grabarVideo();
    if (video == null) {
      setState(() => cargando = false);
      return;
    }

    // Paso 2: Extraer frames
    List<File> frames = await extraerFrames(video);

    // Paso 3: Predecir secuencia
    String frase = await predecirFraseDesdeFrames(frames);

    setState(() {
      resultado = frase;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Traductor de Señas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando) CircularProgressIndicator(),
            if (!cargando && resultado.isNotEmpty)
              MostrarResultado(resultado: resultado),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: cargando ? null : _iniciarProceso,
              icon: Icon(Icons.videocam),
              label: Text('Grabar y traducir'),
            ),
          ],
        ),
      ),
    );
  }
}
