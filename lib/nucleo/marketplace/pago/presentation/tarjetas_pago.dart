import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/componentes/esqueleto_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../ui/aviso_marketplace.dart';
import '../../ui/boton_principal_marketplace.dart';
import '../../ui/formato_marketplace.dart';
import '../../ui/superficie_marketplace.dart';
import '../pago_confirmado.dart';
import '../pagos_repositorio.dart';
import 'pago_cubit.dart';

/// «Ya recibí el pago»: lo que el proveedor titular ve en el servicio
/// finalizado. La app no cobra; solo deja constancia de un pago hecho fuera,
/// una sola vez. Lee [PagosRepositorio] del contexto.
class TarjetaConfirmarPago extends StatelessWidget {
  const TarjetaConfirmarPago({required this.solicitudId, super.key});

  final int solicitudId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PagoCubit(context.read<PagosRepositorio>(), solicitudId)..cargar(),
      child: const _VistaConfirmar(),
    );
  }
}

class _VistaConfirmar extends StatelessWidget {
  const _VistaConfirmar();

  Future<void> _preguntar(BuildContext context) async {
    final cubit = context.read<PagoCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Confirmas que recibiste el pago?'),
        content: const Text(
          'Solo se puede confirmar una vez. El cliente verá que el pago '
          'quedó confirmado.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(64, ObjetivoTactilCampo.guantes),
            ),
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Todavía no'),
          ),
          FilledButton(
            key: const Key('pago-confirmar-si'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, ObjetivoTactilCampo.guantes),
            ),
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Sí, lo recibí'),
          ),
        ],
      ),
    );
    if (ok ?? false) await cubit.confirmar();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return BlocBuilder<PagoCubit, PagoEstado>(
      builder: (context, estado) {
        final cubit = context.read<PagoCubit>();
        if (estado.fase == FasePago.cargando) {
          return const SuperficieMarketplace(
            child: EsqueletoCampo(key: Key('pago-carga'), alto: 88, radio: 12),
          );
        }
        if (estado.fase == FasePago.confirmado) {
          return SelloPagoConfirmado(pago: estado.pago!, paraProveedor: true);
        }
        // Un error al leer (aún no se pudo saber si hay pago) solo permite
        // reintentar la lectura; un error al confirmar, la confirmación.
        final falloDeLectura =
            estado.fase == FasePago.error && estado.fallaAlLeer;
        return SuperficieMarketplace(
          resaltada: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('¿Ya te pagaron?', style: texto.titleLarge),
              ),
              const SizedBox(height: EspaciadoCampo.xs),
              Text(
                'El cliente te paga directamente. Cuando lo recibas, '
                'confírmalo aquí: la app no cobra ni mueve dinero.',
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
              if (!falloDeLectura) ...[
                const SizedBox(height: EspaciadoCampo.m),
                Text('¿Cómo te pagó? (opcional)', style: texto.labelLarge),
                const SizedBox(height: EspaciadoCampo.s),
                Wrap(
                  spacing: EspaciadoCampo.s,
                  runSpacing: EspaciadoCampo.s,
                  children: [
                    for (final m in MetodoPago.values)
                      ChoiceChip(
                        key: Key('pago-metodo-${m.api}'),
                        label: Text(m.etiqueta),
                        selected: estado.metodo == m,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onSelected: estado.fase == FasePago.confirmando
                            ? null
                            : (v) => cubit.elegirMetodo(v ? m : null),
                      ),
                  ],
                ),
              ],
              if (estado.fase == FasePago.error) ...[
                const SizedBox(height: EspaciadoCampo.m),
                Semantics(
                  liveRegion: true,
                  child: AvisoMarketplace(
                    key: const Key('pago-aviso'),
                    mensaje: estado.mensaje ?? 'No pudimos confirmar el pago.',
                    tono: estado.fallo == FalloPago.sinRed
                        ? TonoAviso.alerta
                        : TonoAviso.error,
                    icono: estado.fallo == FalloPago.sinRed
                        ? Icons.wifi_off_rounded
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: EspaciadoCampo.l),
              if (estado.fase == FasePago.error && !estado.sePuedeReintentar)
                const SizedBox.shrink()
              else
                BotonPrincipalMarketplace(
                  key: const Key('pago-confirmar'),
                  alto: ObjetivoTactilCampo.guantes,
                  texto: estado.fase == FasePago.error
                      ? 'Reintentar'
                      : 'Ya recibí el pago',
                  icono: estado.fase == FasePago.error
                      ? Icons.refresh_rounded
                      : Icons.payments_outlined,
                  cargando: estado.fase == FasePago.confirmando,
                  onPressed: () => falloDeLectura
                      ? cubit.cargar()
                      : estado.fase == FasePago.error
                      ? cubit.confirmar()
                      : _preguntar(context),
                ),
            ],
          ),
        );
      },
    );
  }
}

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

/// Lo que el cliente ve del pago en el seguimiento: «Pago confirmado» o que
/// todavía falta. Es de solo lectura.
class TarjetaPagoDelCliente extends StatelessWidget {
  const TarjetaPagoDelCliente({required this.solicitudId, super.key});

  final int solicitudId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PagoCubit(context.read<PagosRepositorio>(), solicitudId)..cargar(),
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
                  mensaje: estado.mensaje ?? 'No pudimos revisar el pago.',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('pago-cliente-reintentar'),
                    onPressed: context.read<PagoCubit>().cargar,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
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
                        Text('Pago pendiente', style: texto.titleMedium),
                        Text(
                          'Le pagas al piloto directamente. Cuando él '
                          'confirme que lo recibió, lo verás aquí.',
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
