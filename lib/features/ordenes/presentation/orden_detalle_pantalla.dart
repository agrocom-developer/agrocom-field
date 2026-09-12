import 'package:flutter/material.dart';

import '../../../nucleo/flavor.dart';
import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../sesion_vuelo/presentation/trabajo_cubit.dart';
import '../../sesion_vuelo/presentation/trabajo_estado.dart';
import '../../sesion_vuelo/presentation/sesion_vuelo_pantalla.dart';
import '../../sesion_vuelo/presentation/sesion_bloc.dart';
import '../domain/orden_vigente.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detalle de una orden vigente — recibe el `OrdenVigente` ya cargado en
/// memoria desde la lista (`OrdenesVista`), sin volver a consultar
/// `drift`: no hace falta, la fila completa ya viajó por el `Stream` del
/// repositorio.
///
/// No deserializa `LoteCatalogo.geometria` (HU-61, mapa, fuera de
/// alcance). Agrega el botón "Abrir trabajo" (HU-05) — exclusivo del flavor
/// `piloto` — que navega a [SesionVueloPantalla] con el trabajo recién
/// abierto, propagándole también [crearIncidenciaCubit] (HU-08).
class OrdenDetallePantalla extends StatelessWidget {
  const OrdenDetallePantalla({
    required this.orden,
    required this.flavor,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    super.key,
  });

  final OrdenVigente orden;
  final Flavor flavor;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  static const _sinDatos = 'sin datos';

  @override
  Widget build(BuildContext context) {
    // El BlocProvider<TrabajoCubit> se arma solo para flavor piloto: el
    // BlocConsumer lo lee en su initState (eager, no en el tap del botón), así
    // que envolverlo también para auxiliar invocaría `crearTrabajoCubit` —que
    // en `main_auxiliar.dart` lanza `UnimplementedError`— apenas se navega al
    // detalle de una orden, aunque el botón "Abrir trabajo" ya esté oculto.
    if (flavor != Flavor.piloto) {
      return _construirScaffold(context, cargandoTrabajo: false);
    }

    return BlocProvider<TrabajoCubit>(
      create: (_) => crearTrabajoCubit(),
      child: BlocConsumer<TrabajoCubit, TrabajoEstado>(
        listener: (context, estado) {
          if (estado is TrabajoExitoso) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SesionVueloPantalla(
                  crearBloc: () => crearSesionBloc(estado.trabajo.uuidCliente),
                  crearTrabajoCubit: crearTrabajoCubit,
                  crearIncidenciaCubit: crearIncidenciaCubit,
                ),
              ),
            );
          }
          if (estado is TrabajoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(estado.mensaje),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, estadoTrabajo) {
          final cargandoTrabajo = estadoTrabajo is TrabajoCargando;
          return _construirScaffold(context, cargandoTrabajo: cargandoTrabajo);
        },
      ),
    );
  }

  Widget _construirScaffold(
    BuildContext context, {
    required bool cargandoTrabajo,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text('Orden N.º ${orden.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(orden.estado),
              avatar: const Icon(Icons.check_circle_outline, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          _Seccion(
            titulo: 'Lote',
            campos: [
              _Campo('Código', orden.loteCodigo ?? _sinDatos),
              _Campo('Hectáreas', orden.loteHectareas?.toString() ?? _sinDatos),
            ],
          ),
          _Seccion(
            titulo: 'Aplicación',
            campos: [
              _Campo('N.º de aplicación', '${orden.nroAplicacion}'),
              _Campo('Litros por hectárea', '${orden.litrosHa}'),
              _Campo('Fecha de emisión', orden.fechaEmision),
            ],
          ),
          _Seccion(
            titulo: 'Límites climáticos',
            campos: [
              _Campo(
                'Humedad mínima (%)',
                orden.humedadMinPct?.toString() ?? _sinDatos,
              ),
              _Campo(
                'Humedad máxima (%)',
                orden.humedadMaxPct?.toString() ?? _sinDatos,
              ),
              _Campo(
                'Viento máximo (km/h)',
                orden.vientoMaxKmh?.toString() ?? _sinDatos,
              ),
              _Campo(
                'Temperatura máxima (°C)',
                orden.temperaturaMaxC?.toString() ?? _sinDatos,
              ),
            ],
          ),
          _Seccion(
            titulo: 'Parámetros de vuelo',
            campos: [
              _Campo(
                'Velocidad máxima (km/h)',
                orden.velocidadMaxKmh?.toString() ?? _sinDatos,
              ),
              _Campo(
                'Altura de vuelo (m)',
                orden.alturaVueloM?.toString() ?? _sinDatos,
              ),
              _Campo(
                'Velocidad de vuelo (km/h)',
                orden.velocidadVueloKmh?.toString() ?? _sinDatos,
              ),
              _Campo(
                'Ancho de pasada (m)',
                orden.anchoPasadaM?.toString() ?? _sinDatos,
              ),
            ],
          ),
          _Seccion(
            titulo: 'Observaciones',
            campos: [_Campo(null, orden.observaciones ?? _sinDatos)],
          ),
          if (flavor == Flavor.piloto) ...[
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('boton_abrir_trabajo'),
              onPressed: cargandoTrabajo
                  ? null
                  : () => context.read<TrabajoCubit>().abrir(orden: orden),
              child: cargandoTrabajo
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Abrir trabajo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Campo {
  const _Campo(this.etiqueta, this.valor);

  final String? etiqueta;
  final String valor;
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.campos});

  final String titulo;
  final List<_Campo> campos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(height: 16),
          for (final campo in campos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: campo.etiqueta == null
                  ? Text(campo.valor)
                  : Text('${campo.etiqueta}: ${campo.valor}'),
            ),
        ],
      ),
    );
  }
}
