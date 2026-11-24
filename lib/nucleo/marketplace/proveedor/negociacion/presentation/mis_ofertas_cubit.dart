import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../dominio/dominio.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';

enum EstadoMisOfertas { cargando, listo, sinRed, error }

class MisOfertasEstado {
  const MisOfertasEstado({
    this.estado = EstadoMisOfertas.cargando,
    this.ofertas = const [],
    this.zonas = const {},
    this.enCurso,
    this.aviso,
    this.avisoEsError = false,
  });

  final EstadoMisOfertas estado;
  final List<OfertaNegociada> ofertas;

  /// Zona de cada solicitud, por id, para titular la tarjeta. Solo están las
  /// solicitudes que el mercado todavía muestra; el resto cae al número.
  final Map<int, String> zonas;

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

  MisOfertasEstado copiarCon({
    EstadoMisOfertas? estado,
    List<OfertaNegociada>? ofertas,
    Map<int, String>? zonas,
    int? Function()? enCurso,
    String? Function()? aviso,
    bool? avisoEsError,
  }) => MisOfertasEstado(
    estado: estado ?? this.estado,
    ofertas: ofertas ?? this.ofertas,
    zonas: zonas ?? this.zonas,
    enCurso: enCurso != null ? enCurso() : this.enCurso,
    aviso: aviso != null ? aviso() : this.aviso,
    avisoEsError: avisoEsError ?? this.avisoEsError,
  );
}

/// Mis ofertas y su negociación. Aceptar, contraofertar, rechazar y retirar
/// son llamadas directas, sin outbox (ADR 0016). El servidor decide quién
/// tiene el turno; la app solo habilita lo que cada oferta permite.
class MisOfertasCubit extends Cubit<MisOfertasEstado> {
  MisOfertasCubit(this._repositorio, {MercadoRepositorio? mercado, Uuid? uuid})
    : _mercado = mercado,
      _uuid = uuid ?? const Uuid(),
      super(const MisOfertasEstado());

  final NegociacionRepositorio _repositorio;
  final MercadoRepositorio? _mercado;
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
      await _cargarZonas();
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

  /// Titula cada oferta con la zona de su solicitud. Es un adorno de la
  /// tarjeta: si el mercado no responde, las ofertas siguen con su número.
  Future<void> _cargarZonas() async {
    final mercado = _mercado;
    if (mercado == null) return;
    try {
      final pagina = await mercado.solicitudes(const FiltrosMapa());
      if (isClosed) return;
      emit(
        state.copiarCon(
          zonas: {
            ...state.zonas,
            for (final s in pagina.solicitudes)
              if (s.zona != null) s.id: s.zona!,
          },
        ),
      );
    } on Object {
      // Sin zona: la tarjeta usa el número de solicitud.
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
