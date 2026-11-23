import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Contraste WCAG 2.x entre dos colores opacos — la fórmula de luminancia
/// relativa del estándar. Sirve a los tests de paleta (`PaletaCampo`) y a
/// quien necesite validar un color nuevo antes de adoptarlo.
abstract final class ContrasteWcag {
  /// Umbral AA para texto normal.
  static const double aaTexto = 4.5;

  /// Umbral AAA para texto normal.
  static const double aaaTexto = 7.0;

  /// Umbral AA para texto grande (>= 24 px, o >= 19 px en negrita) y para
  /// componentes de interfaz y gráficos (bordes de campo, íconos).
  static const double aaComponente = 3.0;

  static double luminancia(Color color) {
    double canal(double valor) => valor <= 0.03928
        ? valor / 12.92
        : math.pow((valor + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * canal(color.r) +
        0.7152 * canal(color.g) +
        0.0722 * canal(color.b);
  }

  static double ratio(Color a, Color b) {
    final la = luminancia(a);
    final lb = luminancia(b);
    final mayor = math.max(la, lb);
    final menor = math.min(la, lb);
    return (mayor + 0.05) / (menor + 0.05);
  }
}
