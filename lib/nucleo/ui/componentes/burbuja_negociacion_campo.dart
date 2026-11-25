import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import 'cifra_campo.dart';

/// Quién escribe una ronda de la negociación.
enum AutorRonda { cliente, piloto }

/// Una ronda de la negociación como burbuja de conversación: el cliente a la
/// izquierda sobre la superficie y el piloto a la derecha en el acento.
///
/// Muestra la etiqueta «R# · QUIÉN», el precio por hectárea y el total (ambos
/// ya formateados), y una barra de [totalRondas] segmentos: hechas en el
/// acento, la del turno en ámbar y las pendientes vacías.
class BurbujaNegociacionCampo extends StatelessWidget {
  const BurbujaNegociacionCampo({
    required this.autor,
    required this.ronda,
    required this.precioPorHectarea,
    required this.total,
    this.totalRondas = 5,
    this.esTurno = false,
    this.conBarra = true,
    this.nota,
    this.quien,
    super.key,
  });

  final AutorRonda autor;

  /// Número de ronda, desde 1.
  final int ronda;

  /// Precio por hectárea con formato, sin unidad ("85").
  final String precioPorHectarea;

  /// Total con formato, sin moneda ("7.680").
  final String total;

  final int totalRondas;

  /// La ronda en curso (turno de responder): su segmento va en ámbar.
  final bool esTurno;

  /// Dibuja la barra de rondas dentro de la burbuja. En una conversación
  /// completa la barra va una sola vez en el encabezado y se apaga aquí.
  final bool conBarra;

  /// Frase corta bajo las cifras («publicado», o lo que escribió quien
  /// ofertó).
  final String? nota;

  /// Quién escribe, en mayúsculas, si no es «CLIENTE» ni «PILOTO» (la
  /// pantalla del propio piloto dice «TÚ»).
  final String? quien;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final delPiloto = autor == AutorRonda.piloto;
    final fondo = delPiloto ? paleta.acento : paleta.superficie;
    final textoPrincipal = delPiloto ? paleta.sobreAcento : paleta.texto;
    final textoApoyo = delPiloto ? paleta.sobreAcento : paleta.textoSecundario;
    final autorEtiqueta =
        quien ??
        (delPiloto
            ? l10n.componentesPilotoMayuscula
            : l10n.componentesClienteMayuscula);
    const radio = Radius.circular(RadioCampo.tarjeta);
    const esquina = Radius.circular(RadioCampo.xs);
    return Semantics(
      container: true,
      label: l10n.componentesRondaSemantica(
        ronda,
        totalRondas,
        quien?.toLowerCase() ??
            (delPiloto
                ? l10n.componentesPilotoMinuscula
                : l10n.componentesClienteMinuscula),
        precioPorHectarea,
        total,
        nota == null ? '' : l10n.componentesNotaSufijo(nota!),
        esTurno ? l10n.componentesTurnoSufijo : '',
      ),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, caja) => Row(
          mainAxisAlignment: delPiloto
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: caja.maxWidth * 0.82),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fondo,
                    border: delPiloto ? null : Border.all(color: paleta.borde),
                    borderRadius: BorderRadius.only(
                      topLeft: radio,
                      topRight: radio,
                      bottomLeft: delPiloto ? radio : esquina,
                      bottomRight: delPiloto ? esquina : radio,
                    ),
                    boxShadow: ElevacionCampo.sombras(paleta, 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(EspaciadoCampo.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'R$ronda · $autorEtiqueta',
                          style: TipografiaCampo.etiquetaMono.copyWith(
                            color: textoApoyo,
                          ),
                        ),
                        const SizedBox(height: EspaciadoCampo.s),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: EspaciadoCampo.l,
                          runSpacing: EspaciadoCampo.xs,
                          children: [
                            CifraCampo(
                              valor: precioPorHectarea,
                              unidad: 'Bs/ha',
                              estilo: TipografiaCampo.cifraMedia,
                              color: textoPrincipal,
                            ),
                            CifraCampo(
                              valor: total,
                              unidad: 'Bs',
                              estilo: TipografiaCampo.cifraMedia,
                              color: textoPrincipal,
                            ),
                          ],
                        ),
                        if (nota != null) ...[
                          const SizedBox(height: EspaciadoCampo.s),
                          Text(
                            nota!,
                            style: TipografiaCampo.cuerpoSecundario.copyWith(
                              color: textoApoyo,
                            ),
                          ),
                        ],
                        if (conBarra) ...[
                          const SizedBox(height: EspaciadoCampo.m),
                          _BarraRondas(
                            ronda: ronda,
                            total: totalRondas,
                            esTurno: esTurno,
                            hecho: delPiloto
                                ? paleta.sobreAcento
                                : paleta.acento,
                            vacio: delPiloto
                                ? paleta.sobreAcento.withValues(alpha: 0.3)
                                : paleta.borde,
                            turno: paleta.ambar,
                          ),
                        ],
                      ],
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

class _BarraRondas extends StatelessWidget {
  const _BarraRondas({
    required this.ronda,
    required this.total,
    required this.esTurno,
    required this.hecho,
    required this.vacio,
    required this.turno,
  });

  final int ronda;
  final int total;
  final bool esTurno;
  final Color hecho;
  final Color vacio;
  final Color turno;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: EspaciadoCampo.xs),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < ronda || (i == ronda && !esTurno)
                    ? hecho
                    : (i == ronda ? turno : vacio),
                borderRadius: BorderRadius.circular(RadioCampo.xs),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
