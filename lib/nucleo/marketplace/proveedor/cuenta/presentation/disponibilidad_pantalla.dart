import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/marketplace_ui.dart';
import '../../negociacion/domain/negociacion_repositorios.dart';
import '../../negociacion/presentation/avisos_pantalla.dart';
import '../domain/cuenta_proveedor.dart';
import 'disponibilidad_cubit.dart';
import 'textos_cuenta.dart';

/// El interruptor de disponibilidad: desactivarse a mano y ver los parámetros
/// de aviso. Cambiarlo es una llamada en línea; sin red no cambia y lo dice.
class DisponibilidadPantalla extends StatelessWidget {
  const DisponibilidadPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) => DisponibilidadCubit(
        context.read<CuentaProveedorRepositorio>(),
        context.read<AvisosRepositorio>(),
        l10n,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.disponibilidadTitulo)),
        body: const _Cuerpo(),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return BlocBuilder<DisponibilidadCubit, DisponibilidadEstado>(
      builder: (context, estado) {
        if (estado.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        final propia = estado.propia;
        if (estado.error || propia == null) {
          return EstadoErrorMarketplace(
            titulo: l10n.disponibilidadErrorCarga,
            detalle: estado.sinRed
                ? l10n.cuentaSinRed
                : l10n.disponibilidadErrorDetalle,
            sinConexion: estado.sinRed,
            onReintentar: context.read<DisponibilidadCubit>().cargar,
          );
        }
        final p = estado.preferencias;
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text(
              l10n.disponibilidadIntro,
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.l),
            if (propia.laCambioLaEmpresa) ...[
              AvisoMarketplace(
                key: const Key('disponibilidad-empresa-te-marco'),
                mensaje: l10n.disponibilidadEmpresaTeMarco(
                  propia.valor.etiqueta(l10n).toLowerCase(),
                ),
              ),
              const SizedBox(height: EspaciadoCampo.m),
            ],
            if (estado.empresaOcupada) ...[
              AvisoMarketplace(
                key: const Key('disponibilidad-empresa-ocupada'),
                tono: TonoAviso.alerta,
                mensaje: l10n.disponibilidadEmpresaOcupada(
                  estado.empresa!.valor.etiqueta(l10n).toLowerCase(),
                ),
              ),
              const SizedBox(height: EspaciadoCampo.m),
            ],
            if (estado.aviso != null) ...[
              Semantics(
                liveRegion: true,
                child: AvisoMarketplace(
                  mensaje: estado.aviso!,
                  tono: TonoAviso.error,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.m),
            ],
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.disponibilidadEstadoActual(propia.valor.etiqueta(l10n)),
                style: texto.titleMedium,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            for (final v in Disponibilidad.values) ...[
              _Opcion(
                valor: v,
                seleccionada: v == propia.valor,
                habilitada: !estado.cambiando,
              ),
              const SizedBox(height: EspaciadoCampo.s),
            ],
            const SizedBox(height: EspaciadoCampo.l),
            Text(l10n.disponibilidadTusAvisos, style: texto.titleMedium),
            const SizedBox(height: EspaciadoCampo.s),
            SuperficieMarketplace(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nuevasSolicitudes
                        ? l10n.disponibilidadAvisosActivos
                        : l10n.disponibilidadAvisosApagados,
                    style: texto.bodyLarge,
                  ),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(
                    l10n.disponibilidadHectareasMinimas(
                      p.hectareasMinimas?.toString() ??
                          l10n.disponibilidadCualquiera,
                    ),
                    style: texto.bodyMedium,
                  ),
                  Text(
                    l10n.disponibilidadDepartamentosExcluidos(
                      p.departamentosExcluidos.length,
                    ),
                    style: texto.bodyMedium,
                  ),
                  Text(
                    l10n.disponibilidadTiposExcluidos(
                      p.tiposAplicacionExcluidos.length,
                    ),
                    style: texto.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            TextButton.icon(
              key: const Key('disponibilidad-ajustar-avisos'),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AvisosPantalla(),
                  ),
                );
                if (context.mounted) {
                  context.read<DisponibilidadCubit>().cargar();
                }
              },
              icon: const Icon(Icons.tune_rounded),
              label: Text(l10n.disponibilidadAjustarAvisos),
            ),
          ],
        );
      },
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.valor,
    required this.seleccionada,
    required this.habilitada,
  });

  final Disponibilidad valor;
  final bool seleccionada;
  final bool habilitada;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Semantics(
      button: true,
      selected: seleccionada,
      inMutuallyExclusiveGroup: true,
      enabled: habilitada,
      label: '${valor.etiqueta(l10n)}. ${valor.detalle(l10n)}',
      excludeSemantics: true,
      onTap: habilitada ? () => _elegir(context) : null,
      child: SuperficieMarketplace(
        key: Key('disponibilidad-${valor.codigo}'),
        onTap: habilitada ? () => _elegir(context) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: ObjetivoTactilCampo.guantes - EspaciadoCampo.xxl,
          ),
          child: Row(
            children: [
              Icon(
                valor.icono,
                color: seleccionada
                    ? paleta.acentoTexto
                    : paleta.textoSecundario,
              ),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(valor.etiqueta(l10n), style: texto.titleMedium),
                    Text(
                      valor.detalle(l10n),
                      style: texto.bodyMedium?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              // La marca de elegido es un ícono, no solo color; entra con
              // un fundido corto que respeta «reducir movimiento».
              AnimatedOpacity(
                duration: MovimientoCampo.duracion(
                  context,
                  MovimientoCampo.rapida,
                ),
                curve: MovimientoCampo.entrada,
                opacity: seleccionada ? 1 : 0,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: paleta.acentoTexto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _elegir(BuildContext context) {
    HapticaCampo.seleccion();
    context.read<DisponibilidadCubit>().cambiar(valor);
  }
}
