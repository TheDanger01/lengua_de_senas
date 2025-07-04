import 'package:flutter/material.dart';

class MostrarResultado extends StatelessWidget {
  final String resultado;

  const MostrarResultado({Key? key, required this.resultado}) : super(key: key);

  @override
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
}
