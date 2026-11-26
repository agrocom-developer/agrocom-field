import 'package:flutter/painting.dart';

/// Colores para texto y velos que van encima de una foto. No salen de la
/// paleta del tema porque la foto es oscura en ambos modos; los velos
/// garantizan el contraste.
abstract final class SobreFotoCampo {
  static const Color texto = Color(0xFFFFFFFF);
  static const Color textoSecundario = Color(0xFFE6EBE7);
  static const Color puntoInactivo = Color(0x80FFFFFF);

  /// Velo superior: oscurece la barra de estado.
  static const List<Color> veloSuperior = [
    Color(0xA6050A06),
    Color(0x73050A06),
    Color(0x00050A06),
  ];

  /// Velo general de la portada: deja libre la foto y oscurece el pie.
  static const List<Color> veloPortada = [
    Color(0x00050A06),
    Color(0x00050A06),
    Color(0xB3050A06),
    Color(0xE6050A06),
  ];

  /// Velo propio del bloque de texto.
  static const List<Color> veloTexto = [
    Color(0x00050A06),
    Color(0x99050A06),
    Color(0xCC050A06),
  ];
}
