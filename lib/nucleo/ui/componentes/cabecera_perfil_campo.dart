import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Cabecera de perfil: banda verde con esquinas inferiores redondeadas, el
/// avatar centrado, el nombre y una línea de apoyo. Es lo único que lleva el
/// verde a todo el ancho de la pantalla; el resto del perfil va sobre el
/// fondo neutro.
class CabeceraPerfilCampo extends StatelessWidget {
  const CabeceraPerfilCampo({
    required this.avatar,
    required this.nombre,
    this.detalle,
    this.extra,
    this.accion,
    super.key,
  });

  final Widget avatar;
  final String nombre;

  /// Rol, empresa o calificación; una sola línea de apoyo.
  final String? detalle;

  /// Línea opcional bajo el detalle (calificación).
  final Widget? extra;

  /// Acción de la esquina superior derecha, normalmente [MenuPerfilCampo].
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        EspaciadoCampo.xl,
        EspaciadoCampo.l,
        EspaciadoCampo.xl,
      ),
      decoration: BoxDecoration(
        color: paleta.cabecera,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(RadioCampo.tarjeta),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              avatar,
              const SizedBox(height: EspaciadoCampo.m),
              Semantics(
                header: true,
                child: Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: texto.headlineSmall?.copyWith(
                    color: paleta.sobreCabecera,
                  ),
                ),
              ),
              if (detalle != null) ...[
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  detalle!,
                  textAlign: TextAlign.center,
                  style: texto.bodyMedium?.copyWith(
                    color: paleta.sobreCabecera.withValues(alpha: 0.85),
                  ),
                ),
              ],
              if (extra != null) ...[
                const SizedBox(height: EspaciadoCampo.s),
                extra!,
              ],
            ],
          ),
          if (accion != null)
            Positioned(
              top: -EspaciadoCampo.m,
              right: -EspaciadoCampo.s,
              child: accion!,
            ),
        ],
      ),
    );
  }
}
