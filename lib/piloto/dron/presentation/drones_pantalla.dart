import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/drones_repositorio.dart';

/// Los drones del proveedor: el «vehículo» del marketplace, con matrícula,
/// capacidad y ciclos de batería.
class DronesPantalla extends StatelessWidget {
  const DronesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return StreamEstable<List<Dron>>(
      crear: () => context.read<DronesRepositorio>().observar(),
      builder: (context, snap) {
        final drones = snap.data ?? const <Dron>[];
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            Text('Mis drones', style: texto.headlineMedium),
            const SizedBox(height: 16),
            if (snap.data != null && drones.isEmpty)
              const EstadoVacioMarketplace(
                icono: Icons.flight_outlined,
                titulo: 'Todavía no registraste drones',
              ),
            for (final d in drones) ...[
              _TarjetaDron(dron: d),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaDron extends StatelessWidget {
  const _TarjetaDron({required this.dron});

  final Dron dron;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final (color, icono) = switch (dron.estado) {
      EstadoDron.disponible => (paleta.exito, Icons.check_circle_rounded),
      EstadoDron.enServicio => (paleta.info, Icons.flight_rounded),
      EstadoDron.mantenimiento => (paleta.alerta, Icons.build_rounded),
    };
    final desgaste = dron.desgasteBateria;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_rounded, color: paleta.acentoTexto),
              const SizedBox(width: 10),
              Expanded(child: Text(dron.modelo, style: texto.titleMedium)),
              Icon(icono, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                dron.estado.etiqueta,
                style: texto.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${dron.matricula} · ${dron.propiedad.etiqueta} · '
            '${FormatoMarketplace.litros(dron.capacidadLitros)}',
            style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Batería', style: texto.bodyMedium),
              const Spacer(),
              Text(
                '${dron.ciclosBateria} de ${dron.cicloMaximoBateria} ciclos',
                style: texto.bodySmall?.copyWith(color: paleta.textoSecundario),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: desgaste,
              minHeight: 8,
              backgroundColor: paleta.borde,
              color: desgaste > 0.75 ? paleta.alerta : paleta.acentoTexto,
            ),
          ),
        ],
      ),
    );
  }
}
