import 'package:flutter/material.dart';

import 'colores_campo.dart';

/// Radios y familia monoespaciada del modo "campo" (ADR 0008), como
/// `ThemeExtension` — así un widget del catálogo puede leerlos de
/// `Theme.of(context)` en vez de repetir números sueltos, y una pantalla
/// puede en el futuro ajustar la extensión sin tocar cada widget.
@immutable
class TemaCampo extends ThemeExtension<TemaCampo> {
  const TemaCampo({
    this.radioPill = 999,
    this.radioTarjetaGrande = 24,
    this.radioTarjetaChica = 18,
    this.radioBadge = 8,
    this.familiaMonoespaciada = 'monospace',
  });

  final double radioPill;
  final double radioTarjetaGrande;
  final double radioTarjetaChica;
  final double radioBadge;

  /// Familia monoespaciada del SO (sin paquete de fuente propio — ver ADR
  /// 0008, mismo motivo de costo en el RC que ya fijó ADR 0003) para datos
  /// técnicos: labels, badges, timestamps, notas de estado de sync.
  final String familiaMonoespaciada;

  @override
  TemaCampo copyWith({
    double? radioPill,
    double? radioTarjetaGrande,
    double? radioTarjetaChica,
    double? radioBadge,
    String? familiaMonoespaciada,
  }) {
    return TemaCampo(
      radioPill: radioPill ?? this.radioPill,
      radioTarjetaGrande: radioTarjetaGrande ?? this.radioTarjetaGrande,
      radioTarjetaChica: radioTarjetaChica ?? this.radioTarjetaChica,
      radioBadge: radioBadge ?? this.radioBadge,
      familiaMonoespaciada: familiaMonoespaciada ?? this.familiaMonoespaciada,
    );
  }

  @override
  TemaCampo lerp(ThemeExtension<TemaCampo>? other, double t) {
    // Tokens discretos (radios/nombre de fuente), no hay nada que
    // interpolar entre dos temas "campo" — mismo criterio que
    // `CardThemeData` de Material cuando no anima geometría.
    if (other is! TemaCampo) return this;
    return t < 0.5 ? this : other;
  }
}

/// Construye el `ThemeData` completo del modo "campo" — una pantalla lo
/// adopta envolviéndose en `Theme(data: AgrocomTheme.campo(), child: ...)`.
abstract final class AgrocomThemeCampo {
  static ThemeData construir() {
    const temaCampo = TemaCampo();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColoresCampo.acentoLima,
      brightness: Brightness.dark,
      surface: ColoresCampo.fondoProfundo,
      onSurface: ColoresCampo.textoPrincipal,
      primary: ColoresCampo.acentoLima,
      onPrimary: ColoresCampo.fondoProfundo,
      error: ColoresCampo.acentoRojo,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ColoresCampo.fondoProfundo,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: const [temaCampo],
    );
  }
}
