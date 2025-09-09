import 'package:flutter/material.dart';
import 'ui/pantalla_principal.dart';

void main() {
  // Asegura que el binding de widgets esté inicializado.
  // El metodo permite inicializar el sistema de enlace de widgets de Flutter.
  // Prepara la aplicación antes de lanzar la interfaz de usuario principal,
  // especialmente si tu aplicación depende de características que requieren la
  // inicialización temprana de Flutter o la comunicación con el código nativo.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LenguaDeSenasApp());
}

class LenguaDeSenasApp extends StatelessWidget {
  const LenguaDeSenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traductor Lengua de Señas',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: PantallaPrincipal(),
      debugShowCheckedModeBanner: false,
    );
  }
}
