import 'package:flutter/material.dart';

import 'colores_campo.dart';

/// Los dos modos visuales del marketplace: [claro] (ciudad, el predeterminado
/// de los dos flavors) y [oscuro] (alto contraste AAA sobre verde profundo, no negro puro).
/// Cualquier modo es válido en cualquier flavor y se elige en el perfil.
enum ModoVisualCampo { claro, oscuro }

/// Paleta semántica del sistema visual Industrial AgTech (DESIGN.md y
/// docs/diseno/sistema-visual.md); la fuente de los valores es
/// `docs/diseno/tokens/tokens.json`.
///
/// Cada rol existe en los dos modos y cumple WCAG 2.2 AA como mínimo, AAA en
/// campo (verificado en `test/nucleo/ui/paleta_campo_test.dart`). Las
/// pantallas leen roles (`context.paleta.texto`), nunca valores hexadecimales.
///
/// Los colores de texto semánticos ([alerta], [error], [info]) son las
/// variantes que alcanzan AA sobre el fondo; los rellenos de marca más vivos
/// son [ambar], [rellenoInfo] y [rellenoError].
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
    required this.superficie2,
    required this.acentoContenedor,
    required this.sobreAcentoContenedor,
    required this.acentoHover,
    required this.grafito,
    required this.sobreGrafito,
    required this.ambar,
    required this.sobreAmbar,
    required this.ambarContenedor,
    required this.sobreAmbarContenedor,
    required this.rellenoInfo,
    required this.infoContenedor,
    required this.sobreInfoContenedor,
    required this.rellenoError,
    required this.errorContenedor,
    required this.sobreErrorContenedor,
    required this.papel,
    required this.papel2,
    required this.papelDoblez,
    required this.sobrePapel,
    required this.cabecera,
    required this.sobreCabecera,
  });

  final Brightness brillo;

  /// Es la paleta oscura de alto contraste: objetivos táctiles de 72.
  bool get esCampo => brillo == Brightness.dark;

  /// Fondo de pantalla.
  final Color fondo;

  /// Tarjetas y hojas sobre el fondo.
  final Color superficie;

  /// Superficie de un nivel por encima (modal, oferta entrante, menú).
  final Color superficieElevada;

  /// Divisores y bordes decorativos (no portan información por sí solos).
  final Color borde;

  /// Borde de campos y controles: contraste >= 3:1 contra fondo y superficie.
  final Color bordeFuerte;

  /// Texto principal.
  final Color texto;

  /// Texto de apoyo; contraste >= 4,5:1 sobre fondo, superficie y superficie2.
  final Color textoSecundario;

  /// Relleno de la acción principal (verde agrícola de marca).
  final Color acento;

  /// Relleno de íconos, marcadores y gráficos (no texto); contraste >= 3:1 contra fondo y superficie.
  final Color apoyo;

  /// Texto e íconos sobre [acento].
  final Color sobreAcento;

  /// El acento usado como color de texto o ícono sobre [fondo].
  final Color acentoTexto;

  /// Estado correcto como texto o ícono.
  final Color exito;

  /// Advertencia como texto o ícono.
  final Color alerta;

  /// Error como texto o ícono.
  final Color error;

  /// Información como texto o ícono.
  final Color info;

  /// Superficie de segundo nivel: chips, filtros inactivos y bloques dentro de una tarjeta (`surface2` de tokens.json).
  final Color superficie2;

  /// Fondo tonal del acento (chip de estado correcto, aviso positivo).
  final Color acentoContenedor;

  /// Texto e íconos sobre [acentoContenedor].
  final Color sobreAcentoContenedor;

  /// Acento al presionar.
  final Color acentoHover;

  /// Estructura: cabecera de ticket, filtro activo, FAB secundario.
  final Color grafito;

  /// Texto e íconos sobre [grafito].
  final Color sobreGrafito;

  /// Relleno de lo que pide atención (banner sin señal, turno). No es color de texto: para texto usa [alerta].
  final Color ambar;

  /// Texto e íconos sobre [ambar].
  final Color sobreAmbar;

  /// Fondo tonal de advertencia.
  final Color ambarContenedor;

  /// Texto sobre [ambarContenedor].
  final Color sobreAmbarContenedor;

  /// Relleno informativo (pin, barra). No es color de texto: para texto usa [info].
  final Color rellenoInfo;

  /// Fondo tonal informativo.
  final Color infoContenedor;

  /// Texto sobre [infoContenedor].
  final Color sobreInfoContenedor;

  /// Relleno de error (botón destructivo, pin). No es color de texto: para texto usa [error].
  final Color rellenoError;

  /// Fondo tonal de error.
  final Color errorContenedor;

  /// Texto sobre [errorContenedor].
  final Color sobreErrorContenedor;

  /// Post-it de oferta: inicio del degradado.
  final Color papel;

  /// Post-it de oferta: fin del degradado.
  final Color papel2;

  /// Esquina doblada del post-it.
  final Color papelDoblez;

  /// Texto sobre el post-it.
  final Color sobrePapel;

  /// Banda de cabecera de perfil. En el oscuro es un verde profundo, no el
  /// acento vivo de los botones, que encandila a pantalla completa.
  final Color cabecera;

  /// Texto e íconos sobre [cabecera] (AAA).
  final Color sobreCabecera;

  static const PaletaCampo claro = PaletaCampo(
    brillo: Brightness.light,
    fondo: Color(0xFFF3F5F1),
    superficie: Color(0xFFFFFFFF),
    superficieElevada: Color(0xFFFFFFFF),
    borde: Color(0xFFDDE4DC),
    bordeFuerte: Color(0xFF7A877D),
    texto: Color(0xFF202A2E),
    textoSecundario: Color(0xFF5F6C65),
    acento: ColoresCampo.verdeHoja,
    apoyo: ColoresCampo.verdePasto,
    sobreAcento: Color(0xFFFFFFFF),
    acentoTexto: ColoresCampo.verdeHoja,
    exito: ColoresCampo.verdeHoja,
    alerta: Color(0xFF7A4B00),
    error: Color(0xFFA12727),
    info: Color(0xFF14577F),
    superficie2: Color(0xFFE9EEE7),
    acentoContenedor: Color(0xFFE3F0D8),
    sobreAcentoContenedor: Color(0xFF285A18),
    acentoHover: Color(0xFF2F6B1D),
    grafito: Color(0xFF29343A),
    sobreGrafito: Color(0xFFFFFFFF),
    ambar: Color(0xFFF5A623),
    sobreAmbar: Color(0xFF29343A),
    ambarContenedor: Color(0xFFFDF0D3),
    sobreAmbarContenedor: Color(0xFF7A4B00),
    rellenoInfo: Color(0xFF2785C7),
    infoContenedor: Color(0xFFE2F0FA),
    sobreInfoContenedor: Color(0xFF14577F),
    rellenoError: Color(0xFFDC4545),
    errorContenedor: Color(0xFFFCE6E6),
    sobreErrorContenedor: Color(0xFFA12727),
    papel: Color(0xFFFFE680),
    papel2: Color(0xFFFFDA55),
    papelDoblez: Color(0xFFE8C13E),
    sobrePapel: Color(0xFF29343A),
    cabecera: ColoresCampo.verdeHoja,
    sobreCabecera: Color(0xFFFFFFFF),
  );

  /// Modo oscuro: contraste AAA de texto y acentos (el antiguo «campo», ADR
  /// 0008) sobre un verde profundo en vez de negro puro (el antiguo «oscuro»).
  static const PaletaCampo oscuro = PaletaCampo(
    brillo: Brightness.dark,
    fondo: Color(0xFF0F1A13),
    superficie: Color(0xFF16241B),
    superficieElevada: Color(0xFF1A2A20),
    borde: Color(0xFF34493B),
    bordeFuerte: Color(0xFF6B8272),
    texto: ColoresCampo.textoPrincipal,
    textoSecundario: Color(0xFFD7E2D9),
    acento: ColoresCampo.acentoHoja,
    apoyo: ColoresCampo.acentoHoja,
    sobreAcento: ColoresCampo.fondoProfundo,
    acentoTexto: ColoresCampo.acentoHoja,
    exito: ColoresCampo.acentoHoja,
    alerta: ColoresCampo.acentoAmbar,
    error: ColoresCampo.acentoRojo,
    info: Color(0xFF8CCBF2),
    superficie2: Color(0xFF1A2A20),
    acentoContenedor: Color(0xFF1B3A22),
    sobreAcentoContenedor: Color(0xFFCBF5CB),
    acentoHover: Color(0xFFA8EBA8),
    grafito: Color(0xFF1A2A20),
    sobreGrafito: Color(0xFFFFFFFF),
    ambar: ColoresCampo.acentoAmbar,
    sobreAmbar: Color(0xFF000000),
    ambarContenedor: Color(0xFF3A2C00),
    sobreAmbarContenedor: Color(0xFFFFE3A3),
    rellenoInfo: Color(0xFF8CCBF2),
    infoContenedor: Color(0xFF0E2A3B),
    sobreInfoContenedor: Color(0xFFC6E6FA),
    rellenoError: Color(0xFFFF9494),
    errorContenedor: Color(0xFF3D1214),
    sobreErrorContenedor: Color(0xFFFFC9C9),
    papel: Color(0xFFFFE680),
    papel2: Color(0xFFFFDA55),
    papelDoblez: Color(0xFFE8C13E),
    sobrePapel: Color(0xFF000000),
    cabecera: Color(0xFF24562F),
    sobreCabecera: Color(0xFFFFFFFF),
  );

  /// Fondo tonal y texto de un chip para el rol de color [rol]
  /// ([exito], [acentoTexto], [alerta], [error] o [info]); cualquier otro
  /// rol cae en el chip neutro. Todos los pares cumplen AA.
  ({Color fondo, Color texto}) contenedorDe(Color rol) {
    if (rol == alerta) {
      return (fondo: ambarContenedor, texto: sobreAmbarContenedor);
    }
    if (rol == error) {
      return (fondo: errorContenedor, texto: sobreErrorContenedor);
    }
    if (rol == info) {
      return (fondo: infoContenedor, texto: sobreInfoContenedor);
    }
    if (rol == exito || rol == acentoTexto) {
      return (fondo: acentoContenedor, texto: sobreAcentoContenedor);
    }
    return (fondo: superficie2, texto: textoSecundario);
  }

  static PaletaCampo deModo(ModoVisualCampo modo) => switch (modo) {
    ModoVisualCampo.claro => claro,
    ModoVisualCampo.oscuro => oscuro,
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
    Color? superficie2,
    Color? acentoContenedor,
    Color? sobreAcentoContenedor,
    Color? acentoHover,
    Color? grafito,
    Color? sobreGrafito,
    Color? ambar,
    Color? sobreAmbar,
    Color? ambarContenedor,
    Color? sobreAmbarContenedor,
    Color? rellenoInfo,
    Color? infoContenedor,
    Color? sobreInfoContenedor,
    Color? rellenoError,
    Color? errorContenedor,
    Color? sobreErrorContenedor,
    Color? papel,
    Color? papel2,
    Color? papelDoblez,
    Color? sobrePapel,
    Color? cabecera,
    Color? sobreCabecera,
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
      superficie2: superficie2 ?? this.superficie2,
      acentoContenedor: acentoContenedor ?? this.acentoContenedor,
      sobreAcentoContenedor:
          sobreAcentoContenedor ?? this.sobreAcentoContenedor,
      acentoHover: acentoHover ?? this.acentoHover,
      grafito: grafito ?? this.grafito,
      sobreGrafito: sobreGrafito ?? this.sobreGrafito,
      ambar: ambar ?? this.ambar,
      sobreAmbar: sobreAmbar ?? this.sobreAmbar,
      ambarContenedor: ambarContenedor ?? this.ambarContenedor,
      sobreAmbarContenedor: sobreAmbarContenedor ?? this.sobreAmbarContenedor,
      rellenoInfo: rellenoInfo ?? this.rellenoInfo,
      infoContenedor: infoContenedor ?? this.infoContenedor,
      sobreInfoContenedor: sobreInfoContenedor ?? this.sobreInfoContenedor,
      rellenoError: rellenoError ?? this.rellenoError,
      errorContenedor: errorContenedor ?? this.errorContenedor,
      sobreErrorContenedor: sobreErrorContenedor ?? this.sobreErrorContenedor,
      papel: papel ?? this.papel,
      papel2: papel2 ?? this.papel2,
      papelDoblez: papelDoblez ?? this.papelDoblez,
      sobrePapel: sobrePapel ?? this.sobrePapel,
      cabecera: cabecera ?? this.cabecera,
      sobreCabecera: sobreCabecera ?? this.sobreCabecera,
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
      superficie2: mezcla(superficie2, other.superficie2),
      acentoContenedor: mezcla(acentoContenedor, other.acentoContenedor),
      sobreAcentoContenedor: mezcla(
        sobreAcentoContenedor,
        other.sobreAcentoContenedor,
      ),
      acentoHover: mezcla(acentoHover, other.acentoHover),
      grafito: mezcla(grafito, other.grafito),
      sobreGrafito: mezcla(sobreGrafito, other.sobreGrafito),
      ambar: mezcla(ambar, other.ambar),
      sobreAmbar: mezcla(sobreAmbar, other.sobreAmbar),
      ambarContenedor: mezcla(ambarContenedor, other.ambarContenedor),
      sobreAmbarContenedor: mezcla(
        sobreAmbarContenedor,
        other.sobreAmbarContenedor,
      ),
      rellenoInfo: mezcla(rellenoInfo, other.rellenoInfo),
      infoContenedor: mezcla(infoContenedor, other.infoContenedor),
      sobreInfoContenedor: mezcla(
        sobreInfoContenedor,
        other.sobreInfoContenedor,
      ),
      rellenoError: mezcla(rellenoError, other.rellenoError),
      errorContenedor: mezcla(errorContenedor, other.errorContenedor),
      sobreErrorContenedor: mezcla(
        sobreErrorContenedor,
        other.sobreErrorContenedor,
      ),
      papel: mezcla(papel, other.papel),
      papel2: mezcla(papel2, other.papel2),
      papelDoblez: mezcla(papelDoblez, other.papelDoblez),
      sobrePapel: mezcla(sobrePapel, other.sobrePapel),
      cabecera: mezcla(cabecera, other.cabecera),
      sobreCabecera: mezcla(sobreCabecera, other.sobreCabecera),
    );
  }
}

/// Acceso corto a la paleta del tema activo. Sin la extensión en el tema
/// (un `MaterialApp` pelado en un test) cae en la paleta de modo campo.
extension PaletaContextoCampo on BuildContext {
  PaletaCampo get paleta =>
      Theme.of(this).extension<PaletaCampo>() ?? PaletaCampo.oscuro;
}
