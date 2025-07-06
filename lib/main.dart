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
