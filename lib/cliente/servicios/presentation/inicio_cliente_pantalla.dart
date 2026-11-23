import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/demo/datos_demo.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../calificar/presentation/calificar_pantalla.dart';
import '../../seguimiento/presentation/seguimiento_pantalla.dart';
import '../domain/servicios_cliente_repositorio.dart';
import 'servicio_detalle_pantalla.dart';
import 'tarjeta_servicio.dart';

/// Pantalla inicial del cliente: lo que está pasando con sus servicios y la
/// acción principal, solicitar uno nuevo.
class InicioClientePantalla extends StatelessWidget {
  const InicioClientePantalla({required this.alSolicitar, super.key});

  final VoidCallback alSolicitar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return StreamBuilder<List<Servicio>>(
      stream: context.read<ServiciosClienteRepositorio>().observar(),
      builder: (context, snap) {
        final servicios = snap.data;
        if (servicios == null) return const _Cargando();
        final activos = servicios.where((s) => s.estado.activo).toList();
        final porCalificar = servicios
            .where(
              (s) =>
                  s.estado == EstadoServicio.completado &&
                  s.puntajeDelCliente == null,
            )
            .toList();
        final recientes = servicios
            .where(
              (s) =>
                  s.estado == EstadoServicio.completado &&
                  s.puntajeDelCliente != null,
            )
            .take(2)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            EspaciadoCampo.l,
            EspaciadoCampo.xl,
            EspaciadoCampo.l,
            EspaciadoCampo.xxl,
          ),
          children: [
            Text(
              'Hola, ${DatosDemo.clienteNombre.split(' ').first}',
              style: texto.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              DatosDemo.clienteEmpresa,
              style: texto.bodyLarge?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: 20),
            BotonPrimarioCampo(
              texto: 'Solicitar un servicio',
              onPressed: alSolicitar,
            ),
            if (activos.isNotEmpty) ...[
              const _Seccion('En curso'),
              for (final s in activos) ...[
                TarjetaServicio(
                  servicio: s,
                  resaltada: s.estado == EstadoServicio.enEjecucion,
                  onTap: () => _abrirDetalle(context, s),
                  acciones: [
                    if (s.estado == EstadoServicio.enEjecucion)
                      FilledButton.icon(
                        onPressed: () => _seguir(context, s),
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('Seguir en vivo'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
            if (porCalificar.isNotEmpty) ...[
              const _Seccion('Por calificar'),
              for (final s in porCalificar) ...[
                TarjetaServicio(
                  servicio: s,
                  onTap: () => _abrirDetalle(context, s),
                  acciones: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => CalificarPantalla(servicio: s),
                        ),
                      ),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Calificar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
            if (activos.isEmpty && porCalificar.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: EstadoVacioMarketplace(
                  icono: Icons.grass_rounded,
                  titulo: 'No tenés servicios en curso',
                  detalle: 'Solicitá uno y seguilo en vivo desde acá.',
                ),
              ),
            if (recientes.isNotEmpty) ...[
              const _Seccion('Recientes'),
              for (final s in recientes) ...[
                TarjetaServicio(
                  servicio: s,
                  onTap: () => _abrirDetalle(context, s),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        );
      },
    );
  }

  static void _abrirDetalle(BuildContext context, Servicio s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicioDetallePantalla(servicioId: s.id),
      ),
    );
  }

  static void _seguir(BuildContext context, Servicio s) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SeguimientoPantalla(servicio: s)),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(EspaciadoCampo.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EsqueletoCampo(alto: 32, ancho: 200),
        SizedBox(height: 24),
        EsqueletoCampo(alto: 56),
        SizedBox(height: 24),
        EsqueletoCampo(alto: 150),
        SizedBox(height: 12),
        EsqueletoCampo(alto: 150),
      ],
    ),
  );
}
