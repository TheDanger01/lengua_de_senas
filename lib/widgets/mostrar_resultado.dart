/*
// Formato Antiguo Colores
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Text(
        resultado,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20, // tamaño mediano
          fontWeight: FontWeight.w500,
          color: Colors.deepPurple[800],
        ),
        softWrap: true, // salto de línea automático
      ),
    );
  }
}*/

import 'package:flutter/material.dart';

class MostrarResultados extends StatelessWidget {
  final List<String> tokens;
  const MostrarResultados({super.key, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final texto = tokens.join(' ');
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Traducción:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(texto.isEmpty ? '— (sin detecciones)' : texto, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            const Text('Tokens detectados (sin repeticiones consecutivas):'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tokens.map((t) => Chip(label: Text(t))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}