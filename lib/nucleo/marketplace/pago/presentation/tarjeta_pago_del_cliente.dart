import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/componentes/esqueleto_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../ui/aviso_marketplace.dart';
import '../../ui/superficie_marketplace.dart';
import '../pagos_repositorio.dart';
import 'pago_cubit.dart';
import 'sello_pago_confirmado.dart';
import '../../../../l10n/app_localizations.dart';

/// Lo que el cliente ve del pago en el seguimiento: «Pago confirmado» o que
/// todavía falta. Es de solo lectura.
class TarjetaPagoDelCliente extends StatelessWidget {
  const TarjetaPagoDelCliente({required this.solicitudId, super.key});

  final int solicitudId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) =>
          PagoCubit(context.read<PagosRepositorio>(), solicitudId, l10n)
            ..cargar(),
      child: BlocBuilder<PagoCubit, PagoEstado>(
        builder: (context, estado) {
          final texto = Theme.of(context).textTheme;
          final paleta = context.paleta;
          return switch (estado.fase) {
            FasePago.confirmado => SelloPagoConfirmado(pago: estado.pago!),
            FasePago.cargando ||
            FasePago.confirmando => const SuperficieMarketplace(
              child: EsqueletoCampo(
                key: Key('pago-carga'),
                alto: 56,
                radio: 12,
              ),
            ),
            FasePago.error => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AvisoMarketplace(
                  key: const Key('pago-cliente-error'),
                  tono: estado.fallo == FalloPago.sinRed
                      ? TonoAviso.alerta
                      : TonoAviso.error,
                  icono: estado.fallo == FalloPago.sinRed
                      ? Icons.wifi_off_rounded
                      : null,
                  mensaje: estado.mensaje ?? l10n.pagoPudimosRevisarPago,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('pago-cliente-reintentar'),
                    onPressed: context.read<PagoCubit>().cargar,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.pagoReintentar),
                  ),
                ),
              ],
            ),
            FasePago.pendiente => SuperficieMarketplace(
              key: const Key('pago-pendiente'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    color: paleta.textoSecundario,
                  ),
                  const SizedBox(width: EspaciadoCampo.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.pagoPagoPendiente, style: texto.titleMedium),
                        Text(
                          l10n.pagoPagasPilotoDirectamenteCuando,
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
          };
        },
      ),
    );
  }
}
