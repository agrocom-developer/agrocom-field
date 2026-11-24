import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/solicitud_repositorio.dart';
import 'mapa_solicitud.dart';
import 'pasos_solicitud.dart';
import 'solicitar_cubit.dart';
import 'solicitar_estado.dart';

/// Ancho del panel del formulario cuando la pantalla se divide en dos.
const _anchoPanel = 420.0;

/// Publicar una solicitud de fumigación, un paso por pantalla: lote (en el
/// mapa), aplicación (hectáreas, cultivo, producto), cuándo (fecha, accesos y
/// observaciones) y precio por hectárea. La solicitud queda abierta para que
/// los pilotos oferten. En iPad horizontal el mapa queda fijo a la izquierda
/// y el formulario a la derecha.
///
/// La clave de idempotencia nace con el cubit, al abrir el formulario, y se
/// reutiliza en cada reintento: un doble toque no crea dos solicitudes
/// (ADR 0009).
class SolicitarPantalla extends StatelessWidget {
  const SolicitarPantalla({required this.alSolicitado, super.key});

  /// Se llama con la solicitud publicada, para que el contenedor navegue.
  final ValueChanged<Solicitud> alSolicitado;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SolicitarCubit(context.read<SolicitudRepositorio>())..cargar(),
      child: SolicitarVista(alSolicitado: alSolicitado),
    );
  }
}

/// La interfaz del flujo sobre un [SolicitarCubit] ya provisto.
class SolicitarVista extends StatelessWidget {
  const SolicitarVista({required this.alSolicitado, super.key});

  final ValueChanged<Solicitud> alSolicitado;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SolicitarCubit, SolicitarEstado>(
      listenWhen: (antes, ahora) =>
          antes.solicitud == null && ahora.solicitud != null,
      listener: (context, estado) {
        HapticaCampo.confirmacion();
        alSolicitado(estado.solicitud!);
      },
      builder: (context, estado) => LayoutBuilder(
        builder: (context, limites) {
          final dividido =
              ClasePantallaCampo.deAncho(limites.maxWidth) ==
              ClasePantallaCampo.expandido;
          return switch (estado.carga) {
            CargaSolicitud.cargando => _Cargando(dividido: dividido),
            CargaSolicitud.error => _ErrorDeCarga(
              alReintentar: context.read<SolicitarCubit>().cargar,
            ),
            CargaSolicitud.lista =>
              dividido
                  ? _Dividido(estado: estado)
                  : Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _Columna(estado: estado, conMapa: true),
                      ),
                    ),
          };
        },
      ),
    );
  }
}

Widget _mapa(
  BuildContext context,
  SolicitarEstado e, {
  required bool editable,
}) {
  final cubit = context.read<SolicitarCubit>();
  final superficie = e.hectareas ?? e.hectareasCalculadas;
  return MapaSolicitud(
    key: const ValueKey('solicitar-mapa'),
    lotes: e.lotes,
    modo: e.modoLote,
    seleccionado: e.loteGuardado,
    vertices: e.vertices,
    superficie: e.lote == null || superficie == null
        ? null
        : FormatoMarketplace.hectareas(superficie),
    editable: editable,
    alSeleccionar: cubit.elegirLote,
    alAgregarVertice: cubit.agregarVertice,
    alMoverVertice: cubit.moverVertice,
  );
}

/// iPad horizontal: el mapa siempre a la vista, el formulario al costado.
class _Dividido extends StatelessWidget {
  const _Dividido({required this.estado});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _mapa(
            context,
            estado,
            editable: estado.paso == PasoSolicitud.lote,
          ),
        ),
        VerticalDivider(width: 1, color: context.paleta.borde),
        SizedBox(
          width: _anchoPanel,
          child: _Columna(estado: estado, conMapa: false),
        ),
      ],
    );
  }
}

/// Encabezado con el progreso, el paso actual y la acción principal.
class _Columna extends StatelessWidget {
  const _Columna({required this.estado, required this.conMapa});

  final SolicitarEstado estado;

  /// En una sola columna el paso «Lote» lleva el mapa arriba.
  final bool conMapa;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Encabezado(estado: e),
        Expanded(
          child: _CambioDePaso(
            paso: e.paso,
            avanza: e.avanza,
            child: switch (e.paso) {
              PasoSolicitud.lote =>
                conMapa ? _LoteConMapa(estado: e) : PanelLote(estado: e),
              PasoSolicitud.aplicacion => PasoAplicacion(estado: e),
              PasoSolicitud.cuando => PasoCuando(estado: e),
              PasoSolicitud.precio => PasoPrecio(estado: e),
            },
          ),
        ),
        _BarraAccion(estado: e),
      ],
    );
  }
}

class _LoteConMapa extends StatelessWidget {
  const _LoteConMapa({required this.estado});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        // El mapa es el protagonista: se queda con la mitad del alto, y el
        // panel de abajo se desplaza si hace falta.
        final alto = (limites.maxHeight * 0.5).clamp(140.0, 520.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: alto,
              child: _mapa(context, estado, editable: true),
            ),
            Divider(height: 1, color: context.paleta.borde),
            Expanded(child: PanelLote(estado: estado)),
          ],
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.estado});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    final paleta = context.paleta;
    final texto = Theme.of(context).textTheme;
    final total = PasoSolicitud.values.length;
    final indice = estado.paso.index;
    final puedeVolver = indice > 0 && !estado.enviando;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        EspaciadoCampo.m,
        EspaciadoCampo.l,
        EspaciadoCampo.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (indice > 0)
                Padding(
                  padding: const EdgeInsets.only(right: EspaciadoCampo.xs),
                  child: IconButton(
                    key: const ValueKey('solicitar-atras'),
                    tooltip: 'Paso anterior',
                    onPressed: puedeVolver
                        ? context.read<SolicitarCubit>().retroceder
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Publicar solicitud', style: texto.titleLarge),
                ),
              ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.s),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < total; i++) ...[
                  if (i > 0) const SizedBox(width: EspaciadoCampo.xs),
                  Expanded(
                    child: AnimatedContainer(
                      duration: MovimientoCampo.duracion(
                        context,
                        MovimientoCampo.media,
                      ),
                      curve: MovimientoCampo.movimiento,
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= indice ? paleta.acentoTexto : paleta.borde,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Text(
            'Paso ${indice + 1} de $total · ${estado.paso.etiqueta}',
            style: texto.bodyMedium?.copyWith(color: paleta.textoSecundario),
          ),
        ],
      ),
    );
  }
}

/// Transición entre pasos: el paso nuevo entra desde el lado hacia el que
/// se avanza, de modo que «Continuar» y «Paso anterior» se sienten opuestos.
/// Con movimiento reducido el cambio es instantáneo.
class _CambioDePaso extends StatelessWidget {
  const _CambioDePaso({
    required this.paso,
    required this.avanza,
    required this.child,
  });

  final PasoSolicitud paso;
  final bool avanza;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final desplazamiento = Offset(avanza ? 0.04 : -0.04, 0);
    return AnimatedSwitcher(
      duration: MovimientoCampo.duracion(context, MovimientoCampo.media),
      switchInCurve: MovimientoCampo.entrada,
      switchOutCurve: MovimientoCampo.salida,
      layoutBuilder: (actual, anteriores) =>
          Stack(fit: StackFit.expand, children: [...anteriores, ?actual]),
      transitionBuilder: (hijo, animacion) {
        final entra = hijo.key == ValueKey(paso);
        return FadeTransition(
          opacity: animacion,
          child: SlideTransition(
            position: Tween(
              begin: entra ? desplazamiento : -desplazamiento,
              end: Offset.zero,
            ).animate(animacion),
            child: hijo,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(paso), child: child),
    );
  }
}

/// La única acción principal de cada paso.
class _BarraAccion extends StatelessWidget {
  const _BarraAccion({required this.estado});

  final SolicitarEstado estado;

  @override
  Widget build(BuildContext context) {
    final e = estado;
    final paleta = context.paleta;
    final etiqueta = switch (e.paso) {
      PasoSolicitud.precio =>
        e.falloEnvio != null ? 'Reintentar publicación' : 'Publicar solicitud',
      _ => 'Continuar',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        EspaciadoCampo.s,
        EspaciadoCampo.l,
        EspaciadoCampo.l,
      ),
      child: Semantics(
        label: e.enviando ? 'Enviando la solicitud' : null,
        child: FilledButton(
          key: const ValueKey('solicitar-continuar'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(ObjetivoTactilCampo.guantes),
          ),
          onPressed: e.enviando
              ? () {}
              : e.puedeAvanzar
              ? context.read<SolicitarCubit>().avanzar
              : null,
          child: e.enviando
              ? SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: paleta.sobreAcento,
                  ),
                )
              : Text(etiqueta, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando({required this.dividido});

  final bool dividido;

  @override
  Widget build(BuildContext context) {
    const lineas = Padding(
      padding: EdgeInsets.all(EspaciadoCampo.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EsqueletoCampo(ancho: 200, alto: 22),
          SizedBox(height: EspaciadoCampo.l),
          EsqueletoCampo(alto: 48, radio: 14),
          SizedBox(height: EspaciadoCampo.m),
          EsqueletoCampo(alto: 64, radio: 18),
          SizedBox(height: EspaciadoCampo.s),
          EsqueletoCampo(alto: 64, radio: 18),
        ],
      ),
    );
    if (dividido) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: EsqueletoCampo(alto: double.infinity, radio: 0)),
          SizedBox(width: _anchoPanel, child: lineas),
        ],
      );
    }
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [EsqueletoCampo(alto: 260, radio: 0), lineas],
      ),
    );
  }
}

class _ErrorDeCarga extends StatelessWidget {
  const _ErrorDeCarga({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EstadoVacioMarketplace(
              icono: Icons.cloud_off_rounded,
              titulo: 'No pudimos cargar tus lotes',
              detalle:
                  'Publicar una solicitud necesita conexión. Revisa la señal '
                  'y vuelve a intentar.',
            ),
            FilledButton.icon(
              key: const ValueKey('solicitar-reintentar-carga'),
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
          ],
        ),
      ),
    );
  }
}
