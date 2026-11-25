import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../notificaciones/notificador_local.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/falla.dart';
import '../../../ui/marketplace_ui.dart';
import '../di/dependencias_negociacion.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import '../../../../../l10n/app_localizations.dart';
import 'pedir_precio_hoja.dart' show leerPrecio;

// ------------------------------------------------------------------- cubit

class AvisosEstado {
  const AvisosEstado({
    this.cargando = true,
    this.preferencias = const PreferenciasAviso(),
    this.guardando = false,
    this.aviso,
    this.error = false,
  });

  final bool cargando;
  final PreferenciasAviso preferencias;
  final bool guardando;
  final String? aviso;
  final bool error;

  AvisosEstado copiarCon({
    bool? cargando,
    PreferenciasAviso? preferencias,
    bool? guardando,
    String? Function()? aviso,
    bool? error,
  }) => AvisosEstado(
    cargando: cargando ?? this.cargando,
    preferencias: preferencias ?? this.preferencias,
    guardando: guardando ?? this.guardando,
    aviso: aviso != null ? aviso() : this.aviso,
    error: error ?? this.error,
  );
}

/// Preferencias de aviso del piloto. Activar las nuevas solicitudes pide el
/// permiso de notificaciones del sistema, con el motivo a la vista; cada
/// cambio se guarda al momento y, si falla, se revierte y se dice por qué.
class AvisosCubit extends Cubit<AvisosEstado> {
  AvisosCubit(this._repositorio, {NotificadorLocal? notificador})
    : _notificador = notificador,
      super(const AvisosEstado());

  final AvisosRepositorio _repositorio;
  final NotificadorLocal? _notificador;

  Future<void> cargar() async {
    emit(state.copiarCon(cargando: true, error: false));
    try {
      final p = await _repositorio.leer();
      if (!isClosed) {
        emit(
          state.copiarCon(cargando: false, preferencias: p, aviso: () => null),
        );
      }
    } on FallaMarketplace catch (e) {
      if (!isClosed) {
        emit(
          state.copiarCon(
            cargando: false,
            error: true,
            aviso: () => e is OperacionRechazada
                ? e.mensaje
                : 'Sin conexión. Los avisos se configuran con señal.',
          ),
        );
      }
    }
  }

  Future<void> cambiar(PreferenciasAviso nuevas) async {
    final antes = state.preferencias;
    emit(
      state.copiarCon(
        preferencias: nuevas,
        guardando: true,
        aviso: () => null,
        error: false,
      ),
    );
    try {
      if (!antes.nuevasSolicitudes && nuevas.nuevasSolicitudes) {
        // El permiso se pide recién al activar los avisos.
        await _notificador?.pedirPermiso();
      }
      final guardadas = await _repositorio.guardar(nuevas);
      if (!isClosed) {
        emit(state.copiarCon(preferencias: guardadas, guardando: false));
      }
    } on FallaMarketplace catch (e) {
      if (!isClosed) {
        emit(
          state.copiarCon(
            preferencias: antes,
            guardando: false,
            error: true,
            aviso: () => e is OperacionRechazada
                ? e.mensaje
                : 'No se guardó: no hay conexión. Intenta con señal.',
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------- pantalla

class AvisosPantalla extends StatelessWidget {
  const AvisosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (context) => AvisosCubit(
        context.read<AvisosRepositorio>(),
        notificador: context.read<DependenciasNegociacion>().notificador,
      )..cargar(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.proveedorNegociacionAvisos)),
        body: const AvisosVista(),
      ),
    );
  }
}

class AvisosVista extends StatelessWidget {
  const AvisosVista({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<AvisosCubit, AvisosEstado>(
      builder: (context, estado) {
        final cubit = context.read<AvisosCubit>();
        final p = estado.preferencias;
        if (estado.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (estado.error &&
            estado.aviso != null &&
            p == const PreferenciasAviso()) {
          return EstadoErrorMarketplace(
            titulo: l10n.proveedorNegociacionPudimosCargarTusAvisos,
            detalle: estado.aviso,
            onReintentar: cubit.cargar,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text(
              l10n.proveedorNegociacionEligeQueQuieresEnterarte,
              style: texto.bodyLarge,
            ),
            const SizedBox(height: EspaciadoCampo.l),
            if (estado.aviso != null) ...[
              Semantics(
                liveRegion: true,
                child: AvisoMarketplace(
                  mensaje: estado.aviso!,
                  tono: TonoAviso.alerta,
                ),
              ),
              const SizedBox(height: EspaciadoCampo.l),
            ],
            SuperficieMarketplace(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Interruptor(
                    titulo: l10n.proveedorNegociacionNuevasSolicitudes,
                    detalle:
                        l10n.proveedorNegociacionAvisamosCuandoClientePublica,
                    valor: p.nuevasSolicitudes,
                    alCambiar: (v) =>
                        cubit.cambiar(p.copiarCon(nuevasSolicitudes: v)),
                  ),
                  if (p.nuevasSolicitudes) ...[
                    const Divider(height: EspaciadoCampo.xl),
                    Text(
                      l10n.proveedorNegociacionZonas,
                      style: texto.titleMedium,
                    ),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      p.macrorregiones.isEmpty
                          ? l10n.proveedorNegociacionTodasLasZonas
                          : p.macrorregiones.map((m) => m.etiqueta).join(', '),
                      style: texto.bodyMedium,
                    ),
                    const SizedBox(height: EspaciadoCampo.s),
                    Wrap(
                      spacing: EspaciadoCampo.s,
                      runSpacing: EspaciadoCampo.s,
                      children: [
                        for (final m in Macrorregion.values)
                          FilterChip(
                            label: Text(m.etiqueta),
                            selected: p.macrorregiones.contains(m),
                            onSelected: (activa) => cubit.cambiar(
                              p.copiarCon(
                                macrorregiones: activa
                                    ? [...p.macrorregiones, m]
                                    : [
                                        for (final x in p.macrorregiones)
                                          if (x != m) x,
                                      ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: EspaciadoCampo.l),
                    Text(
                      l10n.proveedorNegociacionHectareasMinimas,
                      style: texto.titleMedium,
                    ),
                    const SizedBox(height: EspaciadoCampo.s),
                    Wrap(
                      spacing: EspaciadoCampo.s,
                      children: [
                        for (final ha in [null, '20', '50', '100'])
                          ChoiceChip(
                            label: Text(
                              ha == null
                                  ? l10n.proveedorNegociacionCualquiera
                                  : l10n.proveedorNegociacionHa2(ha),
                            ),
                            selected:
                                p.hectareasMinimas ==
                                (ha == null ? null : leerPrecio(ha)),
                            onSelected: (_) => cubit.cambiar(
                              p.copiarCon(
                                hectareasMinimas: () =>
                                    ha == null ? null : Decimal.parse(ha),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            SuperficieMarketplace(
              child: Column(
                children: [
                  _Interruptor(
                    titulo: l10n.proveedorNegociacionOfertasContraofertas,
                    detalle:
                        l10n.proveedorNegociacionCuandoClienteRespondeOferta,
                    valor: p.ofertas,
                    alCambiar: (v) => cubit.cambiar(p.copiarCon(ofertas: v)),
                  ),
                  const Divider(height: EspaciadoCampo.xl),
                  _Interruptor(
                    titulo: l10n.proveedorNegociacionMensajes,
                    detalle: l10n.proveedorNegociacionCuandoClienteEscribeChat,
                    valor: p.mensajes,
                    alCambiar: (v) => cubit.cambiar(p.copiarCon(mensajes: v)),
                  ),
                  const Divider(height: EspaciadoCampo.xl),
                  _Interruptor(
                    titulo: l10n.proveedorNegociacionCalificaciones,
                    detalle: l10n.proveedorNegociacionCuandoClienteCalifica,
                    valor: p.calificaciones,
                    alCambiar: (v) =>
                        cubit.cambiar(p.copiarCon(calificaciones: v)),
                  ),
                ],
              ),
            ),
            if (estado.guardando)
              const Padding(
                padding: EdgeInsets.only(top: EspaciadoCampo.m),
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }
}

class _Interruptor extends StatelessWidget {
  const _Interruptor({
    required this.titulo,
    required this.detalle,
    required this.valor,
    required this.alCambiar,
  });

  final String titulo;
  final String detalle;
  final bool valor;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: texto.titleMedium),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: texto.bodyMedium?.copyWith(
                    color: context.paleta.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Semantics(
            label: titulo,
            child: Switch(value: valor, onChanged: alCambiar),
          ),
        ],
      ),
    );
  }
}
