import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Elige una imagen con la cámara o desde la galería. Sirve para las fotos
/// del dron, que el piloto puede ya tener guardadas; las fotos de avance del
/// lote siguen saliendo de `SelectorFoto` (siempre cámara).
abstract class SelectorImagen {
  /// `null` si la persona canceló.
  Future<Uint8List?> tomarFoto();

  Future<Uint8List?> elegirDeGaleria();
}

class SelectorImagenImagePicker implements SelectorImagen {
  Future<Uint8List?> _de(ImageSource fuente) async {
    final archivo = await ImagePicker().pickImage(source: fuente);
    return archivo?.readAsBytes();
  }

  @override
  Future<Uint8List?> tomarFoto() => _de(ImageSource.camera);

  @override
  Future<Uint8List?> elegirDeGaleria() => _de(ImageSource.gallery);
}
