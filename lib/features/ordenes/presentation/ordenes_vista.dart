import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/flavor.dart';
import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/tema_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../sesion_vuelo/presentation/trabajo_cubit.dart';
import '../../sesion_vuelo/presentation/sesion_bloc.dart';
import '../domain/orden_vigente.dart';
import 'orden_detalle_pantalla.dart';
import 'ordenes_cubit.dart';
import 'ordenes_estado.dart';

/// UI pura de la lista de órdenes vigentes — asume que un `OrdenesCubit` ya
/// está provisto más arriba en el árbol (`OrdenesPantalla`, o
/// `BlocProvider.value` en tests). Mismo split que `features/auth`
/// (`LoginPantalla`/`LoginVista`).
///
/// Propaga las factories de [TrabajoCubit] y [SesionBloc] a
/// [OrdenDetallePantalla] (HU-05, etapa 4), y la de [IncidenciaCubit]
/// (HU-08).
///
/// En modo campo (ADR 0008, decisión del 1/10/2026): sin barra de título de
/// Material, título de pantalla y cada orden como una fila tocable del
/// catálogo. El fondo inferior deja aire para el botón de emergencia del
/// flavor auxiliar (HU-68), que flota encima de toda la app.
class OrdenesVista extends StatelessWidget {
  const OrdenesVista({
    required this.flavor,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    super.key,
  });

  final Flavor flavor;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AgrocomThemeCampo.construir(),
      child: Scaffold(
        backgroundColor: ColoresCampo.fondoProfundo,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 20, 18, 12),
                child: Text(
                  'Órdenes vigentes',
                  style: TipografiaCampo.tituloPantalla,
                ),
              ),
              Expanded(
                child: BlocBuilder<OrdenesCubit, OrdenesEstado>(
                  builder: (context, estado) => switch (estado) {
                    OrdenesCargando() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    OrdenesVacia() => Center(
                      key: const Key('ordenes_vacia'),
                      child: Text(
                        'No hay órdenes vigentes.',
                        style: TipografiaCampo.cuerpoSecundario,
                      ),
                    ),
                    OrdenesLista(:final ordenes) => ListView.separated(
                      key: const Key('ordenes_lista'),
                      // Abajo, lugar para el botón de emergencia (HU-68).
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
                      itemCount: ordenes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, indice) => _OrdenTile(
                        orden: ordenes[indice],
                        flavor: flavor,
                        crearTrabajoCubit: crearTrabajoCubit,
                        crearSesionBloc: crearSesionBloc,
                        crearIncidenciaCubit: crearIncidenciaCubit,
                      ),
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdenTile extends StatelessWidget {
  const _OrdenTile({
    required this.orden,
    required this.flavor,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
  });

  final OrdenVigente orden;
  final Flavor flavor;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  @override
  Widget build(BuildContext context) {
    return ItemListaCampo(
      key: Key('orden_${orden.id}'),
      icono: Icons.grass_outlined,
      titulo: orden.loteCodigo ?? 'Lote sin datos',
      subtitulo:
          'Aplicación N.º ${orden.nroAplicacion} · ${_dosis(orden)} · '
          '${orden.fechaEmision}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrdenDetallePantalla(
            orden: orden,
            flavor: flavor,
            crearTrabajoCubit: crearTrabajoCubit,
            crearSesionBloc: crearSesionBloc,
            crearIncidenciaCubit: crearIncidenciaCubit,
          ),
        ),
      ),
    );
  }
}

/// `litrosHa`/`kilosPorVuelo` son mutuamente excluyentes según la categoría
/// de insumo de la orden (HU-79 de `agrocom-api`) — nunca ambos, nunca
/// ninguno con datos reales, pero el pull es incremental por cursor así que
/// una orden recién llegada podría, en teoría, tener los dos en `null`
/// todavía.
String _dosis(OrdenVigente orden) {
  final litrosHa = orden.litrosHa;
  if (litrosHa != null) return '$litrosHa L/ha';
  final kilosPorVuelo = orden.kilosPorVuelo;
  if (kilosPorVuelo != null) return '$kilosPorVuelo kg/vuelo';
  return 'sin dosis';
}
