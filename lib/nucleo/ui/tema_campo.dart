import 'package:flutter/material.dart';

import 'colores_campo.dart';
import 'paleta_campo.dart';
import 'tipografia_campo.dart';
import 'tokens_campo.dart';

/// Radios y familia monoespaciada del modo "campo" (ADR 0008), como
/// `ThemeExtension` — así un widget del catálogo puede leerlos de
/// `Theme.of(context)` en vez de repetir números sueltos, y una pantalla
/// puede en el futuro ajustar la extensión sin tocar cada widget.
@immutable
class TemaCampo extends ThemeExtension<TemaCampo> {
  const TemaCampo({
    this.radioPill = RadioCampo.capsula,
    this.radioTarjetaGrande = RadioCampo.tarjeta,
    this.radioTarjetaChica = RadioCampo.tarjetaCompacta,
    this.radioBadge = 8,
    this.familiaMonoespaciada = 'JetBrains Mono',
  });

  final double radioPill;
  final double radioTarjetaGrande;
  final double radioTarjetaChica;
  final double radioBadge;

  /// JetBrains Mono (ADR 0008, ampliación 14/9/2026 — antes la
  /// monoespaciada nativa del SO, ver `assets/fonts/FUENTES.md`) para datos
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

/// Construye el `ThemeData` del sistema visual (docs/diseno/sistema-visual.md)
/// para uno de los dos [ModoVisualCampo]. Sin argumentos devuelve el modo
/// campo, el tema de `app.dart` y de todo el catálogo `*Campo`.
abstract final class AgrocomThemeCampo {
  static ThemeData construir({ModoVisualCampo modo = ModoVisualCampo.oscuro}) {
    final paleta = PaletaCampo.deModo(modo);
    final guantes = modo == ModoVisualCampo.oscuro;
    final altoBoton = guantes
        ? ObjetivoTactilCampo.guantes
        : ObjetivoTactilCampo.minimo;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: ColoresCampo.verdeHoja,
      brightness: paleta.brillo,
      surface: paleta.fondo,
      onSurface: paleta.texto,
      primary: paleta.acento,
      onPrimary: paleta.sobreAcento,
      error: paleta.error,
      outline: paleta.bordeFuerte,
      outlineVariant: paleta.borde,
      primaryContainer: paleta.acentoContenedor,
      onPrimaryContainer: paleta.sobreAcentoContenedor,
      secondary: paleta.grafito,
      onSecondary: paleta.sobreGrafito,
      tertiary: paleta.ambar,
      onTertiary: paleta.sobreAmbar,
      tertiaryContainer: paleta.ambarContenedor,
      onTertiaryContainer: paleta.sobreAmbarContenedor,
      errorContainer: paleta.errorContenedor,
      onErrorContainer: paleta.sobreErrorContenedor,
      surfaceContainerHighest: paleta.superficie2,
    );

    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RadioCampo.pildora),
    );
    const estiloBoton = TextStyle(
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w700,
      fontSize: 16,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: paleta.brillo,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paleta.fondo,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fontFamily: 'Manrope',
      textTheme: _textTheme(paleta),
      cardTheme: CardThemeData(
        color: paleta.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
          side: BorderSide(color: paleta.borde),
        ),
      ),
      dividerColor: paleta.borde,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: paleta.acento,
          foregroundColor: paleta.sobreAcento,
          minimumSize: Size(64, altoBoton),
          shape: forma,
          textStyle: estiloBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: paleta.texto,
          minimumSize: Size(64, altoBoton),
          side: BorderSide(color: paleta.bordeFuerte),
          shape: forma,
          textStyle: estiloBoton,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paleta.superficie,
        indicatorColor: paleta.acentoContenedor,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? paleta.sobreAcentoContenedor
                : paleta.textoSecundario,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: estados.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: estados.contains(WidgetState.selected)
                ? paleta.texto
                : paleta.textoSecundario,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: paleta.superficie,
        indicatorColor: paleta.acentoContenedor,
        selectedIconTheme: IconThemeData(color: paleta.sobreAcentoContenedor),
        unselectedIconTheme: IconThemeData(color: paleta.textoSecundario),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          color: paleta.texto,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Manrope',
          color: paleta.textoSecundario,
        ),
      ),
      extensions: [const TemaCampo(), paleta],
    );
  }

  /// Escala tipográfica de Material mapeada a [TipografiaCampo]: cada rol de
  /// Material apunta a un estilo con nombre del dominio, con el color de la
  /// paleta del modo.
  static TextTheme _textTheme(PaletaCampo paleta) {
    TextStyle con(TextStyle base, {bool secundario = false}) => base.copyWith(
      color: secundario ? paleta.textoSecundario : paleta.texto,
    );
    return TextTheme(
      displaySmall: con(TipografiaCampo.tituloHero),
      headlineMedium: con(TipografiaCampo.tituloPantalla),
      headlineSmall: con(TipografiaCampo.valorDestacado),
      titleSmall: con(TipografiaCampo.etiqueta, secundario: true),
      titleLarge: con(TipografiaCampo.tituloSeccion),
      titleMedium: con(TipografiaCampo.tituloTarjeta),
      bodyLarge: con(TipografiaCampo.cuerpo.copyWith(fontSize: 16)),
      bodyMedium: con(TipografiaCampo.cuerpoSecundario, secundario: true),
      labelLarge: con(TipografiaCampo.tituloTarjeta.copyWith(fontSize: 16)),
      labelSmall: con(TipografiaCampo.etiquetaMono, secundario: true),
    );
  }
}
