import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import 'cifra_campo.dart';

/// Una foto del collage con la hora a la que se tomó (en mono, sobre la
/// foto). [imagen] es cualquier widget que llene su caja (foto remota, de
/// archivo o de la vitrina).
class FotoCollageCampo {
  const FotoCollageCampo({
    required this.imagen,
    required this.hora,
    required this.descripcion,
  });

  final Widget imagen;

  /// Hora con formato ("14:32").
  final String hora;

  /// Lo que anuncia el lector de pantalla.
  final String descripcion;
}

/// Collage de avance del servicio: cuadrícula 2fr/1fr con gap de 4 y radio
/// 18. A la izquierda la foto grande; a la derecha una foto y un bloque ámbar
/// con el dato clave ([valorDato] + [unidadDato], p. ej. «38,5 ha»).
class CollageFotosCampo extends StatelessWidget {
  const CollageFotosCampo({
    required this.principal,
    required this.secundaria,
    required this.valorDato,
    required this.unidadDato,
    required this.etiquetaDato,
    this.alto = 240,
    super.key,
  });

  final FotoCollageCampo principal;
  final FotoCollageCampo secundaria;
  final String valorDato;
  final String unidadDato;
  final String etiquetaDato;
  final double alto;

  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return SizedBox(
      height: alto,
      child: Row(
        children: [
          Expanded(flex: 2, child: _Foto(foto: principal)),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _Foto(foto: secundaria)),
                const SizedBox(height: _gap),
                Expanded(
                  child: Semantics(
                    container: true,
                    label: '$etiquetaDato: $valorDato $unidadDato',
                    excludeSemantics: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: paleta.ambar,
                        borderRadius: BorderRadius.circular(
                          RadioCampo.tarjetaCompacta,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(EspaciadoCampo.s),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                etiquetaDato.toUpperCase(),
                                style: TipografiaCampo.etiquetaMono.copyWith(
                                  color: paleta.sobreAmbar,
                                ),
                              ),
                              CifraCampo(
                                valor: valorDato,
                                unidad: unidadDato,
                                color: paleta.sobreAmbar,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  const _Foto({required this.foto});

  final FotoCollageCampo foto;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      image: true,
      label: '${foto.descripcion}, ${foto.hora}',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadioCampo.tarjetaCompacta),
        child: Stack(
          fit: StackFit.expand,
          children: [
            foto.imagen,
            Positioned(
              left: EspaciadoCampo.s,
              bottom: EspaciadoCampo.s,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: paleta.grafito.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(RadioCampo.xs),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EspaciadoCampo.s,
                    vertical: 2,
                  ),
                  child: Text(
                    foto.hora,
                    style: TipografiaCampo.datoMono.copyWith(
                      color: paleta.sobreGrafito,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
