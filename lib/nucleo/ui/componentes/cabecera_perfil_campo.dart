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
    super.key,
  });

  final Widget avatar;
  final String nombre;

  /// Rol, empresa o calificación; una sola línea de apoyo.
  final String? detalle;

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
        color: paleta.acento,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(RadioCampo.tarjeta),
        ),
      ),
      child: Column(
        children: [
          avatar,
          const SizedBox(height: EspaciadoCampo.m),
          Semantics(
            header: true,
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              style: texto.headlineSmall?.copyWith(color: paleta.sobreAcento),
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              detalle!,
              textAlign: TextAlign.center,
              style: texto.bodyMedium?.copyWith(
                color: paleta.sobreAcento.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
