import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

/// Elige una imagen con la cámara o desde la galería. Sirve para las fotos
/// del dron, que el piloto puede ya tener guardadas; las fotos de avance del
/// lote siguen saliendo de `SelectorFoto` (siempre cámara).
/// El sistema negó el permiso de la cámara (iOS: `camera_access_denied`). Quien
/// captura lo traduce a «denegado» y guía a los ajustes (ADR 0026).
class PermisoCamaraDenegado implements Exception {
  const PermisoCamaraDenegado();
}

abstract class SelectorImagen {
  /// `null` si la persona canceló.
  Future<Uint8List?> tomarFoto();

  Future<Uint8List?> elegirDeGaleria();
}

class SelectorImagenImagePicker implements SelectorImagen {
  Future<Uint8List?> _de(ImageSource fuente) async {
    try {
      final archivo = await ImagePicker().pickImage(source: fuente);
      return await archivo?.readAsBytes();
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') throw const PermisoCamaraDenegado();
      rethrow;
    }
  }

  @override
  Future<Uint8List?> tomarFoto() => _de(ImageSource.camera);

  @override
  Future<Uint8List?> elegirDeGaleria() => _de(ImageSource.gallery);
}
