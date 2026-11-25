import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../dominio/dominio.dart';
import '../domain/negociacion.dart';
import '../domain/negociacion_repositorios.dart';
import '../../../../../l10n/app_localizations.dart';

class ChatEstado {
  const ChatEstado({
    this.cargando = true,
    this.mensajes = const [],
    this.soloLectura = false,
    this.enviando = false,
    this.aviso,
    this.sinRed = false,
  });

  final bool cargando;
  final List<MensajeChat> mensajes;
  final bool soloLectura;
  final bool enviando;
  final String? aviso;
  final bool sinRed;

  ChatEstado copiarCon({
    bool? cargando,
    List<MensajeChat>? mensajes,
    bool? soloLectura,
    bool? enviando,
    String? Function()? aviso,
    bool? sinRed,
  }) => ChatEstado(
    cargando: cargando ?? this.cargando,
    mensajes: mensajes ?? this.mensajes,
    soloLectura: soloLectura ?? this.soloLectura,
    enviando: enviando ?? this.enviando,
    aviso: aviso != null ? aviso() : this.aviso,
    sinRed: sinRed ?? this.sinRed,
  );
}

/// Chat con el cliente de una solicitud adjudicada. Mensajes de texto; se
/// actualiza cada pocos segundos mientras la pantalla está abierta (sin
/// servicio en segundo plano). El texto pendiente conserva su
/// `uuid_cliente` entre reintentos: reenviar no duplica el mensaje.
class ChatCubit extends Cubit<ChatEstado> {
  ChatCubit(
    this._repositorio,
    this.solicitudId,
    this._l10n, {
    Uuid? uuid,
    this.intervalo = const Duration(seconds: 8),
  }) : _uuid = uuid ?? const Uuid(),
       super(const ChatEstado());

  final AppLocalizations _l10n;
  final MensajesRepositorio _repositorio;
  final int solicitudId;
  final Uuid _uuid;
  final Duration intervalo;
  Timer? _reloj;
  String? _claveEnVuelo;
  String? _textoEnVuelo;

  Future<void> iniciar() async {
    await _actualizar();
    _reloj?.cancel();
    _reloj = Timer.periodic(intervalo, (_) => _actualizar());
  }

  Future<void> _actualizar() async {
    try {
      final pagina = await _repositorio.leer(solicitudId);
      if (isClosed) return;
      emit(
        state.copiarCon(
          cargando: false,
          mensajes: pagina.mensajes,
          soloLectura: pagina.soloLectura,
          sinRed: false,
        ),
      );
      final ultimoAjeno = pagina.mensajes.where((m) => !m.propio).lastOrNull;
      if (ultimoAjeno != null && !ultimoAjeno.leido) {
        unawaited(
          _repositorio
              .marcarLeidos(solicitudId, hasta: ultimoAjeno.id)
              .catchError((Object _) {}),
        );
      }
    } on SinConexion {
      if (!isClosed) emit(state.copiarCon(cargando: false, sinRed: true));
    } on OperacionRechazada catch (e) {
      if (!isClosed) {
        emit(state.copiarCon(cargando: false, aviso: () => e.mensaje));
      }
    }
  }

  /// Devuelve `true` si el mensaje quedó enviado (la pantalla vacía el
  /// campo); `false` conserva lo escrito.
  Future<bool> enviar(String texto) async {
    final limpio = texto.trim();
    if (limpio.isEmpty || state.enviando) return false;
    // Un texto distinto es un mensaje nuevo; el mismo reintenta con su clave.
    if (_textoEnVuelo != limpio) {
      _claveEnVuelo = null;
      _textoEnVuelo = limpio;
    }
    final clave = _claveEnVuelo ??= _uuid.v4();
    emit(state.copiarCon(enviando: true, aviso: () => null));
    try {
      await _repositorio.enviar(solicitudId, uuidCliente: clave, texto: limpio);
      _claveEnVuelo = null;
      _textoEnVuelo = null;
      if (isClosed) return true;
      emit(state.copiarCon(enviando: false));
      await _actualizar();
      return true;
    } on SinConexion {
      if (!isClosed) {
        emit(
          state.copiarCon(
            enviando: false,
            aviso: () => _l10n.proveedorNegociacionSinConexionMensajeSigue,
          ),
        );
      }
      return false;
    } on OperacionRechazada catch (e) {
      _claveEnVuelo = null;
      _textoEnVuelo = null;
      if (!isClosed) {
        emit(state.copiarCon(enviando: false, aviso: () => e.mensaje));
      }
      return false;
    }
  }

  @override
  Future<void> close() {
    _reloj?.cancel();
    return super.close();
  }
}
