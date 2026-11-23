import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/presentation/calificar_pantalla.dart';
import '../../seguimiento/presentation/seguimiento_pantalla.dart';
import '../domain/servicios_cliente_repositorio.dart';

/// Detalle de un servicio: mapa del lote, datos, proveedor y acciones según
/// el estado (seguir en vivo, calificar).
class ServicioDetallePantalla extends StatelessWidget {
  const ServicioDetallePantalla({required this.servicioId, super.key});

  final String servicioId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Servicio>>(
      stream: context.read<ServiciosClienteRepositorio>().observar(),
      builder: (context, snap) {
        Servicio? s;
        for (final x in snap.data ?? const <Servicio>[]) {
          if (x.id == servicioId) s = x;
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Servicio')),
          body: s == null
              ? const Center(child: CircularProgressIndicator())
              : _Contenido(servicio: s),
        );
      },
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.servicio});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final p = servicio.proveedor;
    return ListView(
      padding: const EdgeInsets.only(bottom: EspaciadoCampo.xxl),
      children: [
        SizedBox(
          height: 220,
          child: MapaLote(
            lotes: [servicio.lote],
            seleccionado: servicio.lote,
            interactivo: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      servicio.lote.nombre,
                      style: texto.headlineSmall,
                    ),
                  ),
                  InsigniaEstadoServicio(servicio.estado),
                ],
              ),
              Text(
                '${servicio.lote.zona} · ${servicio.lote.cultivo}',
                style: texto.bodyMedium?.copyWith(
                  color: paleta.textoSecundario,
                ),
              ),
              const SizedBox(height: 20),
              SuperficieMarketplace(
                child: Column(
                  children: [
                    _Dato(
                      'Superficie',
                      FormatoMarketplace.hectareas(
                        servicio.hectareasDeclaradas,
                      ),
                    ),
                    _Dato('Producto', servicio.producto),
                    _Dato(
                      'Dosis',
                      '${FormatoMarketplace.numero(servicio.dosisLitrosPorHectarea, decimales: 1)} L/ha',
                    ),
                    _Dato(
                      'Caldo total',
                      FormatoMarketplace.litros(servicio.litrosTotales),
                    ),
                    _Dato(
                      'Fecha',
                      FormatoMarketplace.fechaLarga(servicio.fechaDeseada),
                    ),
                    _Dato(
                      'Precio estimado',
                      FormatoMarketplace.bs(servicio.precio),
                      ultimo: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (p != null)
                SuperficieMarketplace(
                  child: Row(
                    children: [
                      AvatarProveedor(p),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombre, style: texto.titleMedium),
                            Text(
                              p.tipo.etiqueta,
                              style: texto.bodySmall?.copyWith(
                                color: paleta.textoSecundario,
                              ),
                            ),
                            const SizedBox(height: 2),
                            CalificacionPromedio(
                              valor: p.calificacion,
                              detalle: '${p.serviciosCompletados} servicios',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (servicio.estado == EstadoServicio.buscandoProveedor)
                const AvisoMarketplace(
                  mensaje:
                      'Estamos buscando un proveedor. Primero lo ofrecemos a '
                      'la flota de Agrocom y, si nadie lo toma, a proveedores '
                      'de la zona.',
                ),
              const SizedBox(height: 20),
              if (servicio.estado == EstadoServicio.enEjecucion)
                BotonPrimarioCampo(
                  texto: 'Seguir en vivo',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SeguimientoPantalla(servicio: servicio),
                    ),
                  ),
                ),
              if (servicio.estado == EstadoServicio.completado &&
                  servicio.puntajeDelCliente == null)
                BotonPrimarioCampo(
                  texto: 'Calificar al proveedor',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => CalificarPantalla(servicio: servicio),
                    ),
                  ),
                ),
              if (servicio.puntajeDelCliente != null) ...[
                Row(
                  children: [
                    Text('Tu calificación', style: texto.titleSmall),
                    const SizedBox(width: 12),
                    CalificacionCampo(valor: servicio.puntajeDelCliente!),
                  ],
                ),
              ],
              if (servicio.puntajeDelProveedor != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Te calificó', style: texto.titleSmall),
                    const SizedBox(width: 12),
                    CalificacionCampo(valor: servicio.puntajeDelProveedor!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.etiqueta, this.valor, {this.ultimo = false});

  final String etiqueta;
  final String valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
