import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/servicio_asignado_auxiliar_repositorio.dart';

/// Servicio al que acompaña el auxiliar: lo que necesita para preparar la
/// mezcla y moverse en el lote.
class ServicioAuxiliarPantalla extends StatelessWidget {
  const ServicioAuxiliarPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return StreamEstable<Servicio?>(
      crear: () =>
          context.read<ServicioAsignadoAuxiliarRepositorio>().observar(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final s = snap.data;
        if (s == null) {
          return const EstadoVacioMarketplace(
            icono: Icons.inventory_2_outlined,
            titulo: 'Sin servicio asignado',
          );
        }
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Row(
              children: [
                Expanded(child: Text('Servicio', style: texto.headlineMedium)),
                InsigniaEstadoServicio(s.estado),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${s.lote.nombre} · ${s.lote.zona}',
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 200,
                child: MapaLote(
                  lotes: [s.lote],
                  seleccionado: s.lote,
                  interactivo: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SuperficieMarketplace(
              resaltada: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALDO A PREPARAR',
                    style: texto.labelSmall?.copyWith(
                      color: paleta.textoSecundario,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatoMarketplace.litros(s.litrosTotales),
                    style: texto.displaySmall?.copyWith(
                      color: paleta.acentoTexto,
                    ),
                  ),
                  Text(
                    '${FormatoMarketplace.numero(s.dosisLitrosPorHectarea, decimales: 1)} L/ha · '
                    '${FormatoMarketplace.hectareas(s.hectareasDeclaradas)}',
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SuperficieMarketplace(
              child: Column(
                children: [
                  _Fila('Producto', s.producto),
                  if (s.proveedor != null) _Fila('Piloto', s.proveedor!.nombre),
                  if (s.dron != null)
                    _Fila('Dron', '${s.dron!.modelo} · ${s.dron!.matricula}'),
                  _Fila(
                    'Capacidad del tanque',
                    s.dron != null
                        ? FormatoMarketplace.litros(s.dron!.capacidadLitros)
                        : '—',
                    ultimo: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila(this.etiqueta, this.valor, {this.ultimo = false});

  final String etiqueta;
  final String valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: texto.bodyMedium?.copyWith(
              color: context.paleta.textoSecundario,
            ),
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
