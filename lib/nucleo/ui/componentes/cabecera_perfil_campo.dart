import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tokens_campo.dart';

/// Cabecera de perfil: banda verde con esquinas inferiores redondeadas, el
/// avatar, el nombre y las líneas de apoyo, todos centrados en el eje de la
/// pantalla. Arriba van, en una misma fila, la [insignia] (izquierda) y la
/// [accion] (derecha). Es lo único que lleva el verde a todo el ancho; el
/// resto del perfil va sobre el fondo neutro.
class CabeceraPerfilCampo extends StatelessWidget {
  const CabeceraPerfilCampo({
    required this.avatar,
    required this.nombre,
    this.detalle,
    this.extra,
    this.accion,
    this.insignia,
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

  /// Insignia de la esquina superior izquierda (p. ej. «Aprobado»).
  final Widget? insignia;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        EspaciadoCampo.s,
        EspaciadoCampo.l,
        EspaciadoCampo.xl,
      ),
      decoration: BoxDecoration(
        color: paleta.cabecera,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(RadioCampo.tarjeta),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila superior: la insignia a la izquierda, el menú a la derecha.
          // Alto fijo para que el centrado de abajo no dependa de ninguno.
          SizedBox(
            height: ObjetivoTactilCampo.minimo,
            child: Row(
              children: [
                if (insignia case final i?) Flexible(child: i),
                const Spacer(),
                ?accion,
              ],
            ),
          ),
          Center(child: avatar),
          const SizedBox(height: EspaciadoCampo.m),
          Semantics(
            header: true,
            child: Text(
              nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: texto.headlineSmall?.copyWith(color: paleta.sobreCabecera),
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              detalle!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: texto.bodyMedium?.copyWith(
                color: paleta.sobreCabecera.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (extra != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Center(child: extra!),
          ],
        ],
      ),
    );
  }
}

/// Píldora compacta de la cabecera: ícono y texto sobre un fondo claro
/// translúcido (p. ej. «Aprobado»).
class InsigniaCabeceraCampo extends StatelessWidget {
  const InsigniaCabeceraCampo({
    required this.icono,
    required this.etiqueta,
    this.etiquetaSemantica,
    super.key,
  });

  final IconData icono;
  final String etiqueta;

  /// Lo que anuncia el lector de pantalla; por defecto, [etiqueta].
  final String? etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      container: true,
      label: etiquetaSemantica ?? etiqueta,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EspaciadoCampo.m,
          vertical: EspaciadoCampo.xs + 2,
        ),
        decoration: BoxDecoration(
          color: paleta.sobreCabecera.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(RadioCampo.capsula),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 18, color: paleta.sobreCabecera),
            const SizedBox(width: EspaciadoCampo.xs),
            Flexible(
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: paleta.sobreCabecera,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
