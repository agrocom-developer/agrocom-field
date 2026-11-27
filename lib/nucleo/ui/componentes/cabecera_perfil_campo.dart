import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colores_campo.dart';
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
    this.imagen,
    this.alineacionImagen = Alignment.center,
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

  /// Foto de fondo (ruta del asset). Se pinta bajo un velo verde que es
  /// traslúcido arriba y se vuelve el verde sólido de la cabecera abajo, donde
  /// están el nombre y las estrellas, para que el texto conserve su contraste.
  final String? imagen;

  /// Qué parte de la foto queda visible al recortarla para llenar la banda.
  final AlignmentGeometry alineacionImagen;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final forma = const BorderRadius.vertical(
      bottom: Radius.circular(RadioCampo.tarjeta),
    );
    final contenido = Padding(
      // El alto de la barra de estado se suma arriba: la foto pasa por debajo
      // de la hora y la batería en vez de dejar una franja.
      padding: EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        EspaciadoCampo.s + MediaQuery.paddingOf(context).top,
        EspaciadoCampo.l,
        EspaciadoCampo.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fila superior: la insignia a la izquierda, el menú a la derecha.
          // Alto fijo para que el centrado de abajo no dependa de ninguno.
          SizedBox(
            height: ObjetivoTactilCampo.minimo,
            child: Stack(
              children: [
                // Cada extremo se ancla a su lado con el mismo margen: la
                // insignia al borde izquierdo y el ícono del menú al derecho.
                if (insignia case final i?)
                  Align(alignment: AlignmentDirectional.centerStart, child: i),
                if (accion case final a?)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    // El botón mide 48 y su ícono 28: se corre la mitad de lo
                    // que sobra (10) para que el ícono quede al ras del margen.
                    child: Transform.translate(
                      offset: const Offset(10, 0),
                      child: a,
                    ),
                  ),
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
    // Íconos claros de la barra de estado sobre la banda verde.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: paleta.cabecera, borderRadius: forma),
        child: ClipRRect(
          borderRadius: forma,
          child: Stack(
            children: [
              if (imagen != null) ...[
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: Image.asset(
                      imagen!,
                      fit: BoxFit.cover,
                      alignment: alineacionImagen,
                      cacheWidth: 1000,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          paleta.cabecera.withValues(alpha: 0.16),
                          paleta.cabecera.withValues(alpha: 0.5),
                          paleta.cabecera.withValues(alpha: 0.93),
                          paleta.cabecera,
                        ],
                        stops: const [0, 0.38, 0.62, 0.8],
                      ),
                    ),
                  ),
                ),
              ],
              contenido,
            ],
          ),
        ),
      ),
    );
  }
}

/// Píldora compacta de la cabecera: ícono y texto sobre un fondo claro
/// translúcido oscuro, que conserva el contraste sobre la foto (p. ej.
/// «Aprobado»).
class InsigniaCabeceraCampo extends StatelessWidget {
  const InsigniaCabeceraCampo({
    required this.icono,
    required this.etiqueta,
    this.etiquetaSemantica,
    this.intensa = false,
    super.key,
  });

  /// Relleno sólido contrastado para «Aprobado»: verde petróleo con letras
  /// blancas en el claro, verde suave cielo con letras negras en el oscuro.
  final bool intensa;

  final IconData icono;
  final String etiqueta;

  /// Lo que anuncia el lector de pantalla; por defecto, [etiqueta].
  final String? etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final fondo = intensa
        ? (paleta.brillo == Brightness.dark
              ? ColoresCampo.insigniaAprobadoOscuro
              : ColoresCampo.insigniaAprobadoClaro)
        : paleta.cabecera.withValues(alpha: 0.7);
    final texto = intensa
        ? (paleta.brillo == Brightness.dark
              ? ColoresCampo.sobreInsigniaAprobadoOscuro
              : ColoresCampo.sobreInsigniaAprobadoClaro)
        : paleta.sobreCabecera;
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
          color: fondo,
          borderRadius: BorderRadius.circular(RadioCampo.capsula),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icono, size: 18, color: texto),
            const SizedBox(width: EspaciadoCampo.xs),
            Flexible(
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Interlineado repartido por igual arriba y abajo: sin esto
                // la fuente deja el texto más bajo que el centro del ícono.
                textHeightBehavior: const TextHeightBehavior(
                  leadingDistribution: TextLeadingDistribution.even,
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: texto,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
