import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/estado_sync/presentation/indicador_sync.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/servicio_asignado_auxiliar_repositorio.dart';

/// Servicio al que acompaña el auxiliar: lo que necesita para preparar la
/// mezcla y moverse en el lote. Un dato protagonista (el caldo a preparar),
/// el lote en el mapa y los datos de apoyo; se lee del dispositivo, sin
/// esperar a la red.
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
            detalle:
                'Cuando un piloto te sume a su servicio, aparece acá con '
                'el caldo a preparar.',
          );
        }
        final margen = EspaciadoCampo.margenLateral(
          MediaQuery.sizeOf(context).width,
        );
        final caldo = FormatoMarketplace.litros(s.litrosTotales);
        final dron = s.dron;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            margen,
            EspaciadoCampo.l,
            margen,
            EspaciadoCampo.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text('Servicio', style: texto.headlineMedium),
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              '${s.lote.nombre} · ${s.lote.zona}',
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            Wrap(
              spacing: EspaciadoCampo.s,
              runSpacing: EspaciadoCampo.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InsigniaEstadoServicio(s.estado),
                const IndicadorSync(),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            SuperficieMarketplace(
              resaltada: true,
              radio: 24,
              padding: const EdgeInsets.all(EspaciadoCampo.l),
              child: Semantics(
                label: 'Caldo a preparar: $caldo',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CALDO A PREPARAR',
                      style: texto.labelSmall?.copyWith(
                        fontSize: 12,
                        color: paleta.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: EspaciadoCampo.xs),
                    // El dato protagonista se achica antes que cortarse con
                    // el texto escalado.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        caldo,
                        style: texto.displaySmall?.copyWith(
                          color: paleta.acentoTexto,
                        ),
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
            ),
            const SizedBox(height: EspaciadoCampo.m),
            Semantics(
              label: 'Mapa del lote ${s.lote.nombre}',
              image: true,
              child: ClipRRect(
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
            ),
            const SizedBox(height: EspaciadoCampo.m),
            SuperficieMarketplace(
              child: Column(
                children: [
                  _Fila('Producto', s.producto),
                  if (s.proveedor != null) _Fila('Piloto', s.proveedor!.nombre),
                  if (dron != null)
                    _Fila('Dron', '${dron.modelo} · ${dron.matricula}'),
                  _Fila(
                    'Capacidad del tanque',
                    dron != null
                        ? FormatoMarketplace.litros(dron.capacidadLitros)
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
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.only(bottom: ultimo ? 0 : EspaciadoCampo.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: texto.bodyMedium?.copyWith(
                color: context.paleta.textoSecundario,
              ),
            ),
            const SizedBox(width: EspaciadoCampo.l),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: texto.bodyMedium?.copyWith(
                  color: context.paleta.texto,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
