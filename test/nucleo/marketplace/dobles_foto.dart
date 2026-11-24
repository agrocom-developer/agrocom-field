// Dobles de prueba de las fotos: un selector que entrega una imagen de
// verdad (para que se pueda dibujar) y un compresor que no hace nada.

import 'dart:convert';
import 'dart:typed_data';

import 'package:agrocom_field/nucleo/camara/selector_imagen.dart';
import 'package:agrocom_field/nucleo/evidencias/compresor_evidencia.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_preparador.dart';

/// Un PNG verde de 8 x 8 píxeles.
final Uint8List fotoDePrueba = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAFklEQVQYV2NkYGD4z0AEYBxVSF+FAP5FDvcfRYWgAAAAAElFTkSuQmCC',
);

class SelectorImagenFalso implements SelectorImagen {
  SelectorImagenFalso({this.cancela = false});

  /// Con `true`, la persona cierra el selector sin elegir.
  bool cancela;
  var llamadas = 0;

  @override
  Future<Uint8List?> tomarFoto() async {
    llamadas++;
    return cancela ? null : fotoDePrueba;
  }

  @override
  Future<Uint8List?> elegirDeGaleria() async {
    llamadas++;
    return cancela ? null : fotoDePrueba;
  }
}

class CompresorFalso implements CompresorEvidencia {
  @override
  Future<Uint8List> comprimir(Uint8List bytesOriginales) async =>
      bytesOriginales;
}

PreparadorFoto preparadorDePrueba([SelectorImagen? selector]) =>
    PreparadorFoto(selector ?? SelectorImagenFalso(), CompresorFalso());
