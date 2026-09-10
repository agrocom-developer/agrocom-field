import 'package:flutter/material.dart';

import 'colores_agrocom.dart';

/// Temas de Material 3 para Agrocom — claro y oscuro.
///
/// El tema es idéntico para ambos flavors (piloto/auxiliar).
/// Consulta ADR 0003 para la decisión sobre colores y ajustes a campo abierto.
abstract final class AgrocomTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColoresAgrocom.verde,
      brightness: Brightness.light,
      secondary: ColoresAgrocom.naranja,
      onSecondary: Colors.white,
      secondaryContainer: ColoresAgrocom.naranjaClaro,
      onSecondaryContainer: Colors.black87,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size(64, 56)),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColoresAgrocom.verde,
      brightness: Brightness.dark,
      secondary: ColoresAgrocom.naranja,
      onSecondary: Colors.black87,
      secondaryContainer: ColoresAgrocom.naranjaOscuro,
      onSecondaryContainer: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size(64, 56)),
      ),
    );
  }
}
