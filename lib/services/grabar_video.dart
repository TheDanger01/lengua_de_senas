// Importa la librería de Dart para trabajar con archivos en el sistema.
// En este caso, se usa para manipular el archivo de video grabado.
// Importa el paquete image_picker, que permite acceder a la cámara
// o galería del dispositivo para capturar imágenes o videos.
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Clase que encapsula la lógica para grabar un video desde la cámara.
/// Se implementa como un "servicio" para separar la lógica de captura
/// de la lógica de la interfaz de usuario.
class VideoService {
  // Se crea una instancia privada de ImagePicker, que será usada
  // para acceder a la cámara del dispositivo.
  final ImagePicker _picker = ImagePicker();

  /// Metodo asíncrono que abre la cámara del dispositivo para grabar un video.
  /// Retorna:
  /// - Un objeto `File` si el usuario graba un video con éxito.
  /// - `null` si el usuario cancela la grabación o ocurre un error.
  Future<File?> grabarVideo() async {
    // Se abre la cámara del dispositivo en modo de grabación de video.
    final pickedFile = await _picker.pickVideo(source: ImageSource.camera);
    // Si el usuario efectivamente grabó un video, se obtiene su ruta
    // y se envuelve en un objeto `File` para poder manipularlo en el código.
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    // Si el usuario canceló o no se pudo grabar el video, retorna null.
    return null;
  }
}
