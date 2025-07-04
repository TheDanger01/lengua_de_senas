/*import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video + IA Flutter',
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isRecording = false;
  late Future<void> _initializeControllerFuture;
  String? _videoPath;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String> _getVideoFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/gesture_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return filePath;
  }

  Future<void> _startRecording() async {
    final path = await _getVideoFilePath();
    await _controller.startVideoRecording();
    setState(() {
      _isRecording = true;
      _videoPath = path;
    });
  }

  Future<void> _stopRecording() async {
    final recording = await _controller.stopVideoRecording();
    final file = File(_videoPath!);
    await file.writeAsBytes(await recording.readAsBytes());
    setState(() {
      _isRecording = false;
    });
    // Aquí puedes invocar el modelo TFLite para procesar el video
    print('Video guardado en: $_videoPath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Grabar gesto')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
      ),
    );
  }
}*/

import 'package:flutter/material.dart';
import 'ui/pantalla_principal.dart';

void main() {
  runApp(LenguaDeSenasApp());
}

class LenguaDeSenasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traductor Lengua de Señas',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: PantallaPrincipal(),
    );
  }
}
