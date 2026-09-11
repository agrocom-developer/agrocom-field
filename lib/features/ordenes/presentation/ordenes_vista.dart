import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/orden_vigente.dart';
import 'orden_detalle_pantalla.dart';
import 'ordenes_cubit.dart';
import 'ordenes_estado.dart';

/// UI pura de la lista de órdenes vigentes — asume que un `OrdenesCubit` ya
/// está provisto más arriba en el árbol (`OrdenesPantalla`, o
/// `BlocProvider.value` en tests). Mismo split que `features/auth`
/// (`LoginPantalla`/`LoginVista`).
class OrdenesVista extends StatelessWidget {
  const OrdenesVista({super.key});

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
          OrdenesLista(:final ordenes) => ListView.separated(
            key: const Key('ordenes_lista'),
            itemCount: ordenes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, indice) =>
                _OrdenTile(orden: ordenes[indice]),
          ),
        },
      ),
    );
  }
}

class _OrdenTile extends StatelessWidget {
  const _OrdenTile({required this.orden});

  final OrdenVigente orden;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('orden_${orden.id}'),
      title: Text(orden.loteCodigo ?? 'Lote sin datos'),
      subtitle: Text(
        'Aplicación N.º ${orden.nroAplicacion} · ${orden.litrosHa} L/ha · '
        '${orden.fechaEmision}',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrdenDetallePantalla(orden: orden)),
      ),
    );
  }
}
