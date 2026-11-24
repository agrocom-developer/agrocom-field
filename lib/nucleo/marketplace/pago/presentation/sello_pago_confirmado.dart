import 'package:flutter/material.dart';

import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../ui/formato_marketplace.dart';
import '../../ui/superficie_marketplace.dart';
import '../pago_confirmado.dart';

/// «Pago confirmado»: el sello que ven el proveedor y el cliente. El monto
/// es el que fijó el servidor.
class SelloPagoConfirmado extends StatelessWidget {
  const SelloPagoConfirmado({
    required this.pago,
    this.paraProveedor = false,
    super.key,
  });

  final PagoConfirmado pago;
  final bool paraProveedor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final detalle = [
      FormatoMarketplace.bs(pago.monto),
      ?pago.metodo?.etiqueta,
      FormatoMarketplace.fechaLarga(pago.confirmadoEn.toLocal()),
    ].join(' · ');
    return Semantics(
      container: true,
      label: 'Pago confirmado. $detalle',
      excludeSemantics: true,
      child: SuperficieMarketplace(
        key: const Key('pago-confirmado'),
        resaltada: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_rounded, color: paleta.exito, size: 32),
            const SizedBox(width: EspaciadoCampo.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pago confirmado', style: texto.titleLarge),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(detalle, style: texto.bodyLarge),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(
                    paraProveedor
                        ? 'Ya quedó registrado y el cliente lo ve. No hay '
                              'nada más que hacer.'
                        : 'El piloto confirmó que recibió el pago. Gracias '
                              'por usar Agrocom.',
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
