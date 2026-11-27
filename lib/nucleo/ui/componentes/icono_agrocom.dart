import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/app_localizations.dart';

/// Tamaños de un [IconoAgrocom] — mismos nombres de escala que el resto del
/// catálogo (`EspaciadoCampo`, `RadioCampo`); 24 es el tamaño por defecto de
/// `Icon` en el sistema visual (sistema-visual.md §6).
abstract final class TamanoIconoCampo {
  /// Junto a un texto pequeño (chip, fila de lista compacta).
  static const double chico = 18;

  /// El mismo tamaño que un `Icon` de Material en el catálogo.
  static const double estandar = 24;

  /// Encabezado de tarjeta, selector de modelo de dron.
  static const double grande = 32;

  /// Vitrina, estado vacío, elección de modelo a pantalla completa.
  static const double destacado = 48;
}

/// Catálogo de íconos dedicados del dominio (ADR 0027) — todo lo que
/// Material no cubre: los modelos de dron de la flota, el equipo en tierra y
/// las medidas propias del marketplace. Siluetas genéricas dibujadas a mano
/// para este repo, en `assets/iconos/`, sin copiar material de un tercero.
enum IconoAgrocomId {
  dronT10('assets/iconos/dron_t10.svg'),
  dronT20('assets/iconos/dron_t20.svg'),
  dronT25('assets/iconos/dron_t25.svg'),
  dronT30('assets/iconos/dron_t30.svg'),
  dronT40('assets/iconos/dron_t40.svg'),
  dronT50('assets/iconos/dron_t50.svg'),
  pulverizadorTanque('assets/iconos/pulverizador_tanque.svg'),
  lote('assets/iconos/lote.svg'),
  cultivo('assets/iconos/cultivo.svg'),
  bateria('assets/iconos/bateria.svg'),
  mandoRc('assets/iconos/mando_rc.svg'),
  hectarea('assets/iconos/hectarea.svg'),
  checkEquipo('assets/iconos/check_equipo.svg');

  const IconoAgrocomId(this.asset);

  /// Ruta del SVG en `assets/iconos/`.
  final String asset;

  /// Texto accesible por defecto si la pantalla no da uno propio con
  /// [IconoAgrocom.semanticLabel] — uno por `l10n`, nunca un string suelto
  /// (ADR 0022).
  String etiquetaPorDefecto(AppLocalizations l10n) => switch (this) {
    dronT10 => l10n.iconoDronT10,
    dronT20 => l10n.iconoDronT20,
    dronT25 => l10n.iconoDronT25,
    dronT30 => l10n.iconoDronT30,
    dronT40 => l10n.iconoDronT40,
    dronT50 => l10n.iconoDronT50,
    pulverizadorTanque => l10n.iconoPulverizadorTanque,
    lote => l10n.iconoLote,
    cultivo => l10n.iconoCultivo,
    bateria => l10n.iconoBateria,
    mandoRc => l10n.iconoMandoRc,
    hectarea => l10n.iconoHectarea,
    checkEquipo => l10n.iconoCheckEquipo,
  };

  /// El ícono del modelo cuyo código ("T10", "T20"…) aparece en [modelo]
  /// (p. ej. "DJI Agras T30"). Sin coincidencia, cae en el T30 (el modelo
  /// más común de la flota) para no dejar la fila sin ícono.
  static IconoAgrocomId deModeloDron(String modelo) {
    final clave = modelo.trim().toUpperCase();
    for (final id in [dronT10, dronT20, dronT25, dronT30, dronT40, dronT50]) {
      if (clave.contains(id.name.substring(4))) return id;
    }
    return dronT30;
  }
}

/// Ícono dedicado del dominio — misma API que un `Icon` de Material
/// (`semanticLabel`, `color`, tamaño), para que una pantalla no distinga en
/// el código si el ícono es de Material o de este catálogo.
///
/// El SVG se dibuja en un solo color; [color] lo retiñe entero con
/// `ColorFilter` (`BlendMode.srcIn`), igual que un `Icon` normal — nunca
/// hace falta declarar un segundo color dentro del archivo.
class IconoAgrocom extends StatelessWidget {
  const IconoAgrocom(
    this.id, {
    this.tamano = TamanoIconoCampo.estandar,
    this.color,
    this.semanticLabel,
    this.excluirSemantica = false,
    super.key,
  });

  final IconoAgrocomId id;
  final double tamano;
  final Color? color;

  /// Si es `null`, se usa [IconoAgrocomId.etiquetaPorDefecto].
  final String? semanticLabel;

  /// En `true` cuando el texto de alrededor ya describe el ícono (evita que
  /// un lector de pantalla lo anuncie dos veces).
  final bool excluirSemantica;

  @override
  Widget build(BuildContext context) {
    final tinte =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: excluirSemantica
          ? null
          : (semanticLabel ?? id.etiquetaPorDefecto(l10n)),
      excludeSemantics: true,
      child: SvgPicture.asset(
        id.asset,
        width: tamano,
        height: tamano,
        colorFilter: ColorFilter.mode(tinte, BlendMode.srcIn),
      ),
    );
  }
}
