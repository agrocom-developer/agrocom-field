import 'package:flutter/material.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';

/// Quién hace el servicio: foto, nombre, calificación y el dron que vuela.
class TarjetaProveedor extends StatelessWidget {
  const TarjetaProveedor({required this.proveedor, this.dron, super.key});

  final Proveedor proveedor;
  final Dron? dron;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final dron = this.dron;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarProveedor(proveedor, tamano: ObjetivoTactilCampo.guantes),
              const SizedBox(width: EspaciadoCampo.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(proveedor.nombre, style: texto.titleMedium),
                    const SizedBox(height: EspaciadoCampo.xs),
                    CalificacionPromedio(
                      valor: proveedor.calificacion,
                      detalle: '${proveedor.serviciosCompletados} servicios',
                    ),
                    Text(
                      proveedor.tipo.etiqueta,
                      style: texto.bodySmall?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (dron != null) ...[
            Divider(height: EspaciadoCampo.xl, color: paleta.borde),
            Semantics(
              label: 'Dron ${dron.modelo}, matrícula ${dron.matricula}',
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(
                    Icons.flight_rounded,
                    size: 20,
                    color: paleta.textoSecundario,
                  ),
                  const SizedBox(width: EspaciadoCampo.s),
                  Expanded(
                    child: Text(
                      '${dron.modelo} · ${dron.matricula}',
                      style: texto.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
