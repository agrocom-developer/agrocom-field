import 'package:flutter/material.dart';

import 'colores_campo.dart';

/// Escala tipográfica del modo "campo" (ADR 0008) — el equivalente de
/// `ColoresCampo`/`OpacidadesCampo` para texto: cada estilo con nombre fija
/// familia, tamaño, peso y opacidad de una vez, para que ninguna pantalla
/// arme su propio `TextStyle(fontFamily: 'monospace', ...)` suelto.
///
/// Dos familias, sin paquete de fuentes (ADR 0008, tipografía): la de
/// plataforma para texto humano y la monoespaciada nativa del SO (misma
/// familia que `TemaCampo.familiaMonoespaciada`) para dato técnico — labels
/// en mayúscula, timestamps, notas de sync. Un uso puntual ajusta con
/// `copyWith` (tamaño, color semántico), nunca reescribe la familia.
abstract final class TipografiaCampo {
  static const String _mono = 'monospace';

  // --- Texto humano (fuente de plataforma) ---

  /// Titular de una pantalla de bienvenida ("El lote no tiene señal.").
  static const TextStyle tituloHero = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 38,
    height: 1.08,
    letterSpacing: -0.5,
    color: ColoresCampo.textoPrincipal,
  );

  /// Título principal de una pantalla ("Vincular dispositivo").
  static const TextStyle tituloPantalla = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1.15,
    letterSpacing: -0.4,
    color: ColoresCampo.textoPrincipal,
  );

  /// Título de sección o de encabezado ("Nueva aplicación", "Hola, Rubén").
  static const TextStyle tituloSeccion = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: ColoresCampo.textoPrincipal,
  );

  /// Dato protagonista dentro de una tarjeta ("Lote 14 — La Nena").
  static const TextStyle valorDestacado = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 1.15,
    letterSpacing: -0.2,
    color: ColoresCampo.textoPrincipal,
  );

  /// Título de una tarjeta o de un ítem de lista ("Mezcla del caldo").
  static const TextStyle tituloTarjeta = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    color: ColoresCampo.textoPrincipal,
  );

  /// Párrafo de lectura (subtítulo de bienvenida, explicación corta).
  static final TextStyle cuerpo = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: ColoresCampo.textoPrincipal.withValues(alpha: OpacidadesCampo.alta),
  );

  /// Texto de apoyo bajo un título ("Soja · Glifosato + 24D · líquido").
  static final TextStyle cuerpoSecundario = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: ColoresCampo.textoPrincipal.withValues(alpha: OpacidadesCampo.media),
  );

  // --- Dato técnico (monoespaciada nativa) ---

  /// Label en mayúscula sobre un valor ("USUARIO", "HECTÁREAS"). Quien lo
  /// usa aplica `toUpperCase()` — el estilo no transforma el texto.
  static final TextStyle etiquetaMono = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: ColoresCampo.textoPrincipal.withValues(
      alpha: OpacidadesCampo.secundaria,
    ),
  );

  /// Dato corto junto a un título (timestamp, subtítulo de encabezado).
  static final TextStyle datoMono = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    color: ColoresCampo.textoPrincipal.withValues(
      alpha: OpacidadesCampo.secundaria,
    ),
  );

  /// Dato mono que pide atención (enlace "3 productos →", acción "VER") —
  /// mismo cuerpo que [datoMono] en semibold; el color lima es el default,
  /// un uso de alerta lo cambia con `copyWith`.
  static const TextStyle datoMonoDestacado = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: ColoresCampo.acentoLima,
  );

  /// Nota de varias líneas en mono, atenuada (estado de sync, aclaración).
  static final TextStyle notaMono = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    height: 1.6,
    color: ColoresCampo.textoPrincipal.withValues(
      alpha: OpacidadesCampo.secundaria,
    ),
  );
}
