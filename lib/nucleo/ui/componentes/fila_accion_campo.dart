import 'package:flutter/material.dart';

import '../../marketplace/ui/superficie_marketplace.dart';
import '../paleta_campo.dart';
import '../tokens_campo.dart';
import 'icono_burbuja_campo.dart';

/// Fila de acción del perfil: burbuja ámbar con el ícono, título, detalle y
/// al final un [trailing] (p. ej. [PildoraContadorCampo]) o el chevron. Es
/// una tarjeta propia; en las pantallas de ajustes se usa [FilaAjusteCampo].
class FilaAccionCampo extends StatelessWidget {
  const FilaAccionCampo({
    required this.icono,
    required this.titulo,
    required this.alToque,
    this.detalle,
    this.trailing,
    this.clave,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback alToque;
  final Widget? trailing;

  /// Llave de la tarjeta (para pruebas).
  final Key? clave;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Semantics(
      button: true,
      onTap: alToque,
      label: detalle == null ? titulo : '$titulo. $detalle',
      excludeSemantics: true,
      child: SuperficieMarketplace(
        key: clave,
        onTap: alToque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.guantes - EspaciadoCampo.xxl,
          ),
          child: Row(
            children: [
              IconoBurbujaCampo(icono),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: texto.titleMedium),
                    if (detalle != null)
                      Text(
                        detalle!,
                        style: texto.bodyMedium?.copyWith(
                          color: paleta.textoSecundario,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: EspaciadoCampo.s),
              ],
              Icon(Icons.chevron_right_rounded, color: paleta.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de pantalla de ajustes: ícono verde sin relleno, título, detalle y
/// chevron (o [trailing], p. ej. un interruptor). No lleva tarjeta: va
/// dentro de un grupo con divisores finos.
class FilaAjusteCampo extends StatelessWidget {
  const FilaAjusteCampo({
    required this.icono,
    required this.titulo,
    required this.alToque,
    this.detalle,
    this.trailing,
    this.clave,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;
  final VoidCallback alToque;

  /// Reemplaza al chevron.
  final Widget? trailing;
  final Key? clave;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Semantics(
      button: true,
      onTap: alToque,
      label: detalle == null ? titulo : '$titulo. $detalle',
      excludeSemantics: true,
      child: InkWell(
        key: clave,
        onTap: alToque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.guantes,
          ),
          child: Padding(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            child: Row(
              children: [
                Icon(icono, color: paleta.acentoTexto),
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: texto.titleMedium),
                      if (detalle != null)
                        Text(
                          detalle!,
                          style: texto.bodyMedium?.copyWith(
                            color: paleta.textoSecundario,
                          ),
                        ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: paleta.textoSecundario,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastilla roja con un número (p. ej. cuántos drones). Fondo [PaletaCampo.error]
/// y texto del color del fondo de pantalla: cumple AA en claro y en oscuro.
class PildoraContadorCampo extends StatelessWidget {
  const PildoraContadorCampo(this.cantidad, {super.key});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.s),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: paleta.error,
        borderRadius: BorderRadius.circular(RadioCampo.capsula),
      ),
      child: Text(
        '$cantidad',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: paleta.fondo,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
