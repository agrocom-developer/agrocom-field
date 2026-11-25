import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../dominio/dominio.dart';
import '../../../foto_perfil/presentation/foto_perfil_widgets.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/perfil_repositorio.dart';
import 'perfil_cubit.dart';
import 'perfil_estado.dart';

/// Perfil del proveedor: quién es y si está habilitado para operar, sus
/// métricas, documentos, equipo y lo que los clientes dijeron de su trabajo.
/// Es el mismo en los flavors `piloto`.
class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({
    this.reloj = DateTime.now,
    this.onVerDrones,
    this.extras = const [],
    super.key,
  });

  final DateTime Function() reloj;

  /// Abre «Mis drones». Sin él la fila no se muestra (el flavor ya los
  /// tiene como destino de la navegación).
  final VoidCallback? onVerDrones;

  /// Filas propias del flavor (avisos, cerrar sesión) que se muestran
  /// después de las métricas.
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PerfilCubit(context.read<PerfilRepositorio>())..cargar(),
      child: PerfilVista(
        reloj: reloj,
        onVerDrones: onVerDrones,
        extras: extras,
      ),
    );
  }
}

/// El perfil sobre un [PerfilCubit] ya provisto.
class PerfilVista extends StatelessWidget {
  const PerfilVista({
    this.reloj = DateTime.now,
    this.onVerDrones,
    this.extras = const [],
    super.key,
  });

  final DateTime Function() reloj;
  final VoidCallback? onVerDrones;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerfilCubit, PerfilEstado>(
      builder: (context, estado) {
        return AnimatedSwitcher(
          duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
          switchInCurve: MovimientoCampo.entrada,
          switchOutCurve: MovimientoCampo.salida,
          child: switch (estado) {
            PerfilCargando() => const _Cargando(key: ValueKey('cargando')),
            PerfilError() => EstadoErrorMarketplace(
              key: const ValueKey('error'),
              titulo: AppLocalizations.of(context).perfilProveedorErrorTitulo,
              detalle: AppLocalizations.of(context).perfilProveedorErrorDetalle,
              onReintentar: context.read<PerfilCubit>().cargar,
            ),
            PerfilListo() => _Contenido(
              key: const ValueKey('listo'),
              datos: estado,
              ahora: reloj(),
              onVerDrones: onVerDrones,
              extras: extras,
            ),
          },
        );
      },
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(EspaciadoCampo.l),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        Row(
          children: [
            EsqueletoCampo(ancho: 64, alto: 64, radio: 32),
            SizedBox(width: EspaciadoCampo.l),
            Expanded(child: EsqueletoCampo(alto: 56)),
          ],
        ),
        SizedBox(height: EspaciadoCampo.xl),
        EsqueletoCampo(alto: 72, radio: 18),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 160, radio: 18),
        SizedBox(height: EspaciadoCampo.l),
        EsqueletoCampo(alto: 200, radio: 18),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.datos,
    required this.ahora,
    required this.onVerDrones,
    required this.extras,
    super.key,
  });

  final PerfilListo datos;
  final DateTime ahora;
  final VoidCallback? onVerDrones;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    final p = datos.proveedor;
    final texto = Theme.of(context).textTheme;
    final t = AppLocalizations.of(context);
    final conAccion = p.documentosConAccion;
    return FotoPerfilProveedor(
      urlInicial: p.fotoUrl,
      child: ListView(
        padding: const EdgeInsets.all(EspaciadoCampo.l),
        children: [
          Row(
            children: [
              AvatarFotoPerfil(
                iniciales: p.iniciales,
                nombre: p.nombre,
                tamano: 64,
              ),
              const SizedBox(width: EspaciadoCampo.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: texto.titleLarge),
                    const SizedBox(height: EspaciadoCampo.xs),
                    Text(
                      '${t.perfilProveedorRolPiloto} · ${p.tipo.etiqueta}',
                      style: texto.bodyMedium,
                    ),
                    const SizedBox(height: EspaciadoCampo.xs),
                    if (datos.calificaciones.total == 0)
                      Text(
                        t.perfilProveedorSinCalificaciones,
                        style: texto.bodyMedium,
                      )
                    else
                      CalificacionPromedio(
                        valor: p.calificacion,
                        detalle: t.perfilProveedorServicios(
                          p.serviciosCompletados,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.s),
          const AccionesFotoPerfil(),
          const SizedBox(height: EspaciadoCampo.m),
          _Aprobacion(proveedor: p),
          if (conAccion.isNotEmpty && p.aprobacion.habilitado) ...[
            const SizedBox(height: EspaciadoCampo.m),
            AvisoMarketplace(
              key: const Key('perfil-documentos-accion'),
              tono: TonoAviso.alerta,
              mensaje: conAccion.length == 1
                  ? t.perfilProveedorDocumentoAtencion(conAccion.first.nombre)
                  : t.perfilProveedorDocumentosAtencion(conAccion.length),
            ),
          ],
          _Titulo(t.perfilProveedorMetricas),
          _Metricas(metricas: datos.metricas),
          _Titulo(t.perfilProveedorAjustes),
          for (final e in extras) ...[
            const SizedBox(height: EspaciadoCampo.m),
            e,
          ],
          if (onVerDrones != null) ...[
            const SizedBox(height: EspaciadoCampo.m),
            SuperficieMarketplace(
              key: const Key('perfil-ver-drones'),
              onTap: onVerDrones,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: ObjetivoTactilCampo.guantes - EspaciadoCampo.xxl,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flight_rounded,
                      color: context.paleta.acentoTexto,
                    ),
                    const SizedBox(width: EspaciadoCampo.m),
                    Expanded(
                      child: Text(
                        '${t.perfilProveedorDronLicencia} · '
                        '${p.drones.length == 1 ? t.perfilProveedorDronesUno : t.perfilProveedorDronesVarios(p.drones.length)}',
                        style: texto.titleLarge,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.paleta.textoSecundario,
                    ),
                  ],
                ),
              ),
            ),
          ],
          _Titulo(t.perfilProveedorHectareasMes),
          if (datos.hectareasPorMes.every((m) => m.hectareas.sign <= 0))
            Text(t.perfilProveedorHectareasMesVacio, style: texto.bodyMedium)
          else
            SuperficieMarketplace(
              child: SizedBox(
                height: 180,
                child: _GraficoHectareas(meses: datos.hectareasPorMes),
              ),
            ),
          _Titulo(t.perfilProveedorDocumentos),
          if (p.documentos.isEmpty)
            Text(t.perfilProveedorDocumentosVacio, style: texto.bodyMedium),
          for (final doc in p.documentos) ...[
            _FilaDocumento(documento: doc),
            const SizedBox(height: EspaciadoCampo.s),
          ],
          _Titulo(t.perfilProveedorZonas),
          Wrap(
            spacing: EspaciadoCampo.s,
            runSpacing: EspaciadoCampo.s,
            children: [
              for (final z in p.zonas)
                ChipEstadoMarketplace(
                  etiqueta: z,
                  etiquetaSemantica: t.perfilProveedorZonaSemantica(z),
                  tono: TonoEstado.neutro,
                  icono: Icons.place_outlined,
                ),
            ],
          ),
          _Titulo(t.perfilProveedorCalificaciones),
          _ResumenCalificaciones(resumen: datos.calificaciones),
          const SizedBox(height: EspaciadoCampo.m),
          if (datos.calificaciones.recientes.isEmpty)
            Text(t.perfilProveedorResenasVacio, style: texto.bodyMedium),
          for (final c in datos.calificaciones.recientes) ...[
            _Resena(calificacion: c, ahora: ahora),
            const SizedBox(height: EspaciadoCampo.s),
          ],
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: EspaciadoCampo.xl,
        bottom: EspaciadoCampo.m,
      ),
      child: Semantics(
        header: true,
        child: Text(texto, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}

/// Estado de aprobación del proveedor, con lo que significa para operar.
class _Aprobacion extends StatelessWidget {
  const _Aprobacion({required this.proveedor});

  final Proveedor proveedor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final (tono, icono, detalle) = switch (proveedor.aprobacion) {
      EstadoAprobacion.aprobado => (
        TonoEstado.exito,
        Icons.verified_rounded,
        'Estás habilitado para recibir ofertas.',
      ),
      EstadoAprobacion.pendiente => (
        TonoEstado.info,
        Icons.hourglass_top_rounded,
        'Un administrador está revisando tus datos. Te avisamos cuando '
            'puedas recibir ofertas.',
      ),
      EstadoAprobacion.suspendido => (
        TonoEstado.alerta,
        Icons.pause_circle_outline_rounded,
        'No recibís ofertas mientras dure la suspensión.',
      ),
      EstadoAprobacion.rechazado => (
        TonoEstado.error,
        Icons.cancel_outlined,
        'Tu solicitud no se aprobó. Podés corregir los datos y reenviarla.',
      ),
    };
    final motivo = proveedor.motivoAprobacion;
    return SuperficieMarketplace(
      key: const Key('perfil-aprobacion'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipEstadoMarketplace(
            etiqueta: proveedor.aprobacion.etiqueta,
            tono: tono,
            icono: icono,
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(detalle, style: texto.bodyLarge),
          if (motivo != null && !proveedor.aprobacion.habilitado) ...[
            const SizedBox(height: EspaciadoCampo.xs),
            Text('Motivo: $motivo', style: texto.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _Metricas extends StatelessWidget {
  const _Metricas({required this.metricas});

  final MetricasProveedor metricas;

  @override
  Widget build(BuildContext context) {
    final celdas = [
      _Metrica(
        etiqueta: 'SERVICIOS',
        valor: '${metricas.serviciosCompletados}',
      ),
      _Metrica(
        etiqueta: 'HECTÁREAS',
        valor: FormatoMarketplace.numero(
          metricas.hectareasAtendidas,
          decimales: 0,
        ),
      ),
      _Metrica(etiqueta: 'CANCELACIÓN', valor: '${metricas.tasaCancelacion} %'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        // Dos por fila; con el texto al 200 % cada métrica ocupa la suya.
        final grande = MediaQuery.textScalerOf(context).scale(10) > 15;
        final ancho = grande ? c.maxWidth : (c.maxWidth - EspaciadoCampo.m) / 2;
        return Wrap(
          spacing: EspaciadoCampo.m,
          runSpacing: EspaciadoCampo.m,
          children: [
            for (final celda in celdas) SizedBox(width: ancho, child: celda),
          ],
        );
      },
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return MergeSemantics(
      child: SuperficieMarketplace(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: texto.labelSmall),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(valor, style: texto.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _FilaDocumento extends StatelessWidget {
  const _FilaDocumento({required this.documento});

  final DocumentoProveedor documento;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final (tono, icono) = switch (documento.estado) {
      EstadoDocumento.vigente => (TonoEstado.exito, Icons.verified_rounded),
      EstadoDocumento.porVencer => (TonoEstado.alerta, Icons.schedule_rounded),
      EstadoDocumento.enRevision => (
        TonoEstado.info,
        Icons.hourglass_top_rounded,
      ),
      EstadoDocumento.rechazado => (TonoEstado.error, Icons.cancel_outlined),
      EstadoDocumento.vencido => (TonoEstado.error, Icons.event_busy_outlined),
    };
    final vence = documento.vence;
    final motivo = documento.motivoRechazo;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(documento.nombre, style: texto.titleLarge),
          const SizedBox(height: EspaciadoCampo.s),
          Wrap(
            spacing: EspaciadoCampo.m,
            runSpacing: EspaciadoCampo.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChipEstadoMarketplace(
                etiqueta: documento.estado.etiqueta,
                tono: tono,
                icono: icono,
              ),
              if (vence != null)
                Text(
                  documento.estado == EstadoDocumento.vencido
                      ? 'Venció el ${FormatoMarketplace.fechaLarga(vence)}'
                      : 'Vence el ${FormatoMarketplace.fechaLarga(vence)}',
                  style: texto.bodyMedium,
                ),
            ],
          ),
          if (motivo != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Text('Motivo: $motivo', style: texto.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Promedio en grande y cuántas calificaciones hay de cada puntaje.
class _ResumenCalificaciones extends StatelessWidget {
  const _ResumenCalificaciones({required this.resumen});

  final ResumenCalificaciones resumen;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final promedio = resumen.promedio.toStringAsFixed(1).replaceAll('.', ',');
    final mayor = resumen.porPuntaje.values.fold<int>(
      0,
      (a, b) => a > b ? a : b,
    );
    return SuperficieMarketplace(
      key: const Key('perfil-calificaciones'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label:
                'Calificación promedio $promedio de 5, sobre '
                '${resumen.total} calificaciones',
            excludeSemantics: true,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: EspaciadoCampo.m,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 32, color: paleta.alerta),
                    const SizedBox(width: EspaciadoCampo.xs),
                    Text(promedio, style: texto.displaySmall),
                  ],
                ),
                Text(
                  resumen.total == 1
                      ? '1 calificación'
                      : '${resumen.total} calificaciones',
                  style: texto.bodyLarge,
                ),
              ],
            ),
          ),
          if (mayor > 0) ...[
            const SizedBox(height: EspaciadoCampo.m),
            for (var puntaje = 5; puntaje >= 1; puntaje--)
              _BarraPuntaje(
                puntaje: puntaje,
                cantidad: resumen.porPuntaje[puntaje] ?? 0,
                mayor: mayor,
              ),
          ],
        ],
      ),
    );
  }
}

class _BarraPuntaje extends StatelessWidget {
  const _BarraPuntaje({
    required this.puntaje,
    required this.cantidad,
    required this.mayor,
  });

  final int puntaje;
  final int cantidad;
  final int mayor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final escala = MediaQuery.textScalerOf(context);
    return Semantics(
      container: true,
      label:
          '$puntaje ${puntaje == 1 ? 'estrella' : 'estrellas'}: '
          '$cantidad',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: EspaciadoCampo.xs),
        child: Row(
          children: [
            SizedBox(
              width: escala.scale(14),
              child: Text('$puntaje', style: texto.bodyMedium),
            ),
            Icon(Icons.star_rounded, size: 14, color: paleta.textoSecundario),
            const SizedBox(width: EspaciadoCampo.s),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RadioCampo.capsula),
                child: LinearProgressIndicator(
                  value: cantidad / mayor,
                  minHeight: 8,
                  backgroundColor: paleta.borde,
                  color: paleta.acentoTexto,
                ),
              ),
            ),
            const SizedBox(width: EspaciadoCampo.s),
            SizedBox(
              width: escala.scale(32),
              child: Text(
                '$cantidad',
                style: texto.bodyMedium,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resena extends StatelessWidget {
  const _Resena({required this.calificacion, required this.ahora});

  final CalificacionRecibida calificacion;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final comentario = calificacion.comentario;
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(calificacion.autor, style: texto.titleLarge),
          const SizedBox(height: EspaciadoCampo.xs),
          Wrap(
            spacing: EspaciadoCampo.m,
            runSpacing: EspaciadoCampo.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CalificacionCampo(valor: calificacion.puntaje, tamano: 18),
              Text(
                FormatoMarketplace.hace(calificacion.fecha, ahora),
                style: texto.bodyMedium,
              ),
            ],
          ),
          if (comentario != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            Text(comentario, style: texto.bodyLarge),
          ],
        ],
      ),
    );
  }
}

class _GraficoHectareas extends StatelessWidget {
  const _GraficoHectareas({required this.meses});

  final List<HectareasMensuales> meses;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final estilo = Theme.of(context).textTheme.labelSmall;
    // Conversión a `double` solo para dibujar la barra: el valor mostrado
    // sigue siendo el `Decimal` (ADR 0002).
    final altos = [for (final m in meses) m.hectareas.toDouble()];
    return Semantics(
      container: true,
      label:
          'Gráfico de barras de hectáreas por mes: ${[for (final m in meses) '${m.etiqueta} ${FormatoMarketplace.hectareas(m.hectareas)}'].join(', ')}',
      child: ExcludeSemantics(
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (altos.fold<double>(0, (a, b) => a > b ? a : b) * 1.15),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: MediaQuery.textScalerOf(context).scale(24),
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(meses[v.toInt()].etiqueta, style: estilo),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < altos.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: altos[i],
                      width: 22,
                      color: i == altos.length - 1
                          ? paleta.acentoTexto
                          : paleta.acentoTexto.withValues(alpha: 0.45),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(RadioCampo.xs),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
