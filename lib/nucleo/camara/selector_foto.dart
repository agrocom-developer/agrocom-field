import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Toma una foto con la cámara del dispositivo — REQUERIDA para incidencias
/// (HU-08) y, a futuro, otras evidencias fotográficas. Abstracta para poder
/// fakear en tests sin canal de plataforma real, mismo patrón que
/// `CompresorEvidencia`/`LinternaControlador`.
abstract class SelectorFoto {
  /// Devuelve los bytes de la foto tomada, o `null` si el piloto canceló la
  /// captura (`image_picker` no fuerza un resultado).
  Future<Uint8List?> tomarFoto();
}

/// Envuelve `image_picker`, siempre con `ImageSource.camera` — esta app
/// nunca ofrece elegir una foto de la galería para evidencias (tiene que
/// ser la captura real del momento del evento).
class SelectorFotoImagePicker implements SelectorFoto {
  @override
  Future<Uint8List?> tomarFoto() async {
    final archivo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (archivo == null) return null;
    return archivo.readAsBytes();
  }
}
