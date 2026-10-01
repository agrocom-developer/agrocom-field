import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/ui/colores_campo.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/imagenes_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../incidencias/presentation/incidencia_cubit.dart';
import '../../sesion_vuelo/presentation/sesion_bloc.dart';
import '../../sesion_vuelo/presentation/sesion_vuelo_pantalla.dart';
import '../../sesion_vuelo/presentation/trabajo_cubit.dart';
import '../../sesion_vuelo/presentation/trabajo_estado.dart';
import '../domain/trabajo_asignado.dart';
import 'inicio_cubit.dart';
import 'inicio_estado.dart';

/// «Inicio» del piloto (HU-70) en modo campo (ADR 0008), con el lenguaje de
/// la vista previa 03 (`inicio_piloto_campo_vitrina.dart`): foto superior,
/// saludo, tarjeta del trabajo asignado con sus `StatChipCampo` y «Crear
/// aplicación», y la barra de navegación.
///
/// De la 03 se muestra solo lo que tiene fuente en `drift`: el nombre del
/// piloto, el clima, la hora de asignación y el banner «SIN CONEXIÓN · N
/// pendientes» quedan fuera (no hay en este repo un conteo reactivo del
/// outbox ni estado de conectividad para la UI), y la barra lleva solo los
/// destinos con pantalla real: Inicio y Órdenes. Un dato ausente se lee
/// «sin datos», nunca se inventa; sin trabajo asignado, un estado vacío
/// explícito. Debajo del trabajo, sus límites climáticos y parámetros de
/// vuelo (tarea 23), los del propio trabajo asignado.
class InicioVista extends StatelessWidget {
  const InicioVista({
    required this.crearTrabajoCubit,
    required this.crearSesionBloc,
    required this.crearIncidenciaCubit,
    required this.construirOrdenes,
    super.key,
  });

  final TrabajoCubit Function() crearTrabajoCubit;
  final SesionBloc Function(String) crearSesionBloc;
  final IncidenciaCubit Function(String sesionUuidCliente) crearIncidenciaCubit;
  final WidgetBuilder construirOrdenes;

  static const _sinDatos = 'sin datos';

  void _abrirOrdenes(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: construirOrdenes));
  }

  void _crearAplicacion(BuildContext context, TrabajoAsignado trabajo) {
    final nroAplicacion = trabajo.nroAplicacion;
    if (nroAplicacion == null) return;
    context.read<TrabajoCubit>().abrirAsignado(
      uuidCliente: trabajo.uuidCliente,
      ordenId: trabajo.ordenId,
      loteId: trabajo.loteId,
      nroAplicacion: nroAplicacion,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TrabajoCubit, TrabajoEstado>(
      listener: (context, estado) {
        if (estado is TrabajoExitoso) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SesionVueloPantalla(
                crearBloc: () => crearSesionBloc(estado.trabajo.uuidCliente),
                crearTrabajoCubit: crearTrabajoCubit,
                crearIncidenciaCubit: crearIncidenciaCubit,
              ),
            ),
          );
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
      child: BlocBuilder<InicioCubit, InicioEstado>(
        builder: (context, estado) {
          final trabajo = estado is InicioConTrabajo ? estado.trabajo : null;
          return Scaffold(
            backgroundColor: ColoresCampo.fondoProfundo,
            body: FondoFotoCampo(
              imagen: ImagenesCampo.dronAgrasT50,
              cobertura: CoberturaFondoFoto.superior,
              altoSuperior: 220,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                        children: [
                          const _Saludo(),
                          const SizedBox(height: 18),
                          switch (estado) {
                            InicioCargando() => const Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Center(
                                key: Key('inicio_cargando'),
                                child: CircularProgressIndicator(
                                  color: ColoresCampo.acentoLima,
                                ),
                              ),
                            ),
                            InicioSinTrabajo() => _SinTrabajo(
                              onVerOrdenes: () => _abrirOrdenes(context),
                            ),
                            InicioConTrabajo(:final trabajo) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TarjetaTrabajo(
                                  trabajo: trabajo,
                                  onCrearAplicacion: () =>
                                      _crearAplicacion(context, trabajo),
                                ),
                                const SizedBox(height: 12),
                                _TarjetaLimites(trabajo: trabajo),
                              ],
                            ),
                          },
                        ],
                      ),
                    ),
                    BarraNavegacionCampo(
                      items: const [
                        ItemBarraNavegacionCampo(
                          icono: Icons.home_filled,
                          etiqueta: 'Inicio',
                        ),
                        ItemBarraNavegacionCampo(
                          icono: Icons.list_alt,
                          etiqueta: 'Órdenes',
                        ),
                      ],
                      indiceActivo: 0,
                      onSeleccionar: (indice) {
                        if (indice == 1) _abrirOrdenes(context);
                      },
                      // El «+» crea una aplicación: sobre el trabajo asignado
                      // si lo hay y ya se puede; si no, lleva a las órdenes
                      // vigentes, donde el piloto abre un trabajo propio.
                      onAccionCentral: () {
                        if (trabajo != null && trabajo.puedeCrearAplicacion) {
                          _crearAplicacion(context, trabajo);
                        } else {
                          _abrirOrdenes(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Saludo extends StatelessWidget {
  const _Saludo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColoresCampo.superficie,
            border: Border.all(
              color: ColoresCampo.textoPrincipal.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(
            Icons.person,
            color: ColoresCampo.textoPrincipal.withValues(
              alpha: OpacidadesCampo.media,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola',
                style: TipografiaCampo.tituloSeccion.copyWith(fontSize: 20),
              ),
              Text(
                'Piloto',
                style: TipografiaCampo.cuerpoSecundario.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SinTrabajo extends StatelessWidget {
  const _SinTrabajo({required this.onVerOrdenes});

  final VoidCallback onVerOrdenes;

  @override
  Widget build(BuildContext context) {
    return TarjetaCampo(
      key: const Key('inicio_sin_trabajo'),
      tamano: TamanoTarjetaCampo.grande,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIN TRABAJO ASIGNADO',
            style: TipografiaCampo.etiquetaMono.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 12),
          const Text(
            'Todavía no tenés un trabajo asignado',
            style: TipografiaCampo.valorDestacado,
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando el jefe de campo te asigne uno desde el panel, aparece '
            'acá al sincronizar. Mientras tanto podés ver las órdenes '
            'vigentes.',
            style: TipografiaCampo.cuerpoSecundario,
          ),
          const SizedBox(height: 16),
          BotonSecundarioCampo(
            key: const Key('inicio_ver_ordenes'),
            texto: 'Ver órdenes',
            onPressed: onVerOrdenes,
          ),
        ],
      ),
    );
  }
}

class _TarjetaTrabajo extends StatelessWidget {
  const _TarjetaTrabajo({
    required this.trabajo,
    required this.onCrearAplicacion,
  });

  final TrabajoAsignado trabajo;
  final VoidCallback onCrearAplicacion;

  /// `Decimal.toString()` tal cual, nunca pasando por `double`
  /// (invariante 9 de CLAUDE.md).
  static String _valor(Object? valor) =>
      valor?.toString() ?? InicioVista._sinDatos;

  @override
  Widget build(BuildContext context) {
    final dosis = trabajo.dosis;
    final nroAplicacion = trabajo.nroAplicacion;
    return TarjetaCampo(
      key: const Key('inicio_trabajo_asignado'),
      tamano: TamanoTarjetaCampo.grande,
      acento: ColoresCampo.acentoLima,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASIGNADO POR JEFE DE CAMPO',
            style: TipografiaCampo.etiquetaMono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColoresCampo.acentoLima,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            trabajo.loteCodigo ?? 'Lote sin datos',
            key: const Key('inicio_lote'),
            style: TipografiaCampo.valorDestacado,
          ),
          const SizedBox(height: 4),
          Text(
            nroAplicacion == null
                ? 'Orden N.º ${trabajo.ordenId}'
                : 'Orden N.º ${trabajo.ordenId} · '
                      'Aplicación N.º $nroAplicacion',
            key: const Key('inicio_orden'),
            style: TipografiaCampo.cuerpoSecundario,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StatChipCampo(
                  key: const Key('inicio_hectareas'),
                  etiqueta: 'Hectáreas',
                  valor: _valor(trabajo.hectareasDeclaradas),
                  unidad: 'ha',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatChipCampo(
                  key: const Key('inicio_dosis'),
                  etiqueta: dosis?.etiqueta ?? 'Dosis',
                  valor: _valor(dosis?.valor),
                  unidad: dosis?.unidad,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatChipCampo(
                  key: const Key('inicio_lotes_orden'),
                  etiqueta: 'Lotes orden',
                  valor: _valor(trabajo.cantidadLotesOrden),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BotonPrimarioCampo(
            key: const Key('boton_crear_aplicacion'),
            texto: 'Crear aplicación',
            cargando: context.select<TrabajoCubit, bool>(
              (cubit) => cubit.state is TrabajoCargando,
            ),
            onPressed: trabajo.puedeCrearAplicacion ? onCrearAplicacion : null,
          ),
          if (!trabajo.puedeCrearAplicacion) ...[
            const SizedBox(height: 10),
            const NotaInlineCampo(
              key: Key('inicio_falta_orden'),
              texto:
                  'La orden de este trabajo todavía no llegó al dispositivo: '
                  'sincronizá para poder crear la aplicación.',
            ),
          ],
        ],
      ),
    );
  }
}

/// Límites climáticos y parámetros de vuelo del trabajo asignado (tarea 23):
/// los que el jefe de campo cargó al asignar, nunca los de otro trabajo ni
/// de la orden. Un límite sin completar se lee «sin datos», sin unidad.
class _TarjetaLimites extends StatelessWidget {
  const _TarjetaLimites({required this.trabajo});

  final TrabajoAsignado trabajo;

  /// La unidad solo acompaña a un valor real; `Decimal.toString()` tal
  /// cual, nunca pasando por `double` (invariante 9 de CLAUDE.md).
  static Widget _chip(
    String key,
    String etiqueta,
    Object? valor,
    String unidad,
  ) => Expanded(
    child: StatChipCampo(
      key: Key(key),
      etiqueta: etiqueta,
      valor: valor?.toString() ?? InicioVista._sinDatos,
      unidad: valor == null ? null : unidad,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return TarjetaCampo(
      key: const Key('inicio_limites'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Límites climáticos',
            style: TipografiaCampo.tituloTarjeta,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chip(
                'inicio_viento_max',
                'Viento máx',
                trabajo.vientoMaxKmh,
                'km/h',
              ),
              const SizedBox(width: 10),
              _chip(
                'inicio_temperatura_max',
                'Temp. máx',
                trabajo.temperaturaMaxC,
                '°C',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chip(
                'inicio_humedad_min',
                'Humedad mín',
                trabajo.humedadMinPct,
                '%',
              ),
              const SizedBox(width: 10),
              _chip(
                'inicio_humedad_max',
                'Humedad máx',
                trabajo.humedadMaxPct,
                '%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Parámetros de vuelo',
            style: TipografiaCampo.tituloTarjeta,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chip('inicio_altura_vuelo', 'Altura', trabajo.alturaVueloM, 'm'),
              const SizedBox(width: 10),
              _chip(
                'inicio_velocidad_vuelo',
                'Velocidad',
                trabajo.velocidadVueloKmh,
                'km/h',
              ),
              const SizedBox(width: 10),
              _chip(
                'inicio_ancho_pasada',
                'Ancho pasada',
                trabajo.anchoPasadaM,
                'm',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
