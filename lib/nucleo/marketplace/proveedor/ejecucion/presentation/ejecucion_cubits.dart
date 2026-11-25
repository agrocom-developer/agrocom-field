import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../camara/selector_foto.dart';
import '../../../../evidencias/compresor_adaptativo.dart';
import '../../../dominio/dominio.dart';
import '../domain/ejecucion.dart';
import '../../../../../l10n/app_localizations.dart';

// ---------------------------------------------------------------- la lista

sealed class ServiciosLoteEstado {
  const ServiciosLoteEstado();
}

final class ServiciosLoteCargando extends ServiciosLoteEstado {
  const ServiciosLoteCargando();
}

final class ServiciosLoteError extends ServiciosLoteEstado {
  const ServiciosLoteError();
}

final class ServiciosLoteListos extends ServiciosLoteEstado {
  const ServiciosLoteListos(this.servicios);

  final List<ServicioEnLote> servicios;
}

/// Los servicios adjudicados del equipo. Lee solo de la base local; al
/// abrir pide al repositorio que suba lo pendiente y baje lo nuevo.
class ServiciosLoteCubit extends Cubit<ServiciosLoteEstado> {
  ServiciosLoteCubit(this._repositorio) : super(const ServiciosLoteCargando());

  final EjecucionRepositorio _repositorio;
  StreamSubscription<List<ServicioEnLote>>? _sub;

  void iniciar() {
    _sub?.cancel();
    _sub = _repositorio.observar().listen(
      (s) => emit(ServiciosLoteListos(s)),
      onError: (Object _) {
        if (!isClosed) emit(const ServiciosLoteError());
      },
    );
    unawaited(_repositorio.sincronizarAhora());
  }

  Future<void> actualizar() => _repositorio.sincronizarAhora();

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

// ----------------------------------------------------------------- detalle

class ServicioLoteEstado {
  const ServicioLoteEstado({
    this.servicio,
    this.cargando = true,
    this.ocupado = false,
    this.aviso,
    this.avisoEsError = false,
  });

  final ServicioEnLote? servicio;
  final bool cargando;

  /// Una acción (comprimir una foto, por ejemplo) está en curso.
  final bool ocupado;
  final String? aviso;
  final bool avisoEsError;

  ServicioLoteEstado copiarCon({
    ServicioEnLote? servicio,
    bool? cargando,
    bool? ocupado,
    String? Function()? aviso,
    bool? avisoEsError,
  }) => ServicioLoteEstado(
    servicio: servicio ?? this.servicio,
    cargando: cargando ?? this.cargando,
    ocupado: ocupado ?? this.ocupado,
    aviso: aviso != null ? aviso() : this.aviso,
    avisoEsError: avisoEsError ?? this.avisoEsError,
  );
}

/// Un servicio adjudicado en el lote: todo lo que el piloto hace se guarda
/// en el dispositivo y se sube cuando hay señal.
class ServicioLoteCubit extends Cubit<ServicioLoteEstado> {
  ServicioLoteCubit(
    this._repositorio,
    this.id,
    this._l10n, {
    SelectorFoto? selector,
  }) : _selector = selector,
       super(const ServicioLoteEstado());

  final AppLocalizations _l10n;
  final EjecucionRepositorio _repositorio;
  final int id;
  final SelectorFoto? _selector;
  StreamSubscription<ServicioEnLote?>? _sub;

  void iniciar() {
    _sub?.cancel();
    _sub = _repositorio.observarUno(id).listen((s) {
      emit(state.copiarCon(servicio: s, cargando: false));
    });
  }

  Future<void> iniciarServicio() => _guardar(
    () => _repositorio.iniciar(id),
    exito: _l10n.proveedorEjecucionMarcasteServicioEjecucion,
  );

  Future<void> marcarAvance({
    Decimal? hectareas,
    Decimal? porcentaje,
    String? nota,
    String? motivoCorreccion,
  }) => _guardar(
    () => _repositorio.marcarAvance(
      id,
      hectareas: hectareas,
      porcentaje: porcentaje,
      nota: nota,
      motivoCorreccion: motivoCorreccion,
    ),
    exito: _l10n.proveedorEjecucionAvanceGuardado,
  );

  Future<void> finalizar({
    required Decimal hectareasEjecutadas,
    String? nota,
  }) => _guardar(
    () => _repositorio.finalizar(
      id,
      hectareasEjecutadas: hectareasEjecutadas,
      nota: nota,
    ),
    exito: _l10n.proveedorEjecucionServicioFinalizadoPrecioPagar,
  );

  /// Abre la cámara, comprime la foto a menos de 300 KB y la encola.
  Future<void> tomarFotoDeAvance({
    TipoFotoEjecucion tipo = TipoFotoEjecucion.avance,
  }) async {
    final selector = _selector;
    if (selector == null || state.ocupado) return;
    final bytes = await selector.tomarFoto();
    if (bytes == null) return;
    await _guardar(
      () => _repositorio.adjuntarFoto(id, bytes, tipo: tipo),
      exito: _l10n.proveedorEjecucionFotoGuardadaSubeSola,
    );
  }

  Future<void> _guardar(
    Future<Object?> Function() accion, {
    required String exito,
  }) async {
    if (state.ocupado) return;
    emit(state.copiarCon(ocupado: true, aviso: () => null));
    try {
      await accion();
      if (isClosed) return;
      emit(
        state.copiarCon(
          ocupado: false,
          aviso: () => exito,
          avisoEsError: false,
        ),
      );
    } on FotoDemasiadoPesada {
      if (isClosed) return;
      emit(
        state.copiarCon(
          ocupado: false,
          aviso: () => _l10n.proveedorEjecucionPudimosAchicarFotoSuficiente,
          avisoEsError: true,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(
        state.copiarCon(
          ocupado: false,
          aviso: () => _l10n.proveedorEjecucionPudimosGuardarloIntentaNuevo,
          avisoEsError: true,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

// --------------------------------------------------------------- ubicación

enum FaseUbicacion {
  /// Todavía no se pidió: la pantalla explica el motivo.
  sinPedir,
  denegada,
  denegadaParaSiempre,
  servicioApagado,
  compartiendo,
}

class UbicacionEstado {
  const UbicacionEstado({
    this.fase = FaseUbicacion.sinPedir,
    this.ultimaEn,
    this.sinRed = false,
  });

  final FaseUbicacion fase;
  final DateTime? ultimaEn;
  final bool sinRed;
}

/// Publica la última ubicación del piloto cada 30 segundos mientras la
/// pantalla de un servicio en ejecución está abierta, y deja de hacerlo al
/// cerrarla o al finalizar el servicio (ADR 0016). Nada se guarda en el
/// dispositivo: sin red se omite la posición, no se encola.
class UbicacionCubit extends Cubit<UbicacionEstado> {
  UbicacionCubit(
    this._servicio,
    this._repositorio,
    this.solicitudId, {
    this.intervalo = const Duration(seconds: 30),
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now,
       super(const UbicacionEstado());

  final ServicioUbicacion _servicio;
  final UbicacionRepositorio _repositorio;
  final int solicitudId;
  final Duration intervalo;
  final DateTime Function() _reloj;
  Timer? _reloj0;

  /// Si el permiso ya estaba concedido, empieza a compartir sin preguntar;
  /// si no, queda a la espera de que el piloto lo acepte tras leer el motivo.
  Future<void> iniciar() async {
    final permiso = await _servicio.estado();
    if (isClosed) return;
    if (permiso == PermisoUbicacion.concedido) {
      _empezar();
    } else {
      emit(UbicacionEstado(fase: _fase(permiso)));
    }
  }

  /// El piloto aceptó compartir: recién ahora aparece el diálogo del sistema.
  Future<void> compartir() async {
    final permiso = await _servicio.pedir();
    if (isClosed) return;
    if (permiso == PermisoUbicacion.concedido) {
      _empezar();
    } else {
      emit(UbicacionEstado(fase: _fase(permiso)));
    }
  }

  void detener() {
    _reloj0?.cancel();
    _reloj0 = null;
    if (!isClosed && state.fase == FaseUbicacion.compartiendo) {
      emit(const UbicacionEstado(fase: FaseUbicacion.sinPedir));
    }
  }

  void _empezar() {
    emit(const UbicacionEstado(fase: FaseUbicacion.compartiendo));
    _reloj0?.cancel();
    _reloj0 = Timer.periodic(intervalo, (_) => _publicar());
    unawaited(_publicar());
  }

  Future<void> _publicar() async {
    final punto = await _servicio.actual();
    if (punto == null || isClosed) return;
    try {
      await _repositorio.publicar(solicitudId, punto);
      if (!isClosed) {
        emit(
          UbicacionEstado(fase: FaseUbicacion.compartiendo, ultimaEn: _reloj()),
        );
      }
    } on SinConexion {
      if (!isClosed) {
        emit(
          UbicacionEstado(
            fase: FaseUbicacion.compartiendo,
            ultimaEn: state.ultimaEn,
            sinRed: true,
          ),
        );
      }
    } on OperacionRechazada {
      // El servidor ya no acepta la posición (servicio cerrado o cancelado).
      detener();
    }
  }

  static FaseUbicacion _fase(PermisoUbicacion p) => switch (p) {
    PermisoUbicacion.denegadoParaSiempre => FaseUbicacion.denegadaParaSiempre,
    PermisoUbicacion.servicioApagado => FaseUbicacion.servicioApagado,
    PermisoUbicacion.denegado => FaseUbicacion.denegada,
    PermisoUbicacion.concedido => FaseUbicacion.compartiendo,
  };

  @override
  Future<void> close() {
    _reloj0?.cancel();
    return super.close();
  }
}
