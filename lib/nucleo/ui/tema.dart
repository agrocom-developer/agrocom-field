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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
    );
  }

  /// Estilo "filled" de M3 para todos los campos de formulario — mismo
  /// radio redondeado en los cuatro flancos que el pill de los botones, en
  /// vez del subrayado M2 por defecto que quedaba inconsistente con ellos.
  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: borde,
      enabledBorder: borde,
      disabledBorder: borde,
      focusedBorder: borde.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: borde.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      focusedErrorBorder: borde.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
