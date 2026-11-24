import 'dart:typed_data';

import '../camara/selector_imagen.dart';
import '../evidencias/compresor_adaptativo.dart' show FotoDemasiadoPesada;
import '../evidencias/compresor_evidencia.dart';
import 'dominio/falla.dart';

/// De dónde sale la foto que la persona va a subir.
enum OrigenFoto { camara, galeria }

/// Elige una foto (cámara o galería) y la deja comprimida a menos de 300 KB,
/// lista para subir (invariante 7). Una sola puerta para las fotos de perfil
/// y de terreno, en los tres flavors.
class PreparadorFoto {
  const PreparadorFoto(this._selector, this._compresor);

  final SelectorImagen _selector;
  final CompresorEvidencia _compresor;

  /// Los bytes comprimidos, o `null` si la persona canceló. Lanza
  /// [OperacionRechazada] si la foto no se puede dejar bajo el tope.
  Future<Uint8List?> preparar(OrigenFoto origen) async {
    final original = switch (origen) {
      OrigenFoto.camara => await _selector.tomarFoto(),
      OrigenFoto.galeria => await _selector.elegirDeGaleria(),
    };
    if (original == null) return null;
    try {
      return await _compresor.comprimir(original);
    } on FotoDemasiadoPesada {
      throw const OperacionRechazada(
        'La foto es muy pesada. Elige otra o toma una nueva.',
      );
    }
  }
}

/// El texto para la persona y si el fallo fue falta de red, para cualquier
/// error de una operación en línea.
({String mensaje, bool sinRed}) describirFalla(
  Object error, {
  required String porDefecto,
}) {
  if (error is SinConexion) {
    return (
      mensaje: 'Sin conexión. Revisa tu señal y vuelve a intentar.',
      sinRed: true,
    );
  }
  if (error is OperacionRechazada) {
    return (mensaje: error.mensaje, sinRed: false);
  }
  return (mensaje: porDefecto, sinRed: false);
}
