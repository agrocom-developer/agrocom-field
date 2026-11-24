import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../foto_preparador.dart';
import '../foto_perfil_repositorio.dart';

enum FaseFotoPerfil { cargando, lista, trabajando }

/// Qué se estaba haciendo cuando algo falló, para reintentar lo mismo.
enum _Intento { subir, quitar }

class FotoPerfilEstado {
  const FotoPerfilEstado({
    this.fase = FaseFotoPerfil.cargando,
    this.url,
    this.bytes,
    this.mensaje,
    this.esError = false,
    this.sinRed = false,
    this.puedeReintentar = false,
  });

  final FaseFotoPerfil fase;

  /// La foto que tiene la cuenta, por URL firmada (corta vida).
  final String? url;

  /// La foto recién subida, para mostrarla sin volver a descargarla.
  final Uint8List? bytes;

  /// Resultado de la última acción: éxito o error, en español.
  final String? mensaje;
  final bool esError;
  final bool sinRed;
  final bool puedeReintentar;

  bool get tieneFoto => bytes != null || (url != null && url!.isNotEmpty);
  bool get trabajando => fase == FaseFotoPerfil.trabajando;

  FotoPerfilEstado copiarCon({
    FaseFotoPerfil? fase,
    Object? url = _igual,
    Object? bytes = _igual,
    Object? mensaje = _igual,
    bool? esError,
    bool? sinRed,
    bool? puedeReintentar,
  }) => FotoPerfilEstado(
    fase: fase ?? this.fase,
    url: identical(url, _igual) ? this.url : url as String?,
    bytes: identical(bytes, _igual) ? this.bytes : bytes as Uint8List?,
    mensaje: identical(mensaje, _igual) ? this.mensaje : mensaje as String?,
    esError: esError ?? this.esError,
    sinRed: sinRed ?? this.sinRed,
    puedeReintentar: puedeReintentar ?? this.puedeReintentar,
  );
}

const _igual = Object();

/// Elegir, cambiar y quitar la foto de perfil de la cuenta (ADR 0020). Todo
/// va en línea: la foto sale comprimida a menos de 300 KB y un fallo deja
/// la foto anterior y ofrece reintentar lo mismo.
class FotoPerfilCubit extends Cubit<FotoPerfilEstado> {
  FotoPerfilCubit(this._repositorio, this._preparador, {String? urlInicial})
    : super(
        FotoPerfilEstado(
          fase: urlInicial == null
              ? FaseFotoPerfil.cargando
              : FaseFotoPerfil.lista,
          url: urlInicial,
        ),
      );

  final FotoPerfilRepositorio _repositorio;
  final PreparadorFoto _preparador;

  Uint8List? _porSubir;
  _Intento? _ultimo;

  /// Lee la foto actual de la cuenta. Sin ella (o sin red) quedan las
  /// iniciales: la foto es opcional y no bloquea nada.
  Future<void> cargar() async {
    try {
      final url = await _repositorio.actual();
      if (isClosed) return;
      emit(state.copiarCon(fase: FaseFotoPerfil.lista, url: url));
    } on Object {
      if (isClosed) return;
      emit(state.copiarCon(fase: FaseFotoPerfil.lista));
    }
  }

  /// Elige una foto, la comprime y la sube.
  Future<void> elegir(OrigenFoto origen) async {
    if (state.trabajando) return;
    emit(state.copiarCon(fase: FaseFotoPerfil.trabajando, mensaje: null));
    try {
      final bytes = await _preparador.preparar(origen);
      if (bytes == null) {
        if (!isClosed) emit(state.copiarCon(fase: FaseFotoPerfil.lista));
        return;
      }
      _porSubir = bytes;
      await _subir();
    } on Object catch (e) {
      _fallo(e, 'No pudimos preparar la foto. Prueba con otra.', null);
    }
  }

  /// Quita la foto de la cuenta.
  Future<void> quitar() async {
    if (state.trabajando) return;
    _ultimo = _Intento.quitar;
    emit(state.copiarCon(fase: FaseFotoPerfil.trabajando, mensaje: null));
    try {
      await _repositorio.quitar();
      if (isClosed) return;
      emit(
        state.copiarCon(
          fase: FaseFotoPerfil.lista,
          url: null,
          bytes: null,
          mensaje: 'Quitamos tu foto. Verás tus iniciales.',
          esError: false,
          puedeReintentar: false,
        ),
      );
    } on Object catch (e) {
      _fallo(
        e,
        'No pudimos quitar la foto. Intenta de nuevo.',
        _Intento.quitar,
      );
    }
  }

  /// Repite lo último que falló, con la misma foto.
  Future<void> reintentar() async {
    if (state.trabajando) return;
    switch (_ultimo) {
      case _Intento.subir:
        emit(state.copiarCon(fase: FaseFotoPerfil.trabajando, mensaje: null));
        await _subir();
      case _Intento.quitar:
        await quitar();
      case null:
        return;
    }
  }

  Future<void> _subir() async {
    final bytes = _porSubir;
    if (bytes == null) return;
    _ultimo = _Intento.subir;
    try {
      final url = await _repositorio.subir(bytes);
      if (isClosed) return;
      _porSubir = null;
      emit(
        state.copiarCon(
          fase: FaseFotoPerfil.lista,
          url: url,
          bytes: bytes,
          mensaje: 'Listo: tu foto de perfil está actualizada.',
          esError: false,
          sinRed: false,
          puedeReintentar: false,
        ),
      );
    } on Object catch (e) {
      _fallo(e, 'No pudimos subir la foto. Intenta de nuevo.', _Intento.subir);
    }
  }

  void _fallo(Object error, String porDefecto, _Intento? reintento) {
    if (isClosed) return;
    final f = describirFalla(error, porDefecto: porDefecto);
    _ultimo = reintento;
    emit(
      state.copiarCon(
        fase: FaseFotoPerfil.lista,
        mensaje: f.mensaje,
        esError: true,
        sinRed: f.sinRed,
        puedeReintentar: reintento != null,
      ),
    );
  }
}
