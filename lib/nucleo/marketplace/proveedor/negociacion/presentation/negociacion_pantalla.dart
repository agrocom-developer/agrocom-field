import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../ui/componentes/componentes_campo.dart';
import '../../../../ui/paleta_campo.dart';
import '../../../../ui/tipografia_campo.dart';
import '../../../../ui/tokens_campo.dart';
import '../../../referencias/presentation/sugerencia_precio_referencia.dart';
import '../../../ui/boton_principal_marketplace.dart';
import '../../../ui/marketplace_ui.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import 'cifras_negociacion.dart';
import 'negociacion_cubit.dart';
import '../../../../../l10n/app_localizations.dart';

/// La negociación con el cliente como conversación (pantalla 15): cada ronda
/// es una burbuja, arriba va la barra de rondas y abajo el panel con el
/// stepper de ±1 Bs/ha y el total recalculado en vivo.
///
/// Aceptar y negociar requieren red: son llamadas directas, sin outbox (ADR
/// 0016). Sin señal, la pantalla lo dice, conserva el precio y deja
/// reintentar.
class NegociacionPantalla extends StatelessWidget {
  const NegociacionPantalla({
    required this.solicitudId,
    this.solicitud,
    super.key,
  });

  final int solicitudId;

  /// La fila del mapa, si se viene de ahí: evita pedir el detalle.
  final SolicitudAbierta? solicitud;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NegociacionCubit(
        context.read<MercadoRepositorio>(),
        context.read<NegociacionRepositorio>(),
        solicitudId: solicitudId,
        solicitud: solicitud,
      )..cargar(),
      child: const _Vista(),
    );
  }
}

class _Vista extends StatelessWidget {
  const _Vista();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return BlocConsumer<NegociacionCubit, NegociacionEstado>(
      listenWhen: (a, b) => a.enviado != b.enviado && b.enviado != null,
      listener: (context, estado) => HapticaCampo.confirmacion(),
      builder: (context, estado) {
        return Scaffold(
          backgroundColor: paleta.fondo,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (estado.sinRed)
                BannerSinSenalCampo(
                  mensaje: l10n.proveedorNegociacionOfertarNecesitaRedPrecio,
                ),
              SafeArea(
                top: !estado.sinRed,
                bottom: false,
                child: _Encabezado(estado: estado),
              ),
              Divider(height: 1, color: paleta.borde),
              Expanded(child: _Cuerpo(estado: estado)),
              if (estado.fase == FaseNegociacion.lista) _Panel(estado: estado),
            ],
          ),
        );
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.estado});

  final NegociacionEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final s = estado.solicitud;
    final titulo = s == null
        ? l10n.proveedorNegociacionSolicitud
        : '${s.zona ?? 'Solicitud'} · ${FormatoMarketplace.hectareas(s.hectareas)}';
    final ronda = estado.rondaActual;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EspaciadoCampo.s,
        EspaciadoCampo.s,
        EspaciadoCampo.l,
        EspaciadoCampo.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.proveedorNegociacionVolver,
                constraints: BoxConstraints.tightFor(
                  width: paleta.esCampo
                      ? ObjetivoTactilCampo.campo
                      : ObjetivoTactilCampo.guantes,
                  height: paleta.esCampo
                      ? ObjetivoTactilCampo.campo
                      : ObjetivoTactilCampo.guantes,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.proveedorNegociacionNegociacionConCliente,
                      style: TipografiaCampo.cuerpoSecundario.copyWith(
                        color: paleta.textoSecundario,
                      ),
                    ),
                    Text(
                      titulo,
                      style: TipografiaCampo.tituloBloque.copyWith(
                        fontSize: 17,
                        color: paleta.texto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: EspaciadoCampo.s),
          Padding(
            padding: const EdgeInsets.only(left: EspaciadoCampo.s),
            child: _BarraRondas(
              ronda: ronda,
              total: NegociacionEstado.rondasMaximas,
              // Con la oferta enviada o la negociación cerrada nadie
              // "tiene el turno" en el piloto: el segmento no se pinta ámbar.
              esTurno: estado.esMiTurno,
            ),
          ),
        ],
      ),
    );
  }
}

/// «Ronda 4 de 5» y cinco segmentos: hechos en el acento, el turno en ámbar y
/// los pendientes vacíos.
class _BarraRondas extends StatelessWidget {
  const _BarraRondas({
    required this.ronda,
    required this.total,
    required this.esTurno,
  });

  final int ronda;
  final int total;
  final bool esTurno;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    return Semantics(
      container: true,
      label: 'Ronda $ronda de $total${esTurno ? ', es tu turno' : ''}',
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            l10n.proveedorNegociacionRonda(ronda, total),
            style: TipografiaCampo.tituloSeccion.copyWith(color: paleta.texto),
          ),
          const SizedBox(width: EspaciadoCampo.m),
          Expanded(
            child: Row(
              children: [
                for (var i = 1; i <= total; i++) ...[
                  if (i > 1) const SizedBox(width: EspaciadoCampo.xs),
                  Expanded(
                    child: Container(
                      height: EspaciadoCampo.s,
                      decoration: BoxDecoration(
                        color: i < ronda
                            ? paleta.acento
                            : (i == ronda ? paleta.ambar : paleta.superficie2),
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

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.estado});

  final NegociacionEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<NegociacionCubit>();
    switch (estado.fase) {
      case FaseNegociacion.cargando:
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: const [
            EsqueletoCampo(alto: 112, radio: 24),
            SizedBox(height: EspaciadoCampo.m),
            EsqueletoCampo(alto: 112, radio: 24),
          ],
        );
      case FaseNegociacion.sinRed:
        return ListView(
          children: [
            BannerSinSenalCampo(
              mensaje: l10n.proveedorNegociacionAbrirNegociacionNecesitaRed,
            ),
            EstadoErrorMarketplace(
              sinConexion: true,
              tablaSinRed: true,
              titulo: l10n.proveedorNegociacionSinConexion,
              detalle: l10n.proveedorNegociacionNegociarEntreDosPersonas,
              onReintentar: cubit.cargar,
            ),
          ],
        );
      case FaseNegociacion.error:
        return ListView(
          children: [
            EstadoErrorMarketplace(
              titulo: l10n.proveedorNegociacionPudimosAbrirNegociacion,
              detalle:
                  estado.mensaje ??
                  l10n.proveedorNegociacionIntentaNuevoMomento,
              onReintentar: cubit.cargar,
            ),
          ],
        );
      case FaseNegociacion.lista:
        return ListView(
          padding: const EdgeInsets.all(EspaciadoCampo.l),
          children: [
            for (final r in estado.rondas) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: EspaciadoCampo.m),
                child: BurbujaNegociacionCampo(
                  autor: r.delPiloto ? AutorRonda.piloto : AutorRonda.cliente,
                  quien: r.delPiloto ? l10n.proveedorNegociacionTu2 : null,
                  ronda: r.numero,
                  precioPorHectarea: CifrasNegociacion.bsHa(r.precioHa),
                  total: CifrasNegociacion.bs(r.total),
                  nota: r.publicado
                      ? l10n.proveedorNegociacionPublicado
                      : r.nota,
                  conBarra: false,
                ),
              ),
            ],
            _AvisoTurno(estado: estado),
            // Una guía, no un límite: tocarla solo mueve el stepper.
            if (estado.esMiTurno && !estado.esDefinitiva) ...[
              const SizedBox(height: EspaciadoCampo.l),
              SugerenciaPrecioReferencia(
                tipoAplicacion: estado.solicitud!.tipoAplicacion ?? 'otro',
                zonaId: estado.solicitud!.zonaId,
                macrorregion: estado.solicitud!.macrorregion?.codigo,
                actual: Decimal.fromInt(estado.precio),
                alUsar: (v) =>
                    cubit.cambiarPrecio(v.round().toBigInt().toInt()),
              ),
            ],
          ],
        );
    }
  }
}

/// La frase que dice de quién es el turno y qué sigue.
class _AvisoTurno extends StatelessWidget {
  const _AvisoTurno({required this.estado});

  final NegociacionEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final ronda = estado.rondaActual;
    final (texto, icono) = switch (estado) {
      _ when estado.enviado == 'adjudicada' => (
        l10n.proveedorNegociacionAceptasteSolicitudTuyaContacto,
        Icons.verified_rounded,
      ),
      _ when estado.enviado == 'rechazada' => (
        l10n.proveedorNegociacionRechazasteOfertaNegociacionCerro,
        Icons.block_rounded,
      ),
      _ when estado.enviado == 'retirada' => (
        l10n.proveedorNegociacionRetirasteOfertaNegociacionCerro,
        Icons.undo_rounded,
      ),
      _ when estado.esperaAlCliente => (
        l10n.proveedorNegociacionEsperandoClienteAvisamosCuando,
        Icons.hourglass_top_rounded,
      ),
      _ when estado.cerrada => (
        l10n.proveedorNegociacionEstaNegociacionCerroPuede,
        Icons.lock_outline_rounded,
      ),
      _ when estado.esDefinitiva || ronda >= NegociacionEstado.rondasMaximas =>
        (l10n.proveedorNegociacionTurnoRondaFinalAceptas, Icons.flag_rounded),
      _ when estado.esMiTurno => (
        ronda == NegociacionEstado.rondasMaximas - 1
            ? l10n.proveedorNegociacionTurnoDespuesSoloQueda(
                NegociacionEstado.rondasMaximas,
              )
            : l10n.proveedorNegociacionTurnoRonda(
                ronda,
                NegociacionEstado.rondasMaximas,
              ),
        Icons.bolt_rounded,
      ),
      _ => ('', Icons.info_outline_rounded),
    };
    if (texto.isEmpty) return const SizedBox.shrink();
    final turno = estado.esMiTurno;
    return Semantics(
      container: true,
      liveRegion: true,
      label: texto,
      excludeSemantics: true,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: turno ? paleta.ambarContenedor : paleta.superficie2,
            borderRadius: BorderRadius.circular(RadioCampo.capsula),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EspaciadoCampo.l,
              vertical: EspaciadoCampo.s + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono,
                  size: 18,
                  color: turno
                      ? paleta.sobreAmbarContenedor
                      : paleta.textoSecundario,
                ),
                const SizedBox(width: EspaciadoCampo.s),
                Flexible(
                  child: Text(
                    texto,
                    style: TipografiaCampo.tituloSeccion.copyWith(
                      fontSize: 14,
                      color: turno
                          ? paleta.sobreAmbarContenedor
                          : paleta.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El panel de abajo: el stepper y las dos salidas (aceptar o enviar), o lo
/// que corresponde si ya no es tu turno.
class _Panel extends StatelessWidget {
  const _Panel({required this.estado});

  final NegociacionEstado estado;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paleta = context.paleta;
    final cubit = context.read<NegociacionCubit>();
    final alto = paleta.esCampo
        ? ObjetivoTactilCampo.campo
        : ObjetivoTactilCampo.guantes;
    final hecho = estado.enviado != null;
    final Widget contenido;
    if (!estado.esMiTurno) {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (estado.mensaje != null) ...[
            Semantics(
              liveRegion: true,
              child: AvisoMarketplace(
                mensaje: estado.mensaje!,
                tono: estado.sinRed ? TonoAviso.alerta : TonoAviso.error,
                icono: estado.sinRed ? Icons.wifi_off_rounded : null,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
          ],
          BotonPrincipalMarketplace(
            texto: hecho
                ? l10n.proveedorNegociacionVerMisOfertas
                : l10n.proveedorNegociacionVolver,
            alto: alto,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          if (estado.esperaAlCliente && estado.ofertaMia != null) ...[
            const SizedBox(height: EspaciadoCampo.s),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size.fromHeight(alto),
                foregroundColor: paleta.error,
              ),
              onPressed: estado.enviando ? null : cubit.retirar,
              child: Text(l10n.proveedorNegociacionRetirarOferta),
            ),
          ],
        ],
      );
    } else {
      final aceptable = estado.precioDelCliente;
      final definitiva = estado.esDefinitiva;
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (estado.mensaje != null) ...[
            Semantics(
              liveRegion: true,
              child: AvisoMarketplace(
                mensaje: estado.mensaje!,
                tono: estado.sinRed ? TonoAviso.alerta : TonoAviso.error,
                icono: estado.sinRed ? Icons.wifi_off_rounded : null,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
          ],
          if (!definitiva) ...[
            Center(
              child: StepperCampo(
                valor: estado.precio,
                minimo: 1,
                maximo: 99999,
                unidad: 'Bs/ha',
                etiqueta: l10n.proveedorNegociacionPrecioPorHectarea2,
                alturaCampo: paleta.esCampo,
                onCambio: cubit.cambiarPrecio,
              ),
            ),
            const SizedBox(height: EspaciadoCampo.xs),
            Semantics(
              liveRegion: true,
              child: Center(
                child: Text(
                  estado.total == null
                      ? ''
                      : l10n.proveedorNegociacionTotal2(
                          FormatoMarketplace.bs(estado.total!),
                        ),
                  style: TipografiaCampo.datoMono.copyWith(
                    fontSize: 14,
                    color: paleta.textoSecundario,
                  ),
                ),
              ),
            ),
            const SizedBox(height: EspaciadoCampo.m),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.fromHeight(alto),
                  ),
                  onPressed: estado.enviando || aceptable == null
                      ? null
                      : cubit.aceptar,
                  child: Text(
                    aceptable == null
                        ? l10n.proveedorNegociacionAceptar2
                        : l10n.proveedorNegociacionAceptar3(
                            CifrasNegociacion.bsHa(aceptable),
                          ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (!definitiva) ...[
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: BotonPrincipalMarketplace(
                    texto: estado.sinRed
                        ? l10n.proveedorNegociacionReintentar(estado.precio)
                        : l10n.proveedorNegociacionEnviar(estado.precio),
                    alto: alto,
                    cargando: estado.enviando,
                    onPressed: estado.precio == aceptable?.toBigInt().toInt()
                        ? null
                        : () => cubit.enviar(),
                  ),
                ),
              ] else if (estado.pendiente != null) ...[
                const SizedBox(width: EspaciadoCampo.m),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: Size.fromHeight(alto),
                      foregroundColor: paleta.error,
                    ),
                    onPressed: estado.enviando ? null : cubit.rechazar,
                    child: Text(l10n.proveedorNegociacionRechazar),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ElevacionCampo.superficie(paleta, 2),
        border: Border.all(color: paleta.borde),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(RadioCampo.hoja),
        ),
        boxShadow: ElevacionCampo.sombras(paleta, 3),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(EspaciadoCampo.l),
            child: contenido,
          ),
        ),
      ),
    );
  }
}
