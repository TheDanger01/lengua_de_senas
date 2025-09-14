// Lista constante que contiene las etiquetas (clases) que reconoce el modelo.
// Cada posición de la lista corresponde al índice de clase que devuelve el modelo
// en la predicción. Es muy importante que este orden coincida exactamente con
// el orden de clases usado al entrenar el modelo en Roboflow/TensorFlow.
const List<String> etiquetas = [
  'A',        // 0
  'B',        // 1
  'C',        // 2
  'D',        // 3
  'E',        // 4
  'F',        // 5
  'G',        // 6
  'GRACIAS',  // 7
  'H',        // 8
  'HOLA',     // 9
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

// ------------------------------------------------------------
// CÓDIGO COMENTADO (opcion B) PARA CARGAR ETIQUETAS DINÁMICAMENTE
// ------------------------------------------------------------
/*
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

List<String> etiquetas = [];

/// Función que permite cargar etiquetas de forma dinámica desde un archivo YAML.
/// Esto es útil si las clases se generan automáticamente desde Roboflow u otro
/// dataset y no quieres definirlas a mano en el código.
///
/// Se busca un archivo `ModeloV3metadata.yaml` dentro de la carpeta assets.
/// Este archivo debe contener las clases en una clave `names`, ya sea como lista
/// o como mapa (dependiendo del formato del export de Roboflow).
Future<void> cargarEtiquetas() async {
  // Si ya están cargadas, no hace nada (evita recargar múltiples veces).
  if (etiquetas.isNotEmpty) return;

  // Carga el contenido del archivo YAML desde los assets de Flutter.
  final yamlString = await rootBundle.loadString('assets/ModeloV3metadata.yaml');
  final yaml = loadYaml(yamlString);

  // Roboflow normalmente guarda las clases bajo la clave "names".
  final names = yaml['names'];

  // Caso 1: lista de nombres (ej. ['A','B','C',...])
  if (names is List) {
    etiquetas = names.map((e) => e.toString()).toList();

  // Caso 2: mapa con índices como claves (ej. {0:'A',1:'B',...})
  } else if (names is Map) {
    etiquetas = names.values.map((e) => e.toString()).toList();
  } else {
    // Si el formato no coincide con los esperados, lanza un error.
    throw Exception("Formato inesperado en data.yaml");
  }

  print("Etiquetas cargadas: $etiquetas"); // Muestra en consola las etiquetas cargadas.
}
*/