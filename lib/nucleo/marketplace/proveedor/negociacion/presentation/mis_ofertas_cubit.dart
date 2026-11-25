import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../dominio/dominio.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';

enum EstadoMisOfertas { cargando, listo, sinRed, error }

/// Todas las rondas de una solicitud, de la más vieja a la más nueva. La
/// pantalla muestra una tarjeta por negociación, no una por oferta.
class ResumenNegociacion {
  const ResumenNegociacion(this.filas);

  final List<OfertaNegociada> filas;

  int get solicitudId => filas.last.solicitudId;
  OfertaNegociada get ultima => filas.last;
  String? get zona => filas.map((o) => o.zona).whereType<String>().lastOrNull;

  /// Lo último que pidió el cliente y lo último que ofreció el piloto.
  OfertaNegociada? get ultimaDelCliente =>
      filas.where((o) => o.autor == AutorOferta.cliente).lastOrNull;
  OfertaNegociada? get ultimaMia =>
      filas.where((o) => o.autor == AutorOferta.proveedor).lastOrNull;

  bool get esMiTurno => ultima.esperaMiRespuesta;
  bool get esperaAlCliente => ultima.esperaAlCliente;
  bool get activa => ultima.estado == EstadoOferta.vigente;
  bool get ganada => ultima.estado == EstadoOferta.aceptada;

  /// La ronda que sigue, como la ve la persona: la R1 es la solicitud
  /// publicada, así que la ronda del servidor `n` es la `n + 1` y sigue la
  /// `n + 2` (máximo 5).
  int get rondaQueSigue => (ultima.numero + 2).clamp(1, 5);
}

class MisOfertasEstado {
  const MisOfertasEstado({
    this.estado = EstadoMisOfertas.cargando,
    this.ofertas = const [],
    this.enCurso,
    this.aviso,
    this.avisoEsError = false,
  });

  final EstadoMisOfertas estado;
  final List<OfertaNegociada> ofertas;

  /// La oferta sobre la que hay una acción en vuelo.
  final int? enCurso;
  final String? aviso;
  final bool avisoEsError;

  /// Las que piden una respuesta, luego las vigentes mías, luego el resto.
  List<OfertaNegociada> get ordenadas {
    int peso(OfertaNegociada o) => o.esperaMiRespuesta
        ? 0
        : o.esperaAlCliente
        ? 1
        : o.estado == EstadoOferta.aceptada
        ? 2
        : 3;
    final indices = {for (var i = 0; i < ofertas.length; i++) ofertas[i].id: i};
    return [...ofertas]..sort((a, b) {
      final p = peso(a).compareTo(peso(b));
      return p != 0 ? p : indices[a.id]!.compareTo(indices[b.id]!);
    });
  }

  /// Una entrada por solicitud: primero las que piden tu respuesta, luego
  /// las que esperan al cliente, luego el resto, de lo nuevo a lo viejo.
  List<ResumenNegociacion> get negociaciones {
    final porSolicitud = <int, List<OfertaNegociada>>{};
    for (final o in ofertas) {
      porSolicitud.putIfAbsent(o.solicitudId, () => []).add(o);
    }
    final lista = [
      for (final filas in porSolicitud.values)
        ResumenNegociacion(
          [...filas]..sort((a, b) => a.numero.compareTo(b.numero)),
        ),
    ];
    int peso(ResumenNegociacion r) => r.esMiTurno
        ? 0
        : r.esperaAlCliente
        ? 1
        : r.ganada
        ? 2
        : 3;
    final orden = {for (var i = 0; i < lista.length; i++) lista[i]: i};
    return lista..sort((a, b) {
      final p = peso(a).compareTo(peso(b));
      return p != 0 ? p : orden[a]!.compareTo(orden[b]!);
    });
  }

  List<ResumenNegociacion> get activas => [
    for (final n in negociaciones)
      if (n.activa) n,
  ];
  List<ResumenNegociacion> get ganadas => [
    for (final n in negociaciones)
      if (n.ganada) n,
  ];
  List<ResumenNegociacion> get cerradas => [
    for (final n in negociaciones)
      if (!n.activa && !n.ganada) n,
  ];

  MisOfertasEstado copiarCon({
    EstadoMisOfertas? estado,
    List<OfertaNegociada>? ofertas,
    int? Function()? enCurso,
    String? Function()? aviso,
    bool? avisoEsError,
  }) => MisOfertasEstado(
    estado: estado ?? this.estado,
    ofertas: ofertas ?? this.ofertas,
    enCurso: enCurso != null ? enCurso() : this.enCurso,
    aviso: aviso != null ? aviso() : this.aviso,
    avisoEsError: avisoEsError ?? this.avisoEsError,
  );
}

/// Mis ofertas y su negociación. Aceptar, contraofertar, rechazar y retirar
/// son llamadas directas, sin outbox (ADR 0016). El servidor decide quién
/// tiene el turno; la app solo habilita lo que cada oferta permite.
class MisOfertasCubit extends Cubit<MisOfertasEstado> {
  MisOfertasCubit(this._repositorio, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid(),
      super(const MisOfertasEstado());

  final NegociacionRepositorio _repositorio;
  final Uuid _uuid;

  /// Una clave por oferta respondida, conservada entre reintentos.
  final _claves = <int, String>{};

  Future<void> cargar() async {
    try {
      final ofertas = await _repositorio.misOfertas();
      if (isClosed) return;
      emit(
        state.copiarCon(
          estado: EstadoMisOfertas.listo,
          ofertas: ofertas,
          enCurso: () => null,
        ),
      );
    } on SinConexion {
      if (isClosed) return;
      // Con ofertas ya en pantalla se conservan y solo se avisa.
      emit(
        state.ofertas.isEmpty
            ? state.copiarCon(estado: EstadoMisOfertas.sinRed)
            : state.copiarCon(
                aviso: () => 'Sin conexión: puede que lo que ves esté viejo.',
                avisoEsError: true,
              ),
      );
    } on OperacionRechazada catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          estado: EstadoMisOfertas.error,
          aviso: () => e.mensaje,
          avisoEsError: true,
        ),
      );
    }
  }

  Future<void> aceptar(OfertaNegociada o) => _ejecutar(
    o,
    () => _repositorio.aceptar(o.id),
    exito: '¡Listo! El cliente te eligió. Ya puedes escribirle desde Servicio.',
  );

  Future<void> rechazar(OfertaNegociada o) => _ejecutar(
    o,
    () => _repositorio.rechazar(o.id),
    exito: 'Rechazaste la oferta del cliente.',
  );

  Future<void> retirar(OfertaNegociada o) => _ejecutar(
    o,
    () => _repositorio.retirar(o.id),
    exito: 'Retiraste tu oferta.',
  );

  Future<void> contraofertar(
    OfertaNegociada o, {
    required Decimal precioHa,
    String? nota,
  }) {
    final clave = _claves.putIfAbsent(o.id, _uuid.v4);
    return _ejecutar(
      o,
      () => _repositorio.contraofertar(
        o.id,
        precioHa: precioHa,
        uuidCliente: clave,
        nota: nota,
      ),
      exito: 'Enviaste tu contraoferta.',
      alTerminar: () => _claves.remove(o.id),
    );
  }

  Future<void> _ejecutar(
    OfertaNegociada o,
    Future<OfertaNegociada> Function() accion, {
    required String exito,
    void Function()? alTerminar,
  }) async {
    if (state.enCurso != null) return;
    emit(state.copiarCon(enCurso: () => o.id, aviso: () => null));
    try {
      await accion();
      alTerminar?.call();
      if (isClosed) return;
      emit(
        state.copiarCon(
          aviso: () => exito,
          avisoEsError: false,
          enCurso: () => null,
        ),
      );
      await cargar();
    } on SinConexion {
      if (isClosed) return;
      // La clave de la contraoferta se conserva: reenviar es idempotente.
      emit(
        state.copiarCon(
          enCurso: () => null,
          aviso: () =>
              'No hay conexión. No se envió nada: reintenta con señal.',
          avisoEsError: true,
        ),
      );
    } on OperacionRechazada catch (e) {
      alTerminar?.call();
      if (isClosed) return;
      emit(
        state.copiarCon(
          enCurso: () => null,
          aviso: () => _explicar(e),
          avisoEsError: true,
        ),
      );
      // Lo que falló casi siempre cambió en el servidor: se recarga.
      await cargar();
    }
  }

  static String _explicar(OperacionRechazada e) => switch (e.motivo) {
    'oferta_no_vigente' =>
      'Esa oferta ya no está vigente: el cliente respondió o venció. '
          'Actualizamos tu lista.',
    'solicitud_ya_adjudicada' =>
      'El cliente ya eligió a otro piloto para esta solicitud.',
    'equipo_no_disponible' =>
      'Tu equipo no está disponible para esas fechas. Revisa tus drones.',
    _ => e.mensaje,
  };
}
