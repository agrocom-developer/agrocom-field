import 'package:flutter/material.dart';

import '../domain/orden_vigente.dart';

/// Detalle de una orden vigente — recibe el `OrdenVigente` ya cargado en
/// memoria desde la lista (`OrdenesVista`), sin volver a consultar
/// `drift`: no hace falta, la fila completa ya viajó por el `Stream` del
/// repositorio.
///
/// No deserializa `LoteCatalogo.geometria` (HU-61, mapa, fuera de
/// alcance) ni agrega ningún flujo de "abrir trabajo" (HU-05, otra rama).
class OrdenDetallePantalla extends StatelessWidget {
  const OrdenDetallePantalla({required this.orden, super.key});

  final OrdenVigente orden;

  static const _sinDatos = 'sin datos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orden N.º ${orden.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              _Campo('Estado', orden.estado),
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
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
