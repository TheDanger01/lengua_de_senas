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
    try {
      setState(() {
        cargando = true;
        resultado = '';
      });

      // Paso 1: Grabar video
      //Print Borrar
      print('Iniciando grabación de video...');
      File? video = await grabarVideo();
      if (video == null) {
        print("No se pudo Grabar el video.");
        setState(() {
          cargando = false;
          resultado = 'No se pudo Grabar el video.';
        });
        return;
      }
      print('Video grabado: ${video.path}');

      // Paso 2: Extraer frames
      print('Extrayendo frames del video...');
      //List<File> frames = await extraerFrames(video);   -- VERSION ANTERIOR CON FFMPG
      List<File> frames = await extraerFrames(context, video);
      if (frames.isEmpty) {
        print("No se pudieron extraer frames del video.");
        setState(() {
          cargando = false;
          resultado = 'No se pudieron extraer frames del video.';
        });
        return;
      }
      print('Frames extraídos: ${frames.length}');

      // Paso 3: Predecir secuencia
      print('Prediciendo la frase desde los frames...');
      String frase = await predecirFraseDesdeFrames(frames);
      print('Frase predicha: $frase');
      if (frase.isEmpty) {
        frase =
            'Los Gestos Realizados no son Reconocidos y No se Pudo Traducir';
      }
      setState(() {
        resultado = frase;
        cargando = false;
      });
    } catch (e, stack) {
      print('Error durante el proceso: $e');
      print('Stack trace: \n$stack');
      setState(() {
        cargando = false;
        resultado = 'Error durante el proceso: $e';
      });
    }
  }

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
}
