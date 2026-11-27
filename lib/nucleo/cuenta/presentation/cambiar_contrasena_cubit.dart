import 'package:flutter_bloc/flutter_bloc.dart';

import '../../marketplace/dominio/falla.dart';
import '../domain/contrasena_repositorio.dart';

/// En qué paso va el cambio de contraseña.
enum PasoContrasena { canal, codigo, listo }

class CambiarContrasenaEstado {
  const CambiarContrasenaEstado({
    this.paso = PasoContrasena.canal,
    this.canal = CanalCodigo.whatsapp,
    this.destino,
    this.enviando = false,
    this.mensaje,
    this.sinConexion = false,
    this.codigoInvalido = false,
  });

  final PasoContrasena paso;
  final CanalCodigo canal;

  /// Adónde salió el código, enmascarado.
  final String? destino;
  final bool enviando;

  /// Error general para mostrar en un aviso, con qué hacer.
  final String? mensaje;
  final bool sinConexion;

  /// El código fue rechazado: se marca junto al campo del código.
  final bool codigoInvalido;

  CambiarContrasenaEstado copiar({
    PasoContrasena? paso,
    CanalCodigo? canal,
    String? destino,
    bool? enviando,
    String? mensaje,
    bool quitarMensaje = false,
    bool? sinConexion,
    bool? codigoInvalido,
  }) => CambiarContrasenaEstado(
    paso: paso ?? this.paso,
    canal: canal ?? this.canal,
    destino: destino ?? this.destino,
    enviando: enviando ?? this.enviando,
    mensaje: quitarMensaje ? null : mensaje ?? this.mensaje,
    sinConexion: sinConexion ?? this.sinConexion,
    codigoInvalido: codigoInvalido ?? this.codigoInvalido,
  );
}

/// Coordina el flujo: elegir canal, pedir el código, enviarlo con la
/// contraseña nueva. La contraseña y el código pasan por parámetro y no se
/// guardan en el estado.
class CambiarContrasenaCubit extends Cubit<CambiarContrasenaEstado> {
  CambiarContrasenaCubit(this._repositorio)
    : super(const CambiarContrasenaEstado());

  final ContrasenaRepositorio _repositorio;

  void elegirCanal(CanalCodigo canal) =>
      emit(state.copiar(canal: canal, quitarMensaje: true, sinConexion: false));

  Future<void> pedirCodigo() async {
    if (state.enviando) return;
    emit(state.copiar(enviando: true, quitarMensaje: true, sinConexion: false));
    try {
      final r = await _repositorio.pedirCodigo(state.canal);
      emit(
        state.copiar(
          paso: PasoContrasena.codigo,
          destino: r.destino,
          enviando: false,
          codigoInvalido: false,
        ),
      );
    } on SinConexion {
      emit(state.copiar(enviando: false, sinConexion: true, mensaje: _sinRed));
    } on OperacionRechazada catch (e) {
      emit(state.copiar(enviando: false, mensaje: _paraCanal(e)));
    }
  }

  Future<void> cambiar({
    required String codigo,
    required String passwordNueva,
  }) async {
    if (state.enviando) return;
    emit(
      state.copiar(
        enviando: true,
        quitarMensaje: true,
        sinConexion: false,
        codigoInvalido: false,
      ),
    );
    try {
      await _repositorio.cambiar(
        codigo: codigo.trim(),
        passwordNueva: passwordNueva,
      );
      emit(state.copiar(paso: PasoContrasena.listo, enviando: false));
    } on SinConexion {
      emit(state.copiar(enviando: false, sinConexion: true, mensaje: _sinRed));
    } on OperacionRechazada catch (e) {
      emit(
        state.copiar(
          enviando: false,
          codigoInvalido: e.motivo == 'codigo_invalido',
          mensaje: e.mensaje,
        ),
      );
    }
  }

  /// Vuelve a elegir el canal para pedir otro código.
  void pedirOtro() => emit(
    state.copiar(
      paso: PasoContrasena.canal,
      quitarMensaje: true,
      sinConexion: false,
      codigoInvalido: false,
    ),
  );

  static const _sinRed =
      'No hay conexión. Revisa tu señal y vuelve a intentarlo: lo que '
      'escribiste se conserva.';

  /// El `503` no trae mensaje propio en [OperacionRechazada]: se cambia por
  /// uno que diga qué hacer.
  static String _paraCanal(OperacionRechazada e) =>
      e.motivo == 'canal_no_disponible'
      ? 'Ese medio no está disponible ahora. Elige otro para recibir el código.'
      : e.mensaje;
}
