import 'package:flutter/material.dart';

import '../../../nucleo/flavor.dart';
import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/imagenes_campo.dart';
import '../../../nucleo/ui/tema_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../sesion_vuelo/presentation/trabajo_cubit.dart';
import '../../sesion_vuelo/presentation/trabajo_estado.dart';
import '../../sesion_vuelo/presentation/sesion_vuelo_pantalla.dart';
import '../../sesion_vuelo/presentation/sesion_bloc.dart';
import '../../sesion_vuelo/domain/reglas_en_curso.dart';
import '../../sesion_vuelo/domain/trabajo_en_curso.dart';
import '../domain/orden_vigente.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detalle de una orden vigente — recibe el `OrdenVigente` ya cargado en
/// memoria desde la lista (`OrdenesVista`), sin volver a consultar
/// `drift`: no hace falta, la fila completa ya viajó por el `Stream` del
/// repositorio.
///
/// No deserializa `LoteCatalogo.geometria` (HU-61, mapa, fuera de
/// alcance). Agrega el botón "Abrir trabajo" (HU-05) — exclusivo del flavor
/// `piloto` — que navega a [SesionVueloPantalla] con el trabajo recién
/// abierto, propagándole también [crearIncidenciaCubit] (HU-08).
///
/// En modo campo (ADR 0008, decisión del 1/10/2026), con el lenguaje de la
/// pantalla 08 de la vista previa (`orden_detalle_campo_vitrina.dart`):
/// foto superior, badge de estado, tarjetas por sección y el CTA lima.
/// Muestra solo lo que expone [OrdenVigente] — un lote (no `lotes[]`, solo
/// cuántos más cubre la orden y las hectáreas de todos, TE-23), sin
/// los ítems de trabajo/sesión ni el contrato de la 08 —, y un valor nulo se
/// lee «sin datos», nunca se oculta ni se inventa. Los límites climáticos y
/// los parámetros de vuelo son los del trabajo asignado de la orden (tarea
/// 23, ver `OrdenesRepository`): sin trabajo asignado, «sin datos».
class OrdenDetallePantalla extends StatelessWidget {
  const OrdenDetallePantalla({
    required this.orden,
    required this.flavor,
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    super.key,
  });

  final OrdenVigente orden;
  final Flavor flavor;
  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;

  static const _sinDatos = 'sin datos';

  /// Pantalla de sesión de vuelo del trabajo [trabajoUuidCliente]: el
  /// recién abierto, o el que ya estaba en curso (tarea 28).
  void _abrirSesionVuelo(BuildContext context, String trabajoUuidCliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SesionVueloPantalla(
          crearBloc: () => crearSesionBloc(trabajoUuidCliente),
          crearTrabajoCubit: crearTrabajoCubit,
          crearIncidenciaCubit: crearIncidenciaCubit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El BlocProvider<TrabajoCubit> se arma solo para flavor piloto: el
    // BlocConsumer lo lee en su initState (eager, no en el tap del botón), así
    // que envolverlo también para auxiliar invocaría `crearTrabajoCubit` —que
    // en `main_auxiliar.dart` lanza `UnimplementedError`— apenas se navega al
    // detalle de una orden, aunque el botón "Abrir trabajo" ya esté oculto.
    if (flavor != Flavor.piloto) {
      return _construirScaffold(context, cargandoTrabajo: false);
    }

    return BlocProvider<TrabajoCubit>(
      create: (_) => crearTrabajoCubit(),
      child: BlocConsumer<TrabajoCubit, TrabajoEstado>(
        listener: (context, estado) {
          if (estado is TrabajoExitoso) {
            _abrirSesionVuelo(context, estado.trabajo.uuidCliente);
          }
          if (estado is TrabajoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(estado.mensaje),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, estadoTrabajo) {
          final cargandoTrabajo = estadoTrabajo is TrabajoCargando;
          return _construirScaffold(context, cargandoTrabajo: cargandoTrabajo);
        },
      ),
    );
  }

  Widget _construirScaffold(
    BuildContext context, {
    required bool cargandoTrabajo,
  }) {
    return Theme(
      data: AgrocomThemeCampo.construir(),
      child: Scaffold(
        backgroundColor: ColoresCampo.fondoProfundo,
        body: FondoFotoCampo(
          imagen: ImagenesCampo.dronPulverizandoVertical,
          cobertura: CoberturaFondoFoto.superior,
          altoSuperior: 320,
          alineacion: const Alignment(0, -0.3),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Row(
                    children: [
                      BotonCircularCampo(
                        icono: Icons.arrow_back,
                        tooltip: 'Volver',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Orden N.º ${orden.id}',
                          style: TipografiaCampo.tituloSeccion,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      BadgeEstadoCampo(
                        key: const Key('orden_estado'),
                        texto: orden.estado,
                        estado: orden.estado == 'vigente'
                            ? EstadoBadgeCampo.ok
                            : EstadoBadgeCampo.generico,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 120, 18, 12),
                    children: [
                      _tarjetaLote(),
                      const SizedBox(height: 12),
                      _tarjetaLimitesClimaticos(),
                      const SizedBox(height: 12),
                      _Seccion(
                        titulo: 'Parámetros de vuelo',
                        children: [
                          _fila('Altura de vuelo', orden.alturaVueloM, 'm'),
                          _fila(
                            'Velocidad de vuelo',
                            orden.velocidadVueloKmh,
                            'km/h',
                          ),
                          _fila('Ancho de pasada', orden.anchoPasadaM, 'm'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Seccion(
                        titulo: 'Observaciones',
                        children: [
                          Text(
                            orden.observaciones ?? _sinDatos,
                            key: const Key('orden_observaciones'),
                            style: TipografiaCampo.cuerpo,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (flavor == Flavor.piloto)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    child: _AbrirTrabajo(
                      cargando: cargandoTrabajo,
                      onAbrir: () =>
                          context.read<TrabajoCubit>().abrir(orden: orden),
                      onVolver: (trabajoUuidCliente) =>
                          _abrirSesionVuelo(context, trabajoUuidCliente),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lote, aplicación y dosis — lo que el piloto confirma de un vistazo.
  Widget _tarjetaLote() {
    return TarjetaCampo(
      tamano: TamanoTarjetaCampo.grande,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOTE',
            style: TipografiaCampo.etiquetaMono.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 10),
          Text(
            orden.loteCodigo ?? _sinDatos,
            key: const Key('orden_lote_codigo'),
            style: TipografiaCampo.valorDestacado,
          ),
          // Con ADR 0022 una orden cubre todos los lotes del contrato, pero
          // esta pantalla todavía muestra uno solo (multi-lote es HU-92,
          // aparte): se avisa que hay más en vez de presentar el primero
          // como si fuera la orden entera.
          if (orden.otrosLotes > 0) ...[
            const SizedBox(height: 4),
            Text(
              orden.otrosLotes == 1
                  ? 'y 1 lote más de la orden'
                  : 'y ${orden.otrosLotes} lotes más de la orden',
              key: const Key('orden_otros_lotes'),
              style: TipografiaCampo.cuerpoSecundario,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Aplicación N.º ${orden.nroAplicacion} · '
            'emitida ${orden.fechaEmision}',
            style: TipografiaCampo.cuerpoSecundario,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _chip(
                  'Hectáreas',
                  orden.hectareasOrden,
                  'ha',
                  key: const Key('orden_hectareas'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _chipDosis()),
            ],
          ),
        ],
      ),
    );
  }

  /// `litrosHa`/`kilosPorVuelo` son mutuamente excluyentes según la
  /// categoría de insumo (HU-79 de `agrocom-api`): se muestra el que venga,
  /// nunca los dos.
  Widget _chipDosis() {
    const key = Key('orden_dosis');
    final litrosHa = orden.litrosHa;
    if (litrosHa != null) return _chip('Dosis', litrosHa, 'L/ha', key: key);
    final kilosPorVuelo = orden.kilosPorVuelo;
    if (kilosPorVuelo != null) {
      return _chip('Dosis', kilosPorVuelo, 'kg/vuelo', key: key);
    }
    return _chip('Dosis', null, null, key: key);
  }

  Widget _tarjetaLimitesClimaticos() {
    return _Seccion(
      titulo: 'Límites climáticos',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _chip(
                'Viento máx',
                orden.vientoMaxKmh,
                'km/h',
                key: const Key('orden_viento_max'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _chip(
                'Temp. máx',
                orden.temperaturaMaxC,
                '°C',
                key: const Key('orden_temperatura_max'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _chip(
                'Humedad mín',
                orden.humedadMinPct,
                '%',
                key: const Key('orden_humedad_min'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _chip(
                'Humedad máx',
                orden.humedadMaxPct,
                '%',
                key: const Key('orden_humedad_max'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// La unidad solo acompaña a un valor real: «sin datos» va solo.
  static StatChipCampo _chip(
    String etiqueta,
    Object? valor,
    String? unidad, {
    Key? key,
  }) => StatChipCampo(
    key: key,
    etiqueta: etiqueta,
    valor: valor?.toString() ?? _sinDatos,
    unidad: valor == null ? null : unidad,
  );

  static FilaDatoCampo _fila(String etiqueta, Object? valor, String unidad) =>
      FilaDatoCampo(
        etiqueta: etiqueta,
        valor: valor?.toString() ?? _sinDatos,
        unidad: valor == null ? null : unidad,
      );
}

/// «Abrir trabajo» (HU-05) con la regla de un solo trabajo en curso (tarea
/// 28): con una sesión abierta o un trabajo sin cerrar en el dispositivo,
/// queda deshabilitado con el motivo y un acceso a lo que está en curso. Es
/// la misma regla que «Crear aplicación» en «Inicio»
/// (`motivoBloqueoPorEnCurso`); `TrabajoRepository` la vuelve a aplicar
/// antes de escribir.
///
/// Mientras llega la primera lectura de `drift`, el botón queda habilitado:
/// si había algo en curso, el repositorio rechaza igual y la pantalla
/// muestra el motivo.
class _AbrirTrabajo extends StatefulWidget {
  const _AbrirTrabajo({
    required this.cargando,
    required this.onAbrir,
    required this.onVolver,
  });

  final bool cargando;
  final VoidCallback onAbrir;
  final void Function(String trabajoUuidCliente) onVolver;

  @override
  State<_AbrirTrabajo> createState() => _AbrirTrabajoState();
}

class _AbrirTrabajoState extends State<_AbrirTrabajo> {
  // Una sola suscripción por pantalla, no una por `build`.
  late final Stream<TrabajoEnCurso?> _enCurso = context
      .read<TrabajoCubit>()
      .enCurso();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TrabajoEnCurso?>(
      stream: _enCurso,
      builder: (context, snapshot) {
        final enCurso = snapshot.data;
        final motivo = motivoBloqueoPorEnCurso(
          enCurso: enCurso,
          accion: 'abrir otro trabajo',
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (motivo != null && enCurso != null) ...[
              NotaInlineCampo(
                key: const Key('orden_abrir_bloqueado'),
                texto: motivo,
              ),
              const SizedBox(height: 10),
              BotonSecundarioCampo(
                key: const Key('boton_volver_en_curso'),
                texto: enCurso.conSesion
                    ? 'Volver a la sesión'
                    : 'Volver al trabajo',
                onPressed: () => widget.onVolver(enCurso.trabajoUuidCliente),
              ),
              const SizedBox(height: 10),
            ],
            BotonPrimarioCampo(
              key: const Key('boton_abrir_trabajo'),
              texto: 'Abrir trabajo',
              cargando: widget.cargando,
              onPressed: motivo == null ? widget.onAbrir : null,
            ),
          ],
        );
      },
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.children});

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return TarjetaCampo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TipografiaCampo.tituloTarjeta),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
