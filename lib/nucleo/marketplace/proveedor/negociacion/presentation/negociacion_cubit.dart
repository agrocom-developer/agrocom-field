import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../dominio/dominio.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';

/// Quién dijo qué en una ronda, ya con el número que ve la persona.
class RondaVista {
  const RondaVista({
    required this.numero,
    required this.delPiloto,
    required this.precioHa,
    required this.total,
    this.nota,
    this.publicado = false,
  });

  /// Número de ronda visible: la solicitud publicada es la R1 y la primera
  /// oferta del piloto es la R2 (el servidor numera desde la oferta).
  final int numero;
  final bool delPiloto;
  final Decimal precioHa;
  final Decimal total;
  final String? nota;

  /// La R1: el precio con el que el cliente publicó el lote.
  final bool publicado;
}

enum FaseNegociacion { cargando, lista, sinRed, error }

class NegociacionEstado {
  const NegociacionEstado({
    this.fase = FaseNegociacion.cargando,
    this.solicitud,
    this.rondas = const [],
    this.pendiente,
    this.ofertaMia,
    this.precio = 0,
    this.enviando = false,
    this.enviado,
    this.mensaje,
    this.sinRed = false,
  });

  final FaseNegociacion fase;
  final SolicitudAbierta? solicitud;
  final List<RondaVista> rondas;

  /// La oferta vigente del cliente a la que le toca responder al piloto.
  final OfertaNegociada? pendiente;

  /// Mi oferta vigente, que espera al cliente.
  final OfertaNegociada? ofertaMia;

  /// El precio por hectárea del stepper, en bolivianos enteros.
  final int precio;
  final bool enviando;

  /// Lo que acaba de pasar con éxito: `contraoferta`, `oferta` (aceptó el
  /// precio del cliente como primera oferta), `adjudicada`, `rechazada` o `retirada`.
  final String? enviado;
  final String? mensaje;

  /// El último intento falló por falta de red: el precio se conserva.
  final bool sinRed;

  /// Lo último que dijo el cliente: el precio que se acepta.
  Decimal? get precioDelCliente {
    for (final r in rondas.reversed) {
      if (!r.delPiloto) return r.precioHa;
    }
    return null;
  }

  Decimal? get hectareas => solicitud?.hectareas;

  /// Total del stepper: hectáreas por precio, recalculado en vivo.
  Decimal? get total =>
      hectareas == null ? null : hectareas! * Decimal.fromInt(precio);

  /// El servidor marcó la oferta del cliente como la última.
  bool get esDefinitiva => pendiente?.esDefinitiva ?? false;

  /// Le toca al piloto: no hay oferta suya vigente ni la negociación cerró.
  bool get esMiTurno {
    if (solicitud == null || enviado != null) return false;
    if (pendiente != null) return true;
    return solicitud!.puedeOfertar &&
        !rondas.any((r) => r.delPiloto) &&
        solicitud!.miNegociacion != MiNegociacion.vigente;
  }

  /// La oferta del piloto está en manos del cliente.
  bool get esperaAlCliente =>
      enviado == 'contraoferta' ||
      enviado == 'oferta' ||
      (enviado == null &&
          solicitud?.miNegociacion == MiNegociacion.vigente &&
          pendiente == null);

  bool get cerrada =>
      solicitud != null && solicitud!.miNegociacion == MiNegociacion.cerrada;

  /// La ronda que sigue, tal como la ve la persona: la del turno de quien
  /// debe responder (máximo 5; la quinta es definitiva).
  int get rondaActual =>
      ((rondas.isEmpty ? 0 : rondas.last.numero) + 1).clamp(1, rondasMaximas);

  static const rondasMaximas = 5;

  NegociacionEstado copiarCon({
    FaseNegociacion? fase,
    SolicitudAbierta? solicitud,
    List<RondaVista>? rondas,
    OfertaNegociada? Function()? pendiente,
    OfertaNegociada? Function()? ofertaMia,
    int? precio,
    bool? enviando,
    String? Function()? enviado,
    String? Function()? mensaje,
    bool? sinRed,
  }) => NegociacionEstado(
    fase: fase ?? this.fase,
    solicitud: solicitud ?? this.solicitud,
    rondas: rondas ?? this.rondas,
    pendiente: pendiente != null ? pendiente() : this.pendiente,
    ofertaMia: ofertaMia != null ? ofertaMia() : this.ofertaMia,
    precio: precio ?? this.precio,
    enviando: enviando ?? this.enviando,
    enviado: enviado != null ? enviado() : this.enviado,
    mensaje: mensaje != null ? mensaje() : this.mensaje,
    sinRed: sinRed ?? this.sinRed,
  );
}

/// La negociación de una solicitud vista como conversación. Aceptar y
/// contraofertar son llamadas directas, sin outbox (ADR 0016): la clave de
/// idempotencia nace al primer intento y se conserva si no hay red, así
/// reenviar devuelve la misma oferta. El servidor decide el turno y si la
/// oferta del cliente es la última; aquí solo se lee.
class NegociacionCubit extends Cubit<NegociacionEstado> {
  NegociacionCubit(
    this._mercado,
    this._negociacion,
    this._l10n, {
    required this.solicitudId,
    SolicitudAbierta? solicitud,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid(),
       super(NegociacionEstado(solicitud: solicitud));

  final AppLocalizations _l10n;
  final MercadoRepositorio _mercado;
  final NegociacionRepositorio _negociacion;
  final int solicitudId;
  final Uuid _uuid;
  String? _clave;

  Future<void> cargar() async {
    emit(state.copiarCon(fase: FaseNegociacion.cargando, mensaje: () => null));
    try {
      final resultados = await Future.wait([
        state.solicitud != null
            ? Future.value(state.solicitud!)
            : _mercado.detalle(solicitudId),
        _negociacion.misOfertas(),
      ]);
      if (isClosed) return;
      final solicitud = resultados[0] as SolicitudAbierta;
      final mias = [
        for (final o in resultados[1] as List<OfertaNegociada>)
          if (o.solicitudId == solicitudId) o,
      ]..sort((a, b) => a.numero.compareTo(b.numero));
      final pendiente = mias.where((o) => o.esperaMiRespuesta).lastOrNull;
      final rondas = [
        RondaVista(
          numero: 1,
          delPiloto: false,
          precioHa: solicitud.precioHaPropuesto,
          total: solicitud.montoPropuesto,
          publicado: true,
        ),
        for (final o in mias)
          RondaVista(
            numero: o.numero + 1,
            delPiloto: o.autor == AutorOferta.proveedor,
            precioHa: o.precioHa,
            total: o.monto,
            nota: o.nota,
          ),
      ];
      final referencia = pendiente?.precioHa ?? solicitud.precioHaPropuesto;
      emit(
        state.copiarCon(
          fase: FaseNegociacion.lista,
          solicitud: solicitud,
          rondas: rondas,
          pendiente: () => pendiente,
          ofertaMia: () => mias.where((o) => o.esperaAlCliente).lastOrNull,
          // El stepper arranca en el precio del cliente, redondeado al
          // boliviano: de ahí se sube o se baja de a uno.
          precio: state.precio > 0
              ? state.precio
              : referencia.round().toBigInt().toInt(),
        ),
      );
    } on SinConexion {
      if (!isClosed) emit(state.copiarCon(fase: FaseNegociacion.sinRed));
    } on OperacionRechazada catch (e) {
      if (!isClosed) {
        emit(
          state.copiarCon(
            fase: FaseNegociacion.error,
            mensaje: () => e.mensaje,
          ),
        );
      }
    }
  }

  void cambiarPrecio(int precio) {
    if (precio < 1 || state.enviando) return;
    emit(state.copiarCon(precio: precio, mensaje: () => null, sinRed: false));
  }

  /// Acepta lo último que dijo el cliente.
  Future<void> aceptar() => _enviar(() async {
    final pendiente = state.pendiente;
    if (pendiente != null) {
      await _negociacion.aceptar(pendiente.id);
      return 'adjudicada';
    } else {
      await _mercado.ofertar(
        solicitudId: solicitudId,
        uuidCliente: _clave ??= _uuid.v4(),
        tipo: TipoOferta.aceptaPropuesta,
      );
      return 'oferta';
    }
  });

  /// Retira la oferta propia mientras el cliente no responde.
  Future<void> retirar() async {
    final mia = state.ofertaMia;
    if (mia == null || state.enviando) return;
    emit(state.copiarCon(enviando: true, mensaje: () => null, sinRed: false));
    try {
      await _negociacion.retirar(mia.id);
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, enviado: () => 'retirada'));
      await _recargarRondas();
    } on SinConexion {
      if (isClosed) return;
      emit(
        state.copiarCon(
          enviando: false,
          sinRed: true,
          mensaje: () => _l10n.proveedorNegociacionRetiroReintentaCuandoTengas,
        ),
      );
    } on OperacionRechazada catch (e) {
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, mensaje: () => _explicar(e)));
    }
  }

  /// Rechaza la última oferta del cliente: cierra la negociación.
  Future<void> rechazar() => _enviar(() async {
    await _negociacion.rechazar(state.pendiente!.id);
    return 'rechazada';
  });

  /// Envía el precio del stepper como contraoferta.
  Future<void> enviar({String? nota}) => _enviar(() async {
    final precio = Decimal.fromInt(state.precio);
    final pendiente = state.pendiente;
    final clave = _clave ??= _uuid.v4();
    if (pendiente != null) {
      await _negociacion.contraofertar(
        pendiente.id,
        precioHa: precio,
        uuidCliente: clave,
        nota: nota,
      );
    } else {
      await _mercado.ofertar(
        solicitudId: solicitudId,
        uuidCliente: clave,
        tipo: TipoOferta.contraoferta,
        precioHa: precio,
        nota: nota,
      );
    }
    return 'contraoferta';
  });

  Future<void> _enviar(Future<String> Function() accion) async {
    if (state.enviando || !state.esMiTurno) return;
    emit(state.copiarCon(enviando: true, mensaje: () => null, sinRed: false));
    try {
      final resultado = await accion();
      _clave = null;
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, enviado: () => resultado));
      // Con lo que respondió el servidor se redibuja la conversación.
      await _recargarRondas();
    } on SinConexion {
      if (isClosed) return;
      // La clave se conserva: reintentar no crea una segunda oferta.
      emit(
        state.copiarCon(
          enviando: false,
          sinRed: true,
          mensaje: () => _l10n.proveedorNegociacionEnvioPrecioSigueAqui,
        ),
      );
    } on OperacionRechazada catch (e) {
      // Una respuesta del servidor cierra el intento: el próximo es nuevo.
      _clave = null;
      if (isClosed) return;
      emit(state.copiarCon(enviando: false, mensaje: () => _explicar(e)));
    }
  }

  Future<void> _recargarRondas() async {
    final enviado = state.enviado;
    final precio = state.precio;
    await cargar();
    if (isClosed) return;
    emit(state.copiarCon(enviado: () => enviado, precio: precio));
  }

  String _explicar(OperacionRechazada e) => switch (e.motivo) {
    'oferta_no_vigente' => _l10n.proveedorNegociacionEsaOfertaEstaVigente2,
    'solicitud_ya_adjudicada' =>
      _l10n.proveedorNegociacionClienteEligioOtroPiloto,
    'equipo_no_disponible' =>
      _l10n.proveedorNegociacionEquipoEstaDisponiblePara,
    _ => e.mensaje,
  };
}
