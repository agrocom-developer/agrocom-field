import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart' show Lote;
import '../../../l10n/app_localizations.dart';
import '../../../nucleo/marketplace/foto_preparador.dart';
import '../../../nucleo/marketplace/terrenos/fotos_terreno_repositorio.dart';
import '../../../nucleo/marketplace/terrenos/presentation/fotos_terreno_cubit.dart';
import '../../../nucleo/marketplace/ui/marketplace_ui.dart';
import '../../../nucleo/ui/componentes/componentes_campo.dart';
import '../../../nucleo/ui/paleta_campo.dart';
import '../../../nucleo/ui/tipografia_campo.dart';
import '../../../nucleo/ui/tokens_campo.dart';
import '../../contactos/domain/contactos_repositorio.dart';
import '../../solicitudes/domain/solicitud.dart';
import '../domain/solicitud_repositorio.dart';
import 'mapa_solicitud.dart';
import 'pasos_solicitud.dart';
import 'solicitar_cubit.dart';
import 'solicitar_estado.dart';
import 'textos_errores_solicitud.dart';

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
    final l10n = AppLocalizations.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SolicitarCubit(
            context.read<SolicitudRepositorio>(),
            // Solo un cliente empresa tiene contactos de referencia.
            contactos: _contactosDe(context),
          )..cargar(),
        ),
        BlocProvider(
          create: (context) => FotosTerrenoCubit(
            context.read<FotosTerrenoRepositorio>(),
            context.read<PreparadorFoto>(),
            l10n,
          ),
        ),
      ],
      child: SolicitarVista(alSolicitado: alSolicitado),
    );
  }
}

ContactosRepositorio? _contactosDe(BuildContext context) {
  try {
    return context.read<ContactosRepositorio>();
  } on ProviderNotFoundException {
    return null;
  }
}

/// La interfaz del flujo sobre un [SolicitarCubit] ya provisto.
class SolicitarVista extends StatelessWidget {
  const SolicitarVista({required this.alSolicitado, super.key});

  final ValueChanged<Solicitud> alSolicitado;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolicitarCubit, SolicitarEstado>(
      // Las fotos siguen al terreno elegido: uno guardado o el contorno nuevo.
      listenWhen: (antes, ahora) =>
          antes.modoLote != ahora.modoLote ||
          antes.loteGuardado?.id != ahora.loteGuardado?.id,
      listener: (context, estado) {
        final Lote? lote = estado.modoLote == ModoLote.guardado
            ? estado.loteGuardado
            : null;
        context.read<FotosTerrenoCubit>().usarTerreno(
          lote?.terrenoId,
          lote?.fotos ?? const [],
        );
      },
      child: _VistaSolicitar(alSolicitado: alSolicitado),
    );
  }
}

class _VistaSolicitar extends StatelessWidget {
  const _VistaSolicitar({required this.alSolicitado});

  final ValueChanged<Solicitud> alSolicitado;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SolicitarCubit, SolicitarEstado>(
      listenWhen: (antes, ahora) =>
          antes.solicitud == null && ahora.solicitud != null,
      listener: (context, estado) async {
        HapticaCampo.confirmacion();
        final fotos = context.read<FotosTerrenoCubit>();
        final solicitud = estado.solicitud!;
        // Un contorno nuevo ya es un terreno: las fotos que se eligieron
        // antes salen ahora.
        if (estado.modoLote == ModoLote.dibujo && fotos.pendientes > 0) {
          await fotos.subirPendientes(solicitud.lote.terrenoId);
        }
        alSolicitado(solicitud);
      },
      builder: (context, estado) {
        // Un envío que falla es una pantalla propia (patrón del estado 21):
        // dice qué quedó guardado y deja reintentar o volver a editar.
        final fallo = estado.falloEnvio;
        if (fallo != null && !estado.enviando) {
          final t = AppLocalizations.of(context);
          final cubit = context.read<SolicitarCubit>();
          return EstadoErrorMarketplace(
            key: const ValueKey('solicitar-error-envio'),
            sinConexion: fallo == FalloEnvio.sinConexion,
            titulo: t.envioErrorTitulo,
            detalle: switch (fallo) {
              FalloEnvio.sinConexion => t.envioErrorDetalleSinRed,
              FalloEnvio.rechazado =>
                estado.mensajeRechazo ?? t.envioErrorDetalleRechazo,
              FalloEnvio.desconocido => t.envioErrorDetalleRechazo,
            },
            onReintentar: cubit.publicar,
            etiquetaSecundaria: t.envioErrorVolver,
            onSecundaria: cubit.descartarFallo,
          );
        }
        return LayoutBuilder(
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
        );
      },
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
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
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
                    tooltip: l10n.solicitarPasoAnterior,
                    onPressed: puedeVolver
                        ? context.read<SolicitarCubit>().retroceder
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.solicitarPaso(
                        indice + 1,
                        total,
                        estado.paso.etiquetaL10n(l10n),
                      ),
                      style: TipografiaCampo.cuerpoSecundario.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.solicitarPublicarLote,
                        style: TipografiaCampo.tituloSeccion.copyWith(
                          color: paleta.texto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.m),
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
                      height: EspaciadoCampo.s,
                      decoration: BoxDecoration(
                        color: i <= indice
                            ? paleta.acentoTexto
                            : paleta.superficie2,
                        borderRadius: BorderRadius.circular(RadioCampo.capsula),
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
    final l10n = AppLocalizations.of(context);
    final e = estado;
    final paleta = context.paleta;
    final etiqueta = switch (e.paso) {
      PasoSolicitud.precio =>
        e.falloEnvio != null
            ? l10n.solicitarReintentarPublicacion
            : l10n.solicitarPublicarSolicitud,
      _ => l10n.solicitarContinuar,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspaciadoCampo.l,
        EspaciadoCampo.s,
        EspaciadoCampo.l,
        EspaciadoCampo.l,
      ),
      child: Semantics(
        label: e.enviando ? l10n.solicitarEnviandoSolicitud : null,
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
          EsqueletoCampo(alto: 48, radio: RadioCampo.media),
          SizedBox(height: EspaciadoCampo.m),
          EsqueletoCampo(alto: 64, radio: RadioCampo.tarjetaCompacta),
          SizedBox(height: EspaciadoCampo.s),
          EsqueletoCampo(alto: 64, radio: RadioCampo.tarjetaCompacta),
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EstadoVacioMarketplace(
              icono: Icons.cloud_off_rounded,
              titulo: l10n.solicitarPudimosCargarTusLotes,
              detalle: l10n.solicitarPublicarUnaSolicitudNecesita,
            ),
            FilledButton.icon(
              key: const ValueKey('solicitar-reintentar-carga'),
              onPressed: alReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.solicitarReintentar),
            ),
            const SizedBox(height: EspaciadoCampo.xl),
          ],
        ),
      ),
    );
  }
}
