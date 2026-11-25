import 'package:flutter/material.dart';

/// Colores base del sistema visual Industrial AgTech (DESIGN.md): verde agrícola y verde pasto de marca, y la
/// paleta de alto contraste del modo "campo" (ADR 0008), pensada para uso a
/// sol fuerte y con guantes. El tema que la aplica es
/// `AgrocomThemeCampo.construir()`.
///
/// [textoPrincipal] nunca cambia de tono para expresar jerarquía — eso lo
/// resuelve la opacidad (ver [OpacidadesCampo]), igual que el mockup de origen.
abstract final class ColoresCampo {
  /// Verde agrícola: primario de marca en modo claro.
  static const Color verdeHoja = Color(0xFF347A36);

  /// Verde pasto: apoyo de marca (relleno de íconos y gráficos, no texto).
  static const Color verdePasto = Color(0xFF4C8C3A);

  /// Verde hoja claro: primario del modo oscuro.
  static const Color acentoHojaOscuro = Color(0xFF62B66A);

  /// Verde del modo oscuro usado como texto o ícono: AA también sobre la
  /// superficie elevada (4,54:1), donde el relleno [acentoHojaOscuro] no llega.
  static const Color acentoTextoOscuro = Color(0xFF6BBE73);

  static const Color fondoProfundo = Color(0xFF000000);
  static const Color superficie = Color(0xFF0F1A13);

  /// Sombra de marcadores y botones sobre el mapa.
  static const Color sombraMapa = Color(0x55000000);

  /// Sombra proyectada del logo.
  static const Color sombraLogo = Color(0x8C000000);

  /// Sombra de una pastilla de precio sobre el mapa.
  static const Color sombraPastilla = Color(0x44000000);

  /// Fondo de la atribución legal del mapa.
  static const Color atribucionMapa = Color(0xCCFFFFFF);

  /// Fondo del visor de fotos a pantalla completa.
  static const Color visorFoto = Color(0xFF000000);

  /// Fondo del mapa sin teselas.
  static const Color mapaVacioClaro = Color(0xFFE9EEE7);
  static const Color mapaVacioOscuro = Color(0xFF17251C);

  static const Color textoPrincipal = Color(0xFFFFFFFF);

  /// CTA, éxito, dato positivo, registro ya sincronizado (modo campo).
  static const Color acentoHoja = Color(0xFF8EE08F);

  /// Fondo/borde de alerta y estado pendiente — nunca como color de texto
  /// (para eso, [acentoAmbarTexto], con mejor contraste sobre
  /// [fondoProfundo]).
  static const Color acentoAmbar = Color(0xFFFFC547);
  static const Color acentoAmbarTexto = Color(0xFFFFE3A3);

  /// Error / reintento. 9,92:1 sobre [fondoProfundo], 7,09:1 sobre la superficie 2 (AAA).
  static const Color acentoRojo = Color(0xFFFF9494);
}

/// Escala fija de opacidad para [ColoresCampo.textoPrincipal] — reproduce la
/// jerarquía tipográfica por opacidad del mockup de origen, para que
/// ninguna pantalla invente su propio valor suelto.
abstract final class OpacidadesCampo {
  static const double atenuada = 0.48;
  static const double secundaria = 0.55;
  static const double media = 0.62;
  static const double alta = 0.7;
  static const double casiPlena = 0.8;
  static const double plena = 1.0;
}
