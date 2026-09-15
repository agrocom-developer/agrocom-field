import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/flavor.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes vigentes')),
      body: BlocBuilder<OrdenesCubit, OrdenesEstado>(
        builder: (context, estado) => switch (estado) {
          OrdenesCargando() => const Center(child: CircularProgressIndicator()),
          OrdenesVacia() => const Center(
            key: Key('ordenes_vacia'),
            child: Text('No hay órdenes vigentes.'),
          ),
          OrdenesLista(:final ordenes) => ListView.builder(
            key: const Key('ordenes_lista'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: ordenes.length,
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        key: Key('orden_${orden.id}'),
        leading: const Icon(Icons.grass_outlined),
        title: Text(orden.loteCodigo ?? 'Lote sin datos'),
        subtitle: Text(
          'Aplicación N.º ${orden.nroAplicacion} · ${_dosis(orden)} · '
          '${orden.fechaEmision}',
        ),
        trailing: const Icon(Icons.chevron_right),
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
