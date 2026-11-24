import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/estado_sync/presentation/indicador_sync.dart';
import '../../../nucleo/marketplace/demo/recorrido_demo.dart';
import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../domain/servicio_asignado_repositorio.dart';
import 'abrir_sesion_de_vuelo.dart';

/// Detalle de un servicio asignado: el lote en el mapa, lo que hay que
/// aplicar y con qué, y la acción principal anclada abajo. Lee del
/// repositorio local, así que se actualiza sola cuando una sesión cierra y
/// suma hectáreas.
class ServicioDetallePantalla extends StatelessWidget {
  const ServicioDetallePantalla({required this.servicioId, super.key});

  final String servicioId;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    return Scaffold(
      backgroundColor: paleta.fondo,
      body: SafeArea(
        bottom: false,
        child: StreamEstable<List<Servicio>>(
          crear: () => context.read<ServicioAsignadoRepositorio>().observar(),
          builder: (context, snap) {
            final lista = snap.data;
            Servicio? servicio;
            for (final s in lista ?? const <Servicio>[]) {
              if (s.id == servicioId) servicio = s;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margen,
                    EspaciadoCampo.s,
                    margen,
                    0,
                  ),
                  child: EncabezadoCampo(
                    titulo: servicio?.lote.nombre ?? 'Servicio',
                    subtitulo: servicio?.lote.zona,
                  ),
                ),
                if (lista != null && servicio == null)
                  const Expanded(
                    child: EstadoVacioMarketplace(
                      icono: Icons.search_off_rounded,
                      titulo: 'Este servicio ya no está asignado',
                      detalle: 'Volvé a «Mis servicios» para ver los vigentes.',
                    ),
                  )
                else if (servicio != null) ...[
                  Expanded(child: _Contenido(servicio: servicio)),
                  BarraAccionesCampo(
                    principal: servicio.estado.activo
                        ? BotonPrimarioCampo(
                            key: const Key('detalle_abrir_sesion_vuelo'),
                            icono: Icons.flight_takeoff_rounded,
                            texto: servicio.estado == EstadoServicio.enEjecucion
                                ? 'Abrir sesión de vuelo'
                                : 'Iniciar servicio',
                            onPressed: () =>
                                abrirSesionDeVuelo(context, servicio!),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: EspaciadoCampo.s,
                            ),
                            child: NotaInlineCampo(
                              key: const Key('detalle_servicio_terminado'),
                              texto: servicio.estado.etiqueta,
                              color: servicio.estado == EstadoServicio.cancelado
                                  ? paleta.error
                                  : paleta.exito,
                              centrada: true,
                            ),
                          ),
                  ),
                ] else
                  const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.servicio});

  final Servicio servicio;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final margen = EspaciadoCampo.margenLateral(
      MediaQuery.sizeOf(context).width,
    );
    final recorrido = RecorridoDemo.paraLote(servicio.lote);
    final dron = servicio.dron;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        margen,
        EspaciadoCampo.m,
        margen,
        EspaciadoCampo.xl,
      ),
      children: [
        Wrap(
          spacing: EspaciadoCampo.s,
          runSpacing: EspaciadoCampo.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InsigniaEstadoServicio(servicio.estado),
            const IndicadorSync(),
          ],
        ),
        const SizedBox(height: EspaciadoCampo.l),
        Semantics(
          label: 'Mapa del lote ${servicio.lote.nombre}',
          image: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              child: MapaLote(
                lotes: [servicio.lote],
                seleccionado: servicio.lote,
                posicionDron: servicio.estado == EstadoServicio.enEjecucion
                    ? recorrido.en(servicio.progreso)
                    : null,
                trazado: recorrido.trazadoHasta(servicio.progreso),
                interactivo: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        GrupoStatsCampo(
          children: [
            StatChipCampo(
              key: const Key('detalle_hectareas'),
              etiqueta: 'Superficie',
              valor: FormatoMarketplace.numero(servicio.hectareasDeclaradas),
              unidad: 'ha',
            ),
            StatChipCampo(
              key: const Key('detalle_dosis'),
              etiqueta: 'Dosis',
              valor: FormatoMarketplace.numero(
                servicio.dosisLitrosPorHectarea,
                decimales: 1,
              ),
              unidad: 'L/ha',
            ),
            StatChipCampo(
              key: const Key('detalle_caldo'),
              etiqueta: 'Caldo',
              valor: FormatoMarketplace.numero(
                servicio.litrosTotales,
                decimales: 1,
              ),
              unidad: 'L',
            ),
          ],
        ),
        const SizedBox(height: EspaciadoCampo.l),
        SuperficieMarketplace(
          child: Column(
            children: [
              _Fila('Producto', servicio.producto),
              _Fila('Cultivo', servicio.lote.cultivo),
              _Fila(
                'Cubierto',
                '${FormatoMarketplace.hectareas(servicio.hectareasCubiertas)} '
                    'de ${FormatoMarketplace.hectareas(servicio.hectareasDeclaradas)}',
              ),
              _Fila('Cliente', servicio.clienteNombre),
              if (dron != null)
                _Fila('Dron', '${dron.modelo} · ${dron.matricula}'),
              _Fila(
                'Fecha',
                FormatoMarketplace.fechaLarga(servicio.fechaDeseada),
              ),
              _Fila(
                'Pago',
                FormatoMarketplace.bs(servicio.precio),
                ultimo: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: EspaciadoCampo.l),
        Text(
          'El detalle se lee del dispositivo: está disponible sin señal.',
          style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
        ),
      ],
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
