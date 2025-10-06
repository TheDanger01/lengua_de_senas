import 'package:flutter/material.dart';
import '../ui/vista_completa.dart';

/// Página que muestra un catálogo de gestos de lenguaje de señas reconocibles.
///
/// Presenta una lista scrollable de todos los gestos que la aplicación
/// puede reconocer, incluyendo:
/// - Letras del alfabeto (A-Z)
/// - Palabras comunes (HOLA, GRACIAS, TE AMO, POR FAVOR)
///
/// Cada gesto es clickeable y abre una vista detallada en pantalla completa.
class GestosReconociblesPage extends StatelessWidget {
  const GestosReconociblesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de gestos (ruta y nombre)
    final List<Map<String, String>> gestos = [
      {"ruta": "assets/LETRAS/LETRAS/A.jpg", "nombre": "A"},
      {"ruta": "assets/LETRAS/LETRAS/B.jpg", "nombre": "B"},
      {"ruta": "assets/LETRAS/LETRAS/C.jpg", "nombre": "C"},
      {"ruta": "assets/LETRAS/LETRAS/D.jpg", "nombre": "D"},
      {"ruta": "assets/LETRAS/LETRAS/E.jpg", "nombre": "E"},
      {"ruta": "assets/LETRAS/LETRAS/F.jpg", "nombre": "F"},
      {"ruta": "assets/LETRAS/LETRAS/G.jpg", "nombre": "G"},
      {"ruta": "assets/LETRAS/LETRAS/GRACIAS.jpg", "nombre": "GRACIAS"},
      {"ruta": "assets/LETRAS/LETRAS/H.jpg", "nombre": "H"},
      {"ruta": "assets/LETRAS/LETRAS/HOLA.jpg", "nombre": "HOLA"},
      {"ruta": "assets/LETRAS/LETRAS/I.jpg", "nombre": "I"},
      {"ruta": "assets/LETRAS/LETRAS/J.jpg", "nombre": "J"},
      {"ruta": "assets/LETRAS/LETRAS/K.jpg", "nombre": "K"},
      {"ruta": "assets/LETRAS/LETRAS/L.jpg", "nombre": "L"},
      {"ruta": "assets/LETRAS/LETRAS/M.jpg", "nombre": "M"},
      {"ruta": "assets/LETRAS/LETRAS/N.jpg", "nombre": "N"},
      {"ruta": "assets/LETRAS/LETRAS/O.jpg", "nombre": "O"},
      {"ruta": "assets/LETRAS/LETRAS/P.jpg", "nombre": "P"},
      {"ruta": "assets/LETRAS/LETRAS/POR FAVOR.jpg", "nombre": "POR FAVOR"},
      {"ruta": "assets/LETRAS/LETRAS/Q.jpg", "nombre": "Q"},
      {"ruta": "assets/LETRAS/LETRAS/R.jpg", "nombre": "R"},
      {"ruta": "assets/LETRAS/LETRAS/S.jpg", "nombre": "S"},
      {"ruta": "assets/LETRAS/LETRAS/T.jpg", "nombre": "T"},
      {"ruta": "assets/LETRAS/LETRAS/TE AMO.jpg", "nombre": "TE AMO"},
      {"ruta": "assets/LETRAS/LETRAS/U.jpg", "nombre": "U"},
      {"ruta": "assets/LETRAS/LETRAS/V.jpg", "nombre": "V"},
      {"ruta": "assets/LETRAS/LETRAS/W.jpg", "nombre": "W"},
      {"ruta": "assets/LETRAS/LETRAS/X.jpg", "nombre": "X"},
      {"ruta": "assets/LETRAS/LETRAS/Y.jpg", "nombre": "Y"},
      {"ruta": "assets/LETRAS/LETRAS/Z.jpg", "nombre": "Z"},
    ];

    return Scaffold(
      // AppBar con título centrado y colores personalizados
      appBar: AppBar(
        title: const Text('Traductor de Señas por Video',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF007BFF), //Azul
        foregroundColor: Colors.white, //Blanco
      ),
      // Cuerpo con fondo púrpura claro y lista de gestos
      body: Container(
        color: Colors.purple.shade50, // púrpura bien claro
        padding: const EdgeInsets.all(8), // margen general alrededor de la lista
        child: ListView.builder(
          itemCount: gestos.length,
          itemBuilder: (context, index) {
            final gesto = gestos[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8), // espacio entre ítems
              padding: const EdgeInsets.all(8), // espacio interno del contenedor
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Image.asset(
                      gesto["ruta"]!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  gesto["nombre"]!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VistaCompletaPage(
                        ruta: gesto["ruta"]!,
                        nombre: gesto["nombre"]!,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
