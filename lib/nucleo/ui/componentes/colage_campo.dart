import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import '../../../l10n/app_localizations.dart';

/// Foto de un collage: recorta con el radio dado y deja pintar [child] encima
/// (pastillas de precio, etiquetas). La foto es decorativa y no entra en la
/// semántica.
class FotoColageCampo extends StatelessWidget {
  const FotoColageCampo({
    required this.imagen,
    this.child,
    this.alineacion = Alignment.center,
    this.radio = RadioCampo.tarjetaCompacta,
    super.key,
  });

  /// Ruta del asset (ver `ImagenesCampo`).
  final String imagen;
  final Widget? child;
  final Alignment alineacion;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagen,
            fit: BoxFit.cover,
            alignment: alineacion,
            excludeFromSemantics: true,
          ),
          ?child,
        ],
      ),
    );
  }
}

/// Bloque ámbar del collage: una cifra mono grande y su etiqueta
/// («120 hectáreas publicadas»). La cifra se reduce si no cabe, nunca se
/// corta.
class BloqueAmbarCampo extends StatelessWidget {
  const BloqueAmbarCampo({
    required this.titulo,
    required this.etiqueta,
    this.cifra = true,
    this.radio = RadioCampo.tarjetaCompacta,
    super.key,
  });

  /// La cifra («120») o, con [cifra] en falso, un título de marca.
  final String titulo;
  final String etiqueta;
  final bool cifra;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final estilo = cifra
        ? TipografiaCampo.cifraDisplay
        : TipografiaCampo.valorDestacado;
    return Semantics(
      container: true,
      label: '$titulo $etiqueta',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paleta.ambar,
          borderRadius: BorderRadius.circular(radio),
        ),
        child: Padding(
          padding: const EdgeInsets.all(EspaciadoCampo.m),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: estilo.copyWith(color: paleta.sobreAmbar)),
                const SizedBox(height: EspaciadoCampo.xs),
                Text(
                  etiqueta,
                  style: TipografiaCampo.tituloTarjeta.copyWith(
                    color: paleta.sobreAmbar,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.s),
                ColoredBox(
                  color: paleta.sobreAmbar,
                  child: const SizedBox(
                    width: EspaciadoCampo.xxl,
                    height: EspaciadoCampo.xs / 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Precio en una píldora: «Bs 62/ha» en mono. Sobre foto, blanca; la
/// [destacada] va en el color de acento.
class PastillaPrecioCampo extends StatelessWidget {
  const PastillaPrecioCampo({
    required this.valor,
    this.unidad = '/ha',
    this.destacada = false,
    super.key,
  });

  final String valor;
  final String unidad;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final color = destacada ? paleta.sobreAcento : paleta.texto;
    return Semantics(
      container: true,
      label: l10n.componentesPorHectarea(valor),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: destacada ? paleta.acento : paleta.superficie,
          borderRadius: BorderRadius.circular(RadioCampo.capsula),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EspaciadoCampo.l,
            vertical: EspaciadoCampo.m,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l10n.componentesBs(valor)),
                TextSpan(
                  text: unidad,
                  style: TipografiaCampo.cifraUnidad.copyWith(color: color),
                ),
              ],
            ),
            style: TipografiaCampo.cifraMedia.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

/// Barra de rondas de la negociación: [hechas] segmentos en ámbar y el resto
/// apagados. `RONDA 3/5` va al lado en mono.
class RondasColageCampo extends StatelessWidget {
  const RondasColageCampo({
    required this.hechas,
    required this.total,
    this.colorTexto,
    super.key,
  });

  final int hechas;
  final int total;

  /// Color de la etiqueta; por defecto el texto del tema.
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Semantics(
      label: l10n.componentesRonda(hechas, total),
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            l10n.componentesRonda2(hechas, total),
            style: TipografiaCampo.etiquetaMono.copyWith(
              color: colorTexto ?? paleta.texto,
            ),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: EspaciadoCampo.xs),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: i < hechas
                      ? paleta.ambar
                      : paleta.superficie.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(RadioCampo.capsula),
                ),
                child: const SizedBox(height: EspaciadoCampo.s),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Post-it del collage: papel con la esquina inferior derecha doblada y una
/// inclinación leve. Lleva una etiqueta mono, una línea de cuenta y el total.
class PostItCampo extends StatelessWidget {
  const PostItCampo({
    required this.etiqueta,
    required this.cuenta,
    required this.total,
    this.giro = -0.02,
    super.key,
  });

  final String etiqueta;
  final String cuenta;
  final String total;

  /// Giro en radianes (alrededor de −1,2°).
  final double giro;

  static const double _doblez = 22;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final color = paleta.sobrePapel;
    return Semantics(
      container: true,
      label: '$etiqueta. $cuenta. $total',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: giro,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: paleta.texto.withValues(alpha: 0.2),
                blurRadius: EspaciadoCampo.s,
                offset: const Offset(0, EspaciadoCampo.xs),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipPath(
                clipper: const _EsquinaCortada(_doblez),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [paleta.papel, paleta.papel2],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(EspaciadoCampo.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          etiqueta.toUpperCase(),
                          style: TipografiaCampo.etiquetaMono.copyWith(
                            color: color,
                          ),
                        ),
                        const SizedBox(height: EspaciadoCampo.xs),
                        Text(
                          cuenta,
                          style: TipografiaCampo.datoMono.copyWith(
                            color: color,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            total,
                            style: TipografiaCampo.cifraGrande.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: ClipPath(
                  clipper: const _Doblez(_doblez),
                  child: SizedBox(
                    width: _doblez,
                    height: _doblez,
                    child: ColoredBox(color: paleta.papelDoblez),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EsquinaCortada extends CustomClipper<Path> {
  const _EsquinaCortada(this.corte);

  final double corte;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - corte)
    ..lineTo(size.width - corte, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_EsquinaCortada oldClipper) => oldClipper.corte != corte;
}

class _Doblez extends CustomClipper<Path> {
  const _Doblez(this.lado);

  final double lado;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(lado, 0)
    ..lineTo(0, lado)
    ..close();

  @override
  bool shouldReclip(_Doblez oldClipper) => oldClipper.lado != lado;
}
