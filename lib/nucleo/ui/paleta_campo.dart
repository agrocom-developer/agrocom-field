import 'package:flutter/material.dart';

import 'colores_campo.dart';

/// Los tres modos visuales del marketplace. El flavor decide el modo por
/// defecto (cliente: claro u oscuro según el sistema; piloto:
/// [campo], alto contraste para sol directo), pero cualquier modo es válido
/// en cualquier flavor.
enum ModoVisualCampo { claro, oscuro, campo }

/// Paleta semántica del sistema visual (docs/diseno/sistema-visual.md).
///
/// Cada rol existe en los tres modos y cumple WCAG 2.2 AA como mínimo
/// (verificado en `test/nucleo/ui/paleta_campo_test.dart`). Las pantallas
/// nuevas leen roles (`context.paleta.texto`), nunca valores hexadecimales.
@immutable
class PaletaCampo extends ThemeExtension<PaletaCampo> {
  const PaletaCampo({
    required this.brillo,
    required this.fondo,
    required this.superficie,
    required this.superficieElevada,
    required this.borde,
    required this.bordeFuerte,
    required this.texto,
    required this.textoSecundario,
    required this.acento,
    required this.apoyo,
    required this.sobreAcento,
    required this.acentoTexto,
    required this.exito,
    required this.alerta,
    required this.error,
    required this.info,
  });

  final Brightness brillo;

  /// Fondo de pantalla.
  final Color fondo;

  /// Tarjetas y hojas sobre el fondo.
  final Color superficie;

  /// Superficie de un nivel por encima (modal, oferta entrante, menú).
  final Color superficieElevada;

  /// Divisores y bordes decorativos (no portan información por sí solos).
  final Color borde;

  /// Borde de campos y controles: contraste >= 3:1 contra el fondo.
  final Color bordeFuerte;

  final Color texto;

  /// Texto de apoyo; contraste >= 4.5:1 en su superficie.
  final Color textoSecundario;

  /// Relleno de la acción principal (verde hoja de marca).
  final Color acento;

  /// Verde pasto de apoyo: relleno de íconos, marcadores y gráficos (no
  /// texto); contraste >= 3:1 contra fondo y superficie.
  final Color apoyo;

  /// Texto e íconos sobre [acento].
  final Color sobreAcento;

  /// El acento usado como color de texto o ícono sobre [fondo] (en claro es
  /// el verde hoja; en oscuro y campo, el mismo relleno claro).
  final Color acentoTexto;

  final Color exito;
  final Color alerta;
  final Color error;
  final Color info;

  static const PaletaCampo claro = PaletaCampo(
    brillo: Brightness.light,
    fondo: Color(0xFFF6F2E4),
    superficie: Color(0xFFFFFDF7),
    superficieElevada: Color(0xFFFFFDF7),
    borde: Color(0xFFD9D3BC),
    bordeFuerte: Color(0xFF7A7F68),
    texto: Color(0xFF15210F),
    textoSecundario: Color(0xFF4A5240),
    acento: ColoresCampo.verdeHoja,
    apoyo: ColoresCampo.verdePasto,
    sobreAcento: Color(0xFFFFFFFF),
    acentoTexto: ColoresCampo.verdeHoja,
    exito: ColoresCampo.verdeHoja,
    alerta: Color(0xFF8A5300),
    error: Color(0xFFB42318),
    info: Color(0xFF0B5E8A),
  );

  static const PaletaCampo oscuro = PaletaCampo(
    brillo: Brightness.dark,
    fondo: Color(0xFF0A110B),
    superficie: Color(0xFF111B13),
    superficieElevada: Color(0xFF19261B),
    borde: Color(0xFF2A3A2D),
    bordeFuerte: Color(0xFF7F9186),
    texto: Color(0xFFEEF5EA),
    textoSecundario: Color(0xFFA9B8A5),
    acento: ColoresCampo.acentoHojaOscuro,
    apoyo: ColoresCampo.verdePasto,
    sobreAcento: Color(0xFF0A110B),
    acentoTexto: ColoresCampo.acentoHojaOscuro,
    exito: ColoresCampo.acentoHojaOscuro,
    alerta: Color(0xFFFBBF24),
    error: Color(0xFFFF8A80),
    info: Color(0xFF7DD3FC),
  );

  /// Modo campo: la paleta de alto contraste de ADR 0008 (sol directo,
  /// guantes). Es la misma que usan los widgets del catálogo `*Campo`.
  static const PaletaCampo campo = PaletaCampo(
    brillo: Brightness.dark,
    fondo: ColoresCampo.fondoProfundo,
    superficie: ColoresCampo.superficie,
    superficieElevada: Color(0xFF12220F),
    borde: Color(0xFF22362A),
    bordeFuerte: Color(0xFF8FA68F),
    texto: ColoresCampo.textoPrincipal,
    textoSecundario: Color(0xFFC9D8CD),
    acento: ColoresCampo.acentoHoja,
    apoyo: ColoresCampo.verdePasto,
    sobreAcento: ColoresCampo.fondoProfundo,
    acentoTexto: ColoresCampo.acentoHoja,
    exito: ColoresCampo.acentoHoja,
    alerta: ColoresCampo.acentoAmbarTexto,
    error: Color(0xFFFF9A92),
    info: Color(0xFF7DD3FC),
  );

  static PaletaCampo deModo(ModoVisualCampo modo) => switch (modo) {
    ModoVisualCampo.claro => claro,
    ModoVisualCampo.oscuro => oscuro,
    ModoVisualCampo.campo => campo,
  };

  @override
  PaletaCampo copyWith({
    Brightness? brillo,
    Color? fondo,
    Color? superficie,
    Color? superficieElevada,
    Color? borde,
    Color? bordeFuerte,
    Color? texto,
    Color? textoSecundario,
    Color? acento,
    Color? apoyo,
    Color? sobreAcento,
    Color? acentoTexto,
    Color? exito,
    Color? alerta,
    Color? error,
    Color? info,
  }) {
    return PaletaCampo(
      brillo: brillo ?? this.brillo,
      fondo: fondo ?? this.fondo,
      superficie: superficie ?? this.superficie,
      superficieElevada: superficieElevada ?? this.superficieElevada,
      borde: borde ?? this.borde,
      bordeFuerte: bordeFuerte ?? this.bordeFuerte,
      texto: texto ?? this.texto,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      acento: acento ?? this.acento,
      apoyo: apoyo ?? this.apoyo,
      sobreAcento: sobreAcento ?? this.sobreAcento,
      acentoTexto: acentoTexto ?? this.acentoTexto,
      exito: exito ?? this.exito,
      alerta: alerta ?? this.alerta,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  PaletaCampo lerp(ThemeExtension<PaletaCampo>? other, double t) {
    if (other is! PaletaCampo) return this;
    Color mezcla(Color a, Color b) => Color.lerp(a, b, t)!;
    return PaletaCampo(
      brillo: t < 0.5 ? brillo : other.brillo,
      fondo: mezcla(fondo, other.fondo),
      superficie: mezcla(superficie, other.superficie),
      superficieElevada: mezcla(superficieElevada, other.superficieElevada),
      borde: mezcla(borde, other.borde),
      bordeFuerte: mezcla(bordeFuerte, other.bordeFuerte),
      texto: mezcla(texto, other.texto),
      textoSecundario: mezcla(textoSecundario, other.textoSecundario),
      acento: mezcla(acento, other.acento),
      apoyo: mezcla(apoyo, other.apoyo),
      sobreAcento: mezcla(sobreAcento, other.sobreAcento),
      acentoTexto: mezcla(acentoTexto, other.acentoTexto),
      exito: mezcla(exito, other.exito),
      alerta: mezcla(alerta, other.alerta),
      error: mezcla(error, other.error),
      info: mezcla(info, other.info),
    );
  }
}

/// Acceso corto a la paleta del tema activo. Sin la extensión en el tema
/// (un `MaterialApp` pelado en un test) cae en la paleta de modo campo.
extension PaletaContextoCampo on BuildContext {
  PaletaCampo get paleta =>
      Theme.of(this).extension<PaletaCampo>() ?? PaletaCampo.campo;
}
