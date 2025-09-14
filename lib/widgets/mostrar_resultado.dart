import 'package:flutter/material.dart';

/// Widget que muestra los resultados de la traducción de señas.
/// Recibe una lista de tokens (palabras o letras detectadas) y los presenta
/// de forma visual en la interfaz de usuario.
class MostrarResultados extends StatelessWidget {
  /// Lista de tokens detectados por el modelo de predicción.
  /// Ejemplo: ['HOLA', 'M', 'E', 'L', 'L', 'A', 'M', 'O']
  final List<String> tokens;
  /// Constructor que requiere la lista de tokens.
  const MostrarResultados({super.key, required this.tokens});

  @override
  Widget build(BuildContext context) {
    // Une todos los tokens en un solo string, separados por espacios
    final texto = tokens.join(' ');

    return SizedBox(
      width: double.infinity,
      //widthFactor: 0.95, // ocupa el 95% del ancho de la pantalla
      child: Card(
        elevation: 10, // Sombra para dar profundidad al Card
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16), // Espacio interno del Card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal de la sección
              const Text('Traducción Predecida:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple
                  ),
              ),
              const SizedBox(height: 8),

              // Muestra la traducción unida; si no hay tokens, muestra un texto por defecto
              Text(texto.isEmpty ? '— (sin detecciones)' : texto,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87
                  ),
                  softWrap: true, // Permite saltos de línea automáticos
              ),
              const SizedBox(height: 12),

              // Subtítulo para la sección de tokens individuales
              const Text('Gestos detectados durante el Video:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple
                  ),
              ),
              const SizedBox(height: 8),

              // Muestra cada token como un Chip visual, con separación de 8px
              Wrap(
                spacing: 8,
                children: tokens.map((t) {
                  return Chip(
                    label: Text(
                      t,
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                    backgroundColor: Colors.deepPurple[100],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      )
    );
  }
}