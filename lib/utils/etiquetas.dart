const List<String> etiquetas = [
  'A',        // 0
  'B',        // 1
  'HOLA',        // 2
  'D',        // 3
  'E',        // 4
  'F',        // 5
  'G',        // 6
  'GRACIAS',  // 7
  'H',        // 8
  'C',     // 9
  'I',        // 10
  'J',        // 11
  'K',        // 12
  'L',        // 13
  'M',        // 14
  'N',        // 15
  'O',        // 16
  'P',        // 17
  'POR FAVOR',// 18
  'Q',        // 19
  'R',        // 20
  'S',        // 21
  'T',        // 22
  'TE AMO',   // 23
  'U',        // 24
  'V',        // 25
  'W',        // 26
  'X',        // 27
  'Y',        // 28
  'Z',         // 29
];

/*import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

List<String> etiquetas = [];

/// Cargar etiquetas desde el archivo data.yaml de Roboflow
Future<void> cargarEtiquetas() async {
  if (etiquetas.isNotEmpty) return; // evita recargar varias veces

  final yamlString = await rootBundle.loadString('assets/ModeloV3metadata.yaml');
  final yaml = loadYaml(yamlString);

  // Roboflow guarda las clases en la clave "names"
  final names = yaml['names'];

  if (names is List) {
    etiquetas = names.map((e) => e.toString()).toList();
  } else if (names is Map) {
    etiquetas = names.values.map((e) => e.toString()).toList();
  } else {
    throw Exception("Formato inesperado en data.yaml");
  }

  print("Etiquetas cargadas: $etiquetas");
}*/