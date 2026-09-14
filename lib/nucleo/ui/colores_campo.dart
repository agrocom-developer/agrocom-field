import 'package:flutter/material.dart';

/// Paleta de alto contraste del modo "campo" (ADR 0008) — pensada para uso a
/// sol fuerte y con guantes, más extrema que `ColoresAgrocom`/`AgrocomTheme`
/// (ADR 0003). No reemplaza esos colores: conviven, y una pantalla adopta
/// este modo a propósito envolviéndose en `AgrocomTheme.campo()`.
///
/// [textoPrincipal] nunca cambia de tono para expresar jerarquía — eso lo
/// resuelve la opacidad (ver [Opacidades]), igual que el mockup de origen.
abstract final class ColoresCampo {
  static const Color fondoProfundo = Color(0xFF07110A);
  static const Color superficie = Color(0xFF0A1A0E);

  static const Color textoPrincipal = Color(0xFFF0FDF4);

  /// CTA, éxito, dato positivo, registro ya sincronizado.
  static const Color acentoLima = Color(0xFFA3E635);

  /// Fondo/borde de alerta y estado pendiente — nunca como color de texto
  /// (para eso, [acentoAmbarTexto], con mejor contraste sobre
  /// [fondoProfundo]).
  static const Color acentoAmbar = Color(0xFFFBBF24);
  static const Color acentoAmbarTexto = Color(0xFFFDE68A);

  /// Error / reintento. 6.94:1 sobre [fondoProfundo] — AA, no AAA en texto
  /// corrido (ver ADR 0008): reservado a usos puntuales (badge, ícono),
  /// nunca un párrafo largo.
  static const Color acentoRojo = Color(0xFFF87171);
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
