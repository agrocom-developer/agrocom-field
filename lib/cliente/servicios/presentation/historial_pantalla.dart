import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/servicios_cliente_repositorio.dart';
import 'servicio_detalle_pantalla.dart';
import 'tarjeta_servicio.dart';

enum _Filtro { todos, activos, completados }

/// Todos los servicios del cliente, con un filtro simple.
class HistorialPantalla extends StatefulWidget {
  const HistorialPantalla({super.key});

  @override
  State<HistorialPantalla> createState() => _HistorialPantallaState();
}

class _HistorialPantallaState extends State<HistorialPantalla> {
  _Filtro _filtro = _Filtro.todos;

  bool _pasa(Servicio s) => switch (_filtro) {
    _Filtro.todos => true,
    _Filtro.activos => s.estado.activo,
    _Filtro.completados => s.estado == EstadoServicio.completado,
  };

  @override
  Widget build(BuildContext context) {
    return StreamEstable<List<Servicio>>(
      crear: () => context.read<ServiciosClienteRepositorio>().observar(),
      builder: (context, snap) {
        final todos = snap.data;
        final lista = todos?.where(_pasa).toList() ?? const <Servicio>[];
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text(
              'Mis servicios',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<_Filtro>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Filtro.todos, label: Text('Todos')),
                ButtonSegment(value: _Filtro.activos, label: Text('Activos')),
                ButtonSegment(
                  value: _Filtro.completados,
                  label: Text('Listos'),
                ),
              ],
              selected: {_filtro},
              onSelectionChanged: (v) {
                HapticaCampo.seleccion();
                setState(() => _filtro = v.first);
              },
            ),
            const SizedBox(height: 16),
            if (todos == null)
              const EsqueletoCampo(alto: 140)
            else if (lista.isEmpty)
              const EstadoVacioMarketplace(
                icono: Icons.inbox_outlined,
                titulo: 'Sin servicios en esta vista',
              )
            else
              for (final s in lista) ...[
                TarjetaServicio(
                  servicio: s,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ServicioDetallePantalla(servicioId: s.id),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}
