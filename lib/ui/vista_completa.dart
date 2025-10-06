import 'package:flutter/material.dart';

/// Página que muestra una imagen de gesto de lenguaje de señas en pantalla completa.
/// Permite al usuario ver en detalle cómo se realiza un gesto específico.
/// La imagen se muestra centrada y puede hacer zoom mediante gestos táctiles.
/// Esta vista es accedida desde [GestosReconociblesPage] al tocar un gesto.
class VistaCompletaPage extends StatelessWidget {
  // Ruta local del asset de la imagen a mostrar.
  final String ruta;

  // Nombre o descripción del gesto que se muestra en la imagen. (Se Muestra en el AppBar)
  final String nombre;

  const VistaCompletaPage({
    super.key,
    required this.ruta,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: const Color(0xFF007BFF), //Azul //backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Image.asset(ruta),
      ),
    );
  }
}