import 'package:flutter/material.dart';

import '../paleta_campo.dart';
import '../tipografia_campo.dart';
import '../tokens_campo.dart';
import 'cifra_campo.dart';

/// Una fila clave/valor de un [TicketPedidoCampo]. Con [esCifra] el valor va
/// en mono (hectáreas, Bs/ha, totales).
class FilaTicketCampo {
  const FilaTicketCampo({
    required this.clave,
    required this.valor,
    this.unidad,
    this.esCifra = false,
  });

  final String clave;
  final String valor;
  final String? unidad;
  final bool esCifra;
}

/// Ticket de pedido: cabecera grafito con el número y el estado en ámbar,
/// filas clave/valor y un separador punteado antes del [total]. Sirve para
/// comparar ofertas y para el precio final.
class TicketPedidoCampo extends StatelessWidget {
  const TicketPedidoCampo({
    required this.numero,
    required this.estado,
    required this.filas,
    this.total,
    this.etiquetaTotal = 'Total',
    super.key,
  });

  /// Número de pedido ya formateado ("#0412").
  final String numero;

  /// Estado en palabras ("En negociación").
  final String estado;

  final List<FilaTicketCampo> filas;

  /// Total con formato, sin moneda; se muestra grande en mono.
  final String? total;
  final String etiquetaTotal;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Semantics(
      container: true,
      label: 'Pedido $numero, $estado',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paleta.superficie,
          border: Border.all(color: paleta.borde),
          borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
          boxShadow: ElevacionCampo.sombras(paleta, 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RadioCampo.tarjeta),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: paleta.grafito,
                padding: const EdgeInsets.symmetric(
                  horizontal: EspaciadoCampo.l,
                  vertical: EspaciadoCampo.m,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        numero,
                        style: TipografiaCampo.cifraMedia.copyWith(
                          color: paleta.sobreGrafito,
                        ),
                      ),
                    ),
                    const SizedBox(width: EspaciadoCampo.s),
                    Flexible(
                      child: Text(
                        estado.toUpperCase(),
                        textAlign: TextAlign.end,
                        style: TipografiaCampo.etiquetaMono.copyWith(
                          color: paleta.ambar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(EspaciadoCampo.l),
                child: Column(
                  children: [
                    for (final fila in filas) _Fila(fila: fila),
                    if (total != null) ...[
                      const SizedBox(height: EspaciadoCampo.s),
                      _SeparadorPunteado(color: paleta.bordeFuerte),
                      const SizedBox(height: EspaciadoCampo.m),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              etiquetaTotal,
                              style: TipografiaCampo.etiqueta.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                          ),
                          CifraCampo(valor: total!, unidad: 'Bs'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.fila});

  final FilaTicketCampo fila;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              fila.clave,
              style: TipografiaCampo.cuerpoSecundario.copyWith(
                color: paleta.textoSecundario,
              ),
            ),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Flexible(
            child: fila.esCifra
                ? CifraCampo(
                    valor: fila.valor,
                    unidad: fila.unidad,
                    estilo: TipografiaCampo.cifraMedia.copyWith(fontSize: 16),
                  )
                : Text(
                    fila.valor,
                    textAlign: TextAlign.end,
                    style: TipografiaCampo.tituloTarjeta.copyWith(
                      color: paleta.texto,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SeparadorPunteado extends StatelessWidget {
  const _SeparadorPunteado({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _PintorPunteado(color)),
    );
  }
}

class _PintorPunteado extends CustomPainter {
  const _PintorPunteado(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), pincel);
    }
  }

  @override
  bool shouldRepaint(_PintorPunteado viejo) => viejo.color != color;
}
