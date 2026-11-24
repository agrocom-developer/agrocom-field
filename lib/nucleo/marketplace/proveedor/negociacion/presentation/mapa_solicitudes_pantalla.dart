import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/campo_formulario_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../di/dependencias_negociacion.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'mapa_solicitudes.dart';
import 'mapa_solicitudes_cubit.dart';
import 'pedir_precio_hoja.dart';
import 'solicitud_detalle_pantalla.dart';

/// La pestaña «Mapa» del piloto: las solicitudes abiertas de Santa Cruz en
/// un mapa, con filtros por zona, hectáreas y precio, un resumen por zona
/// (valles frente a Chiquitania) y la lista debajo.
class MapaSolicitudesPantalla extends StatelessWidget {
  const MapaSolicitudesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MapaSolicitudesCubit(
        context.read<MercadoRepositorio>(),
        avisador: context.read<DependenciasNegociacion>().avisador,
      )..cargar(),
      child: const MapaSolicitudesVista(),
    );
  }
}

class MapaSolicitudesVista extends StatelessWidget {
  const MapaSolicitudesVista({super.key});

  Future<void> _abrir(BuildContext context, SolicitudAbierta s) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SolicitudDetallePantalla(solicitud: s),
      ),
    );
    if (context.mounted) context.read<MapaSolicitudesCubit>().cargar();
  }

  Future<void> _filtrar(BuildContext context) async {
    final cubit = context.read<MapaSolicitudesCubit>();
    final nuevos = await showModalBottomSheet<FiltrosMapa>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaFiltros(inicial: cubit.state.filtros),
    );
    if (nuevos != null) cubit.aplicarFiltros(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return BlocBuilder<MapaSolicitudesCubit, MapaSolicitudesEstado>(
      builder: (context, estado) {
        final cubit = context.read<MapaSolicitudesCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EspaciadoCampo.l,
                EspaciadoCampo.l,
                EspaciadoCampo.l,
                EspaciadoCampo.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Solicitudes abiertas',
                      style: texto.headlineMedium,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: estado.filtros.hayFiltros
                        ? 'Filtros, hay filtros aplicados'
                        : 'Filtros',
                    constraints: const BoxConstraints.tightFor(
                      width: ObjetivoTactilCampo.guantes,
                      height: ObjetivoTactilCampo.guantes,
                    ),
                    onPressed: () => _filtrar(context),
                    icon: Badge(
                      isLabelVisible: estado.filtros.hayFiltros,
                      child: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ],
              ),
            ),
            _FranjaZonas(
              seleccionada: estado.filtros.macrorregion,
              alElegir: (m) => cubit.aplicarFiltros(
                estado.filtros.copiarCon(macrorregion: () => m),
              ),
            ),
            // El mapa se achica antes que la lista: con texto grande el
            // encabezado ocupa más y la lista sigue a la vista.
            Flexible(
              flex: 2,
              child: MapaSolicitudes(
                solicitudes: estado.solicitudes,
                seleccionada: estado.seleccionada,
                alSeleccionar: (s) => estado.seleccionada == s.id
                    ? _abrir(context, s)
                    : cubit.seleccionar(s.id),
              ),
            ),
            Expanded(
              flex: 3,
              child: _Cuerpo(estado: estado, alAbrir: _abrir),
            ),
          ],
        );
      },
    );
  }
}

class _FranjaZonas extends StatelessWidget {
  const _FranjaZonas({required this.seleccionada, required this.alElegir});

  final Macrorregion? seleccionada;
  final ValueChanged<Macrorregion?> alElegir;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ObjetivoTactilCampo.guantes + EspaciadoCampo.s,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EspaciadoCampo.l),
        children: [
          _Opcion(
            etiqueta: 'Todas',
            activa: seleccionada == null,
            alToque: () => alElegir(null),
          ),
          // Valles y Chiquitania primero: es la decisión que más se toma.
          for (final m in Macrorregion.ordenDeMapa)
            _Opcion(
              etiqueta: m.etiqueta,
              activa: seleccionada == m,
              alToque: () => alElegir(m),
            ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.etiqueta,
    required this.activa,
    required this.alToque,
  });

  final String etiqueta;
  final bool activa;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: EspaciadoCampo.s),
      child: Semantics(
        button: true,
        selected: activa,
        label: 'Zona $etiqueta${activa ? ', elegida' : ''}',
        excludeSemantics: true,
        child: ChoiceChip(
          label: Text(etiqueta),
          selected: activa,
          showCheckmark: true,
          onSelected: (_) => alToque(),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
        ),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado, required this.alAbrir});

  final MapaSolicitudesEstado estado;
  final Future<void> Function(BuildContext, SolicitudAbierta) alAbrir;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MapaSolicitudesCubit>();
    switch (estado.estado) {
      case EstadoMapa.cargando:
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: const [
            EsqueletoCampo(alto: 120, radio: 18),
            SizedBox(height: EspaciadoCampo.m),
            EsqueletoCampo(alto: 120, radio: 18),
          ],
        );
      case EstadoMapa.sinRed:
        // En una lista: con poco alto y texto grande el estado se desplaza.
        return ListView(
          children: [
            EstadoErrorMarketplace(
              titulo: 'Sin conexión',
              detalle:
                  'El mapa de solicitudes necesita señal: es una competencia '
                  'entre pilotos. Reintenta cuando la tengas.',
              onReintentar: cubit.cargar,
            ),
          ],
        );
      case EstadoMapa.error:
        return ListView(
          children: [
            EstadoErrorMarketplace(
              titulo: 'No pudimos cargar las solicitudes',
              detalle: estado.mensaje ?? 'Intenta de nuevo en un momento.',
              onReintentar: cubit.cargar,
            ),
          ],
        );
      case EstadoMapa.listo:
        if (estado.solicitudes.isEmpty) {
          return RefreshIndicator(
            onRefresh: cubit.cargar,
            child: ListView(
              children: [
                EstadoVacioMarketplace(
                  icono: Icons.map_outlined,
                  titulo: estado.filtros.hayFiltros
                      ? 'Ninguna solicitud con estos filtros'
                      : 'No hay solicitudes abiertas ahora',
                  detalle: estado.filtros.hayFiltros
                      ? 'Quita algún filtro o prueba con otra zona.'
                      : 'Activa los avisos en Perfil y te decimos cuando '
                            'llegue una en tus zonas.',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: cubit.cargar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              EspaciadoCampo.l,
              EspaciadoCampo.s,
              EspaciadoCampo.l,
              EspaciadoCampo.xl,
            ),
            children: [
              if (estado.zonas.isNotEmpty) ...[
                _ResumenZonas(zonas: estado.zonas),
                const SizedBox(height: EspaciadoCampo.m),
              ],
              for (final s in estado.solicitudes) ...[
                _TarjetaSolicitud(
                  solicitud: s,
                  resaltada: s.id == estado.seleccionada,
                  alToque: () => alAbrir(context, s),
                ),
                const SizedBox(height: EspaciadoCampo.m),
              ],
              if (estado.hayMas)
                OutlinedButton(
                  onPressed: estado.cargandoMas ? null : cubit.cargarMas,
                  child: Text(
                    estado.cargandoMas ? 'Cargando…' : 'Ver más solicitudes',
                  ),
                ),
            ],
          ),
        );
    }
  }
}

class _ResumenZonas extends StatelessWidget {
  const _ResumenZonas({required this.zonas});

  final List<ResumenZona> zonas;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    final porMacro = <Macrorregion?, List<ResumenZona>>{};
    for (final z in zonas) {
      porMacro.putIfAbsent(z.macrorregion, () => []).add(z);
    }
    return SuperficieMarketplace(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dónde hay trabajo', style: texto.titleMedium),
          const SizedBox(height: EspaciadoCampo.s),
          for (final e in porMacro.entries) ...[
            Semantics(
              container: true,
              label:
                  '${e.key?.etiqueta ?? 'Otras zonas'}: '
                  '${e.value.fold(0, (a, z) => a + z.solicitudes)} solicitudes, '
                  '${FormatoMarketplace.hectareas(e.value.fold(Decimal.zero, (a, z) => a + z.hectareas))}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                // `Wrap` y no `Row`: con texto grande la cifra baja de renglón.
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: EspaciadoCampo.m,
                  children: [
                    Text(
                      e.key?.etiqueta ?? 'Otras zonas',
                      style: texto.bodyLarge,
                    ),
                    Text(
                      '${e.value.fold(0, (a, z) => a + z.solicitudes)} · '
                      '${FormatoMarketplace.hectareas(e.value.fold(Decimal.zero, (a, z) => a + z.hectareas))}',
                      style: texto.bodyLarge?.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({
    required this.solicitud,
    required this.resaltada,
    required this.alToque,
  });

  final SolicitudAbierta solicitud;
  final bool resaltada;
  final VoidCallback alToque;

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final texto = Theme.of(context).textTheme;
    final paleta = context.paleta;
    return Semantics(
      button: true,
      label:
          'Solicitud en ${s.zona ?? 'zona sin nombre'}, '
          '${FormatoMarketplace.hectareas(s.hectareas)}, '
          '${FormatoMarketplace.bs(s.precioHaPropuesto)} por hectárea, '
          '${s.ofertasVigentes} ofertas',
      excludeSemantics: true,
      child: SuperficieMarketplace(
        onTap: alToque,
        resaltada: resaltada,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${FormatoMarketplace.hectareas(s.hectareas)}'
              '${s.cultivo == null ? '' : ' · ${s.cultivo}'}',
              style: texto.titleLarge,
            ),
            if (s.miNegociacion != MiNegociacion.ninguna) ...[
              const SizedBox(height: EspaciadoCampo.xs),
              ChipEstadoMarketplace(
                etiqueta: s.miNegociacion == MiNegociacion.vigente
                    ? 'Ofertaste'
                    : 'Cerrada',
                tono: s.miNegociacion == MiNegociacion.vigente
                    ? TonoEstado.info
                    : TonoEstado.neutro,
                icono: s.miNegociacion == MiNegociacion.vigente
                    ? Icons.handshake_rounded
                    : Icons.lock_outline_rounded,
              ),
            ],
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              [?s.zona, ?s.macrorregion?.etiqueta].join(' · '),
              style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
            ),
            const SizedBox(height: EspaciadoCampo.s),
            Text(
              '${FormatoMarketplace.bs(s.precioHaPropuesto)} por ha · '
              'total ${FormatoMarketplace.bs(s.montoPropuesto)}',
              style: texto.titleMedium,
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Text(
              [
                if (s.ventanaDesde != null)
                  'Desde ${FormatoMarketplace.fechaConDia(s.ventanaDesde!)}',
                s.ofertasVigentes == 0
                    ? 'Sin ofertas'
                    : '${s.ofertasVigentes} '
                          '${s.ofertasVigentes == 1 ? 'oferta' : 'ofertas'}',
                if (s.distanciaKm != null)
                  FormatoMarketplace.kilometros(s.distanciaKm!),
              ].join(' · '),
              style: texto.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _HojaFiltros extends StatefulWidget {
  const _HojaFiltros({required this.inicial});

  final FiltrosMapa inicial;

  @override
  State<_HojaFiltros> createState() => _HojaFiltrosState();
}

class _HojaFiltrosState extends State<_HojaFiltros> {
  late final _haMin = TextEditingController(
    text: widget.inicial.hectareasMin?.toString() ?? '',
  );
  late final _haMax = TextEditingController(
    text: widget.inicial.hectareasMax?.toString() ?? '',
  );
  late final _precioMin = TextEditingController(
    text: widget.inicial.precioHaMin?.toString() ?? '',
  );
  late final _precioMax = TextEditingController(
    text: widget.inicial.precioHaMax?.toString() ?? '',
  );
  late final _cultivo = TextEditingController(
    text: widget.inicial.cultivo ?? '',
  );
  late OrdenMapa _orden = widget.inicial.orden;

  @override
  void dispose() {
    for (final c in [_haMin, _haMax, _precioMin, _precioMax, _cultivo]) {
      c.dispose();
    }
    super.dispose();
  }

  void _aplicar() {
    final cultivo = _cultivo.text.trim();
    Navigator.pop(
      context,
      FiltrosMapa(
        macrorregion: widget.inicial.macrorregion,
        zonaId: widget.inicial.zonaId,
        hectareasMin: leerPrecio(_haMin.text),
        hectareasMax: leerPrecio(_haMax.text),
        precioHaMin: leerPrecio(_precioMin.text),
        precioHaMax: leerPrecio(_precioMax.text),
        cultivo: cultivo.isEmpty ? null : cultivo,
        orden: _orden,
      ),
    );
  }

  void _limpiar() => Navigator.pop(
    context,
    FiltrosMapa(macrorregion: widget.inicial.macrorregion),
  );

  Widget _par(
    String a,
    TextEditingController ca,
    String b,
    TextEditingController cb,
  ) => Row(
    children: [
      Expanded(child: _numero(a, ca)),
      const SizedBox(width: EspaciadoCampo.m),
      Expanded(child: _numero(b, cb)),
    ],
  );

  Widget _numero(String etiqueta, TextEditingController c) =>
      CampoFormularioMarketplace(
        etiqueta: etiqueta,
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      );

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          EspaciadoCampo.l,
          0,
          EspaciadoCampo.l,
          EspaciadoCampo.l + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtrar solicitudes', style: texto.titleLarge),
            const SizedBox(height: EspaciadoCampo.l),
            _par('Hectáreas desde', _haMin, 'Hectáreas hasta', _haMax),
            const SizedBox(height: EspaciadoCampo.m),
            _par('Bs por ha desde', _precioMin, 'Bs por ha hasta', _precioMax),
            const SizedBox(height: EspaciadoCampo.m),
            CampoFormularioMarketplace(
              etiqueta: 'Cultivo',
              controller: _cultivo,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: EspaciadoCampo.l),
            Text('Ordenar por', style: texto.titleMedium),
            const SizedBox(height: EspaciadoCampo.s),
            Wrap(
              spacing: EspaciadoCampo.s,
              children: [
                for (final o in OrdenMapa.values)
                  ChoiceChip(
                    label: Text(o.etiqueta),
                    selected: _orden == o,
                    onSelected: (_) => setState(() => _orden = o),
                  ),
              ],
            ),
            const SizedBox(height: EspaciadoCampo.xl),
            BotonPrincipalMarketplace(
              texto: 'Ver solicitudes',
              onPressed: _aplicar,
            ),
            const SizedBox(height: EspaciadoCampo.s),
            TextButton(
              onPressed: _limpiar,
              child: const Text('Quitar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
