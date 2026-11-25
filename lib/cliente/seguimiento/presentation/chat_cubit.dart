import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';

enum FaseChat { cargando, lista, error }

/// Por qué no salió un mensaje.
enum FalloMensaje { sinConexion, cerrado, desconocido }

class ChatEstado {
  const ChatEstado({
    required this.fase,
    this.mensajes = const [],
    this.cursor,
    this.soloLectura = false,
    this.enviando = false,
    this.fallo,
    this.sinConexion = false,
  });

  final FaseChat fase;
  final List<MensajeChat> mensajes;
  final String? cursor;

  /// El plazo del chat cerró: se lee, no se escribe.
  final bool soloLectura;
  final bool enviando;
  final FalloMensaje? fallo;

  /// La última lectura falló por falta de red.
  final bool sinConexion;

  ChatEstado copiarCon({
    FaseChat? fase,
    List<MensajeChat>? mensajes,
    String? cursor,
    bool? soloLectura,
    bool? enviando,
    Object? fallo = _igual,
    bool? sinConexion,
  }) => ChatEstado(
    fase: fase ?? this.fase,
    mensajes: mensajes ?? this.mensajes,
    cursor: cursor ?? this.cursor,
    soloLectura: soloLectura ?? this.soloLectura,
    enviando: enviando ?? this.enviando,
    fallo: identical(fallo, _igual) ? this.fallo : fallo as FalloMensaje?,
    sinConexion: sinConexion ?? this.sinConexion,
  );
}

const _igual = Object();

/// Chat entre el cliente y el piloto adjudicado. Texto solamente: las fotos
/// viajan como evidencia de avance. El cliente escribe en línea; la lectura
/// es por cursor con sondeo corto mientras el chat está abierto
/// (cada [intervalo]; ADR 0017).
class ChatCubit extends Cubit<ChatEstado> {
  ChatCubit({
    required SeguimientoRepositorio repositorio,
    required this.solicitudId,
    Duration? intervalo = const Duration(seconds: 5),
    Uuid? uuid,
  }) : _repositorio = repositorio,
       _uuid = uuid ?? const Uuid(),
       super(const ChatEstado(fase: FaseChat.cargando)) {
    if (intervalo != null) {
      _temporizador = Timer.periodic(intervalo, (_) => unawaited(_leer()));
    }
  }

  final SeguimientoRepositorio _repositorio;
  final String solicitudId;
  final Uuid _uuid;
  Timer? _temporizador;
  var _leyendo = false;

  /// Clave del mensaje que se está enviando: un reintento tras perder la
  /// respuesta crea un solo mensaje.
  String? _claveActual;
  String? _textoActual;
  Uint8List? _bytesActuales;
  String? _claveFoto;

  Future<void> cargar() async {
    if (state.fase != FaseChat.lista) {
      emit(state.copiarCon(fase: FaseChat.cargando));
    }
    await _leer();
  }

  /// Vuelve a leer los mensajes nuevos (el sondeo y deslizar para actualizar).
  Future<void> actualizar() => _leer();

  Future<void> _leer() async {
    if (isClosed || _leyendo) return;
    _leyendo = true;
    try {
      final pagina = await _repositorio.mensajes(
        solicitudId,
        despues: state.cursor,
      );
      if (isClosed) return;
      final conocidos = {for (final m in state.mensajes) m.id};
      final nuevos = [
        for (final m in pagina.mensajes)
          if (!conocidos.contains(m.id)) m,
      ];
      emit(
        state.copiarCon(
          fase: FaseChat.lista,
          mensajes: [...state.mensajes, ...nuevos],
          cursor: pagina.cursor,
          soloLectura: pagina.soloLectura,
          sinConexion: false,
        ),
      );
      final cursor = pagina.cursor;
      if (nuevos.any((m) => !m.propio) && cursor != null) {
        unawaited(_marcarLeidos(cursor));
      }
    } on Object catch (e) {
      if (isClosed) return;
      emit(
        state.copiarCon(
          fase: state.fase == FaseChat.lista ? FaseChat.lista : FaseChat.error,
          sinConexion: e is SinConexion,
        ),
      );
    } finally {
      _leyendo = false;
    }
  }

  Future<void> _marcarLeidos(String cursor) async {
    try {
      await _repositorio.marcarLeidos(solicitudId, cursor);
    } on Object {
      // Marcar como leído es un extra: se reintenta con la próxima lectura.
    }
  }

  /// Envía [texto]. Devuelve `true` si el servidor lo confirmó; con `false`
  /// el campo conserva lo escrito para reintentar.
  Future<bool> enviar(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || state.enviando || state.soloLectura) return false;
    // Reintentar el mismo texto reutiliza la clave; otro texto, una nueva.
    if (_textoActual != limpio) {
      _textoActual = limpio;
      _claveActual = _uuid.v4();
    }
    emit(state.copiarCon(enviando: true, fallo: null));
    try {
      final mensaje = await _repositorio.enviarMensaje(
        solicitudId,
        texto: limpio,
        claveCliente: _claveActual!,
      );
      if (isClosed) return true;
      _textoActual = null;
      _claveActual = null;
      final conocidos = {for (final m in state.mensajes) m.id};
      emit(
        state.copiarCon(
          enviando: false,
          mensajes: conocidos.contains(mensaje.id)
              ? state.mensajes
              : [...state.mensajes, mensaje],
          // El cursor no avanza: la próxima lectura trae lo que el piloto
          // escribió antes de este mensaje, y los repetidos se descartan.
        ),
      );
      return true;
    } on ChatCerrado {
      if (!isClosed) {
        emit(
          state.copiarCon(
            enviando: false,
            soloLectura: true,
            fallo: FalloMensaje.cerrado,
          ),
        );
      }
    } on SinConexion {
      if (!isClosed) {
        emit(state.copiarCon(enviando: false, fallo: FalloMensaje.sinConexion));
      }
    } on Object {
      if (!isClosed) {
        emit(state.copiarCon(enviando: false, fallo: FalloMensaje.desconocido));
      }
    }
    return false;
  }

  /// Envía una foto ya comprimida a menos de 300 KB. Un reintento con los
  /// mismos bytes reutiliza la clave: el servidor devuelve el mismo mensaje.
  Future<bool> enviarFoto(Uint8List bytes, {String? pie}) async {
    if (state.enviando || state.soloLectura) return false;
    if (!identical(_bytesActuales, bytes)) {
      _bytesActuales = bytes;
      _claveFoto = _uuid.v4();
    }
    emit(state.copiarCon(enviando: true, fallo: null));
    try {
      final mensaje = await _repositorio.enviarFoto(
        solicitudId,
        bytes: bytes,
        claveCliente: _claveFoto!,
        pie: pie,
      );
      if (isClosed) return true;
      _bytesActuales = null;
      _claveFoto = null;
      final conocidos = {for (final m in state.mensajes) m.id};
      emit(
        state.copiarCon(
          enviando: false,
          mensajes: conocidos.contains(mensaje.id)
              ? state.mensajes
              : [...state.mensajes, mensaje],
        ),
      );
      return true;
    } on ChatCerrado {
      if (!isClosed) {
        emit(
          state.copiarCon(
            enviando: false,
            soloLectura: true,
            fallo: FalloMensaje.cerrado,
          ),
        );
      }
    } on SinConexion {
      if (!isClosed) {
        emit(state.copiarCon(enviando: false, fallo: FalloMensaje.sinConexion));
      }
    } on Object {
      if (!isClosed) {
        emit(state.copiarCon(enviando: false, fallo: FalloMensaje.desconocido));
      }
    }
    return false;
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
