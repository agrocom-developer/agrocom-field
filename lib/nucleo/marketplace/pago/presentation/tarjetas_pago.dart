import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/componentes/esqueleto_campo.dart';
import '../../../ui/paleta_campo.dart';
import '../../../ui/tokens_campo.dart';
import '../../ui/aviso_marketplace.dart';
import '../../ui/boton_principal_marketplace.dart';
import '../../ui/superficie_marketplace.dart';
import '../pago_confirmado.dart';
import '../pagos_repositorio.dart';
import 'pago_cubit.dart';
import 'sello_pago_confirmado.dart';

export 'sello_pago_confirmado.dart';
export 'tarjeta_pago_del_cliente.dart';

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
