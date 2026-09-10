import 'package:flutter/material.dart';

/// Constantes de color derivadas del logo de Agrocom SRL.
///
/// El logo contiene un triángulo en degradado verde y un ícono de señal
/// en naranja. Los colores aquí reflejan esa identidad visual.
abstract final class ColoresAgrocom {
  // Verde primario y variantes
  /// Verde claro del degradado del triángulo del logo.
  static const Color verdeClaro = Color(0xFF8BC34A);

  /// Verde primario (seed para Material 3).
  /// Usado como base de la paleta de Material 3 y color primario de marca.
  static const Color verde = Color(0xFF2E7D32);

  /// Verde oscuro del degradado del triángulo del logo.
  static const Color verdeOscuro = Color(0xFF1B5E20);

  // Naranja secundario y variantes
  /// Naranja claro derivado del ícono de señal del logo.
  static const Color naranjaClaro = Color(0xFFFFB74D);

  /// Naranja primario del ícono de señal del logo.
  /// Usado como color secundario de Material 3.
  static const Color naranja = Color(0xFFF57C00);

  /// Naranja oscuro derivado del ícono de señal del logo.
  static const Color naranjaOscuro = Color(0xFFE65100);
}
