import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/estado_sync/presentation/indicador_sync.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/servicio_asignado_repositorio.dart';
import 'abrir_sesion_de_vuelo.dart';
import 'servicio_detalle_pantalla.dart';

/// Inicio del piloto en el lote: sus servicios asignados. El vigente va
/// primero y grande, con un dato protagonista (hectáreas cubiertas) y la
/// acción principal de 56 px; los siguientes, como lista. Todo viene del
/// repositorio local: sin esqueleto, sin espera de red (sistema visual,
/// §9).
class ServicioAsignadoPantalla extends StatelessWidget {
  const ServicioAsignadoPantalla({super.key});

  void _verDetalle(BuildContext context, Servicio servicio) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServicioDetallePantalla(servicioId: servicio.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return StreamEstable<List<Servicio>>(
      crear: () => context.read<ServicioAsignadoRepositorio>().observar(),
      builder: (context, snap) {
        // Lectura local: sin esqueleto; el primer cuadro queda vacío.
        if (snap.data == null) return const SizedBox.shrink();
        final lista = snap.data!;
        if (lista.isEmpty) {
          return const EstadoVacioMarketplace(
            icono: Icons.flight_takeoff_rounded,
            titulo: 'Sin servicio asignado',
            detalle:
                'Aceptá una oferta y el servicio aparece acá, listo '
                'para trabajar sin señal.',
          );
        }
        final activos = lista.where((s) => s.estado.activo).toList();
        final cerrados = lista.where((s) => !s.estado.activo).toList();
        final actual = activos.isEmpty ? null : activos.first;
        final proximos = activos.skip(1).toList();
        final margen = EspaciadoCampo.margenLateral(
          MediaQuery.sizeOf(context).width,
        );
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
              child: Text('Mis servicios', style: texto.headlineMedium),
            ),
            const SizedBox(height: EspaciadoCampo.m),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: IndicadorSync(),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            if (actual == null)
              const _SinServicioVigente()
            else
              _ServicioVigente(
                servicio: actual,
                onAbrirSesion: () => abrirSesionDeVuelo(context, actual),
                onVerDetalle: () => _verDetalle(context, actual),
              ),
            if (proximos.isNotEmpty) ...[
              const SizedBox(height: EspaciadoCampo.xxl),
              Semantics(
                header: true,
                child: Text('Próximos', style: texto.titleLarge),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              for (final s in proximos) ...[
                _FilaServicio(
                  servicio: s,
                  onTap: () => _verDetalle(context, s),
                ),
                const SizedBox(height: EspaciadoCampo.s),
              ],
            ],
            if (cerrados.isNotEmpty) ...[
              const SizedBox(height: EspaciadoCampo.xxl),
              Semantics(
                header: true,
                child: Text('Terminados', style: texto.titleLarge),
              ),
              const SizedBox(height: EspaciadoCampo.m),
              for (final s in cerrados) ...[
                _FilaServicio(
                  servicio: s,
                  onTap: () => _verDetalle(context, s),
                ),
                const SizedBox(height: EspaciadoCampo.s),
              ],
            ],
          ],
        );
      },
    );
  }
}

/// El servicio en el que el piloto trabaja ahora: lote, estado, avance y
/// las dos acciones — abrir la sesión de vuelo (principal) y ver el
/// detalle.
class _ServicioVigente extends StatelessWidget {
  const _ServicioVigente({
    required this.servicio,
    required this.onAbrirSesion,
    required this.onVerDetalle,
  });

  final Servicio servicio;
  final VoidCallback onAbrirSesion;
  final VoidCallback onVerDetalle;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final cubiertas = FormatoMarketplace.hectareas(servicio.hectareasCubiertas);
    final declaradas = FormatoMarketplace.hectareas(
      servicio.hectareasDeclaradas,
    );
    return SuperficieMarketplace(
      key: const Key('servicio_vigente'),
      resaltada: true,
      radio: 24,
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InsigniaEstadoServicio(servicio.estado),
          ),
          const SizedBox(height: EspaciadoCampo.m),
          Text(servicio.lote.nombre, style: texto.headlineSmall),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            '${servicio.lote.zona} · ${servicio.producto}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          Semantics(
            label: 'Hectáreas cubiertas: $cubiertas de $declaradas',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HECTÁREAS CUBIERTAS',
                  style: texto.labelSmall?.copyWith(
                    fontSize: 12,
                    color: paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.xs),
                // El dato protagonista se achica antes que cortarse con el
                // texto escalado.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    cubiertas,
                    style: texto.displaySmall?.copyWith(
                      color: paleta.acentoTexto,
                    ),
                  ),
                ),
                Text(
                  'de $declaradas',
                  style: texto.bodyMedium?.copyWith(
                    color: paleta.textoSecundario,
                  ),
                ),
                const SizedBox(height: EspaciadoCampo.m),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: servicio.progreso,
                    minHeight: 10,
                    backgroundColor: paleta.borde,
                    color: paleta.acentoTexto,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EspaciadoCampo.xl),
          BotonPrimarioCampo(
            key: const Key('boton_abrir_sesion_vuelo'),
            icono: Icons.flight_takeoff_rounded,
            texto: servicio.estado == EstadoServicio.enEjecucion
                ? 'Abrir sesión de vuelo'
                : 'Iniciar servicio',
            onPressed: onAbrirSesion,
          ),
          const SizedBox(height: EspaciadoCampo.m),
          BotonSecundarioCampo(
            key: const Key('boton_ver_detalle'),
            icono: Icons.map_outlined,
            texto: 'Ver detalle',
            onPressed: onVerDetalle,
          ),
        ],
      ),
    );
  }
}

/// Lo que se ve cuando todos los servicios asignados ya terminaron.
class _SinServicioVigente extends StatelessWidget {
  const _SinServicioVigente();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return SuperficieMarketplace(
      key: const Key('sin_servicio_vigente'),
      radio: 24,
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.task_alt_rounded, size: 32, color: paleta.exito),
          const SizedBox(height: EspaciadoCampo.m),
          Text('Sin servicio en curso', style: texto.headlineSmall),
          const SizedBox(height: EspaciadoCampo.xs),
          Text(
            'Terminaste lo asignado. Las ofertas nuevas llegan a la bandeja.',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ),
    );
  }
}

/// Un servicio en la lista: lote, zona, superficie, fecha y estado. Toda la
/// fila es tocable y mide al menos 56 px.
class _FilaServicio extends StatelessWidget {
  const _FilaServicio({required this.servicio, required this.onTap});

  final Servicio servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return SuperficieMarketplace(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ObjetivoTactilCampo.guantes - EspaciadoCampo.xl,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(servicio.lote.nombre, style: texto.titleMedium),
                  const SizedBox(height: EspaciadoCampo.xs),
                  Text(
                    '${servicio.lote.zona} · '
                    '${FormatoMarketplace.hectareas(servicio.hectareasDeclaradas)} · '
                    '${FormatoMarketplace.fechaCorta(servicio.fechaDeseada)}',
                    style: texto.bodyMedium?.copyWith(
                      color: paleta.textoSecundario,
                    ),
                  ),
                  if (!servicio.estado.activo) ...[
                    const SizedBox(height: EspaciadoCampo.s),
                    InsigniaEstadoServicio(servicio.estado),
                  ],
                ],
              ),
            ),
            const SizedBox(width: EspaciadoCampo.m),
            Icon(Icons.chevron_right_rounded, color: paleta.textoSecundario),
          ],
        ),
      ),
    );
  }
}
