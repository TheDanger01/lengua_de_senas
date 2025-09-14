import 'package:flutter/material.dart';
import 'ui/pantalla_principal.dart';

/// Función principal que inicia la aplicación.
/// - `WidgetsFlutterBinding.ensureInitialized()` asegura que el
///   framework de Flutter esté completamente inicializado antes
///   de ejecutar la aplicación.
/// - `runApp()` recibe el widget raíz de la app e inicia la
///   construcción del árbol de widgets.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LenguaDeSenasApp());
}

/// Widget principal de la aplicación.
/// Extiende de [StatelessWidget] ya que no maneja un estado interno.
/// Configura la aplicación con Material Design a través de [MaterialApp],
/// estableciendo el tema, el título y la pantalla inicial.
class LenguaDeSenasApp extends StatelessWidget {
  const LenguaDeSenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traductor Lengua de Señas',                 /// Título de la aplicación
      theme: ThemeData(primarySwatch: Colors.deepPurple), /// Tema principal de la aplicación con un color primario.
      home: PantallaPrincipal(),                          /// Define la pantalla inicial que se mostrará al abrir la app.
      debugShowCheckedModeBanner: false,                  /// Oculta la etiqueta "Debug" que aparece en modo desarrollo.
    );
  }
}
