import 'package:flutter/material.dart';

/// Widget que muestra los resultados de la traducción de señas.
/// Presenta:
/// - El texto traducido Completo (procesado Externamente).
/// - Los gestos o tokens detectados individualmente, representados como Chips visuales.
class MostrarResultados extends StatelessWidget {
  /// Lista de tokens detectados por el modelo de predicción.
  final List<String> tokens;

  /// Texto ya calculado por el widget padre (puede ser la traducción o mensajes como "— (sin video) y los otros estados")
  final String displayText;

  /// Constructor que requiere la lista de tokens.
  const MostrarResultados({super.key, required this.tokens, required this.displayText}); // Constructor

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Caja que contiene el Card
      width: double.infinity, // Expande al ancho disponible
      //widthFactor: 0.95, // ocupa el 95% del ancho de la pantalla
      child: Card(
        elevation: 10, // Sombra para dar profundidad al Card
        color: Colors.grey[200], // Fondo gris claro
        child: Padding(
          padding: const EdgeInsets.all(16), // Espacio interno del Card
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal de la sección
              const Text(
                'Traducción Predecida:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),

              // Muestra la traducción unida; si no hay tokens, muestra displayText (previamente calculado)
              Text(
                displayText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                softWrap: true, // Permite el salto de línea si el texto es largo
              ),
              const SizedBox(height: 12),

              // Subtítulo para la sección de tokens individuales
              const Text(
                'Gestos detectados durante el Video:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),

              // Muestra cada token como un Chip visual, con separación de 8px
              Wrap(
                spacing: 8,
                children:
                    tokens.map((t) {
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
      ),
    );
  }
}
