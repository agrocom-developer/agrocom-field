import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../dominio/dominio.dart';
import '../../foto_preparador.dart';
import '../fotos_terreno_repositorio.dart';

/// Dónde está una foto del terreno.
enum SituacionFoto {
  /// Ya está en el servidor.
  guardada,

  /// Subiendo ahora.
  subiendo,

  /// Elegida para un terreno que todavía no existe: sale al publicar.
  pendiente,

  /// La subida falló; se puede reintentar o quitar.
  fallida,
}

class FotoDeTerreno {
  const FotoDeTerreno({
    required this.clave,
    required this.situacion,
    this.id,
    this.url,
    this.bytes,
  });

  /// Identifica la foto en la pantalla (la del servidor no la tiene hasta
  /// subir).
  final String clave;
  final SituacionFoto situacion;

  /// Id en el servidor, si ya subió.
  final int? id;

  /// URL firmada de corta vida de una foto del servidor.
  final String? url;

  /// La foto comprimida que se eligió en este celular.
  final Uint8List? bytes;

  FotoDeTerreno copiarCon({SituacionFoto? situacion, int? id, String? url}) =>
      FotoDeTerreno(
        clave: clave,
        situacion: situacion ?? this.situacion,
        id: id ?? this.id,
        url: url ?? this.url,
        bytes: bytes,
      );
}

class FotosTerrenoEstado {
  const FotosTerrenoEstado({
    this.fotos = const [],
    this.terrenoId,
    this.mensaje,
    this.esError = false,
    this.sinRed = false,
  });

  final List<FotoDeTerreno> fotos;

  /// El terreno al que se suben; `null` mientras es un contorno nuevo.
  final int? terrenoId;
  final String? mensaje;
  final bool esError;
  final bool sinRed;

  bool get lleno => fotos.length >= FotosTerrenoRepositorio.maximo;
  bool get ocupado => fotos.any((f) => f.situacion == SituacionFoto.subiendo);
  bool get hayFallidas =>
      fotos.any((f) => f.situacion == SituacionFoto.fallida);

  FotosTerrenoEstado copiarCon({
    List<FotoDeTerreno>? fotos,
    Object? terrenoId = _igual,
    Object? mensaje = _igual,
    bool? esError,
    bool? sinRed,
  }) => FotosTerrenoEstado(
    fotos: fotos ?? this.fotos,
    terrenoId: identical(terrenoId, _igual)
        ? this.terrenoId
        : terrenoId as int?,
    mensaje: identical(mensaje, _igual) ? this.mensaje : mensaje as String?,
    esError: esError ?? this.esError,
    sinRed: sinRed ?? this.sinRed,
  );
}

const _igual = Object();

/// Galería de hasta 8 fotos del terreno (ADR 0020), compartida por el
/// alta y la edición del lote del cliente.
///
/// Con un terreno ya guardado cada foto sube al elegirla. Con un contorno
/// nuevo todavía no hay terreno al que subir: las fotos quedan pendientes en
/// este celular y salen con [subirPendientes] cuando la solicitud se
/// publica y el terreno existe.
class FotosTerrenoCubit extends Cubit<FotosTerrenoEstado> {
  FotosTerrenoCubit(this._repositorio, this._preparador)
    : super(const FotosTerrenoEstado());

  final FotosTerrenoRepositorio _repositorio;
  final PreparadorFoto _preparador;

  final _porTerreno = <int, List<FotoDeTerreno>>{};
  var _pendientes = <FotoDeTerreno>[];
  var _siguiente = 0;

  String _clave() => 'foto-${_siguiente++}';

  /// Cambia el terreno sobre el que se trabaja: uno guardado (con sus
  /// [iniciales]) o `null` para el contorno nuevo.
  void usarTerreno(int? terrenoId, [List<FotoTerreno> iniciales = const []]) {
    final fotos = terrenoId == null
        ? _pendientes
        : _porTerreno.putIfAbsent(
            terrenoId,
            () => [
              for (final f in iniciales)
                FotoDeTerreno(
                  clave: 'servidor-${f.id}',
                  situacion: SituacionFoto.guardada,
                  id: f.id,
                  url: f.url,
                ),
            ],
          );
    emit(FotosTerrenoEstado(fotos: fotos, terrenoId: terrenoId));
  }

  void _guardarLista(List<FotoDeTerreno> fotos) {
    final id = state.terrenoId;
    if (id == null) {
      _pendientes = fotos;
    } else {
      _porTerreno[id] = fotos;
    }
  }

  void _emitir(
    List<FotoDeTerreno> fotos, {
    String? mensaje,
    bool error = false,
    bool sinRed = false,
  }) {
    _guardarLista(fotos);
    if (isClosed) return;
    emit(
      state.copiarCon(
        fotos: fotos,
        mensaje: mensaje,
        esError: error,
        sinRed: sinRed,
      ),
    );
  }

  /// Elige una foto, la comprime y, si el terreno ya existe, la sube.
  Future<void> agregar(OrigenFoto origen) async {
    if (state.lleno) {
      emit(
        state.copiarCon(
          mensaje:
              'Ya tienes ${FotosTerrenoRepositorio.maximo} fotos, el máximo. '
              'Quita una para agregar otra.',
          esError: true,
          sinRed: false,
        ),
      );
      return;
    }
    final terreno = state.terrenoId;
    try {
      final bytes = await _preparador.preparar(origen);
      if (bytes == null || isClosed) return;
      if (state.terrenoId != terreno) return;
      final nueva = FotoDeTerreno(
        clave: _clave(),
        situacion: terreno == null
            ? SituacionFoto.pendiente
            : SituacionFoto.subiendo,
        bytes: bytes,
      );
      _emitir([...state.fotos, nueva]);
      if (terreno != null) await _subir(nueva.clave);
    } on Object catch (e) {
      final f = describirFalla(
        e,
        porDefecto: 'No pudimos preparar la foto. Prueba con otra.',
      );
      if (!isClosed) {
        emit(
          state.copiarCon(mensaje: f.mensaje, esError: true, sinRed: f.sinRed),
        );
      }
    }
  }

  Future<void> _subir(String clave) async {
    final terreno = state.terrenoId;
    if (terreno == null) return;
    final foto = _buscar(terreno, clave);
    final bytes = foto?.bytes;
    if (foto == null || bytes == null) return;
    _cambiar(
      terreno,
      clave,
      (f) => f.copiarCon(situacion: SituacionFoto.subiendo),
    );
    try {
      final subida = await _repositorio.subir(terreno, bytes);
      _cambiar(
        terreno,
        clave,
        (f) => f.copiarCon(
          situacion: SituacionFoto.guardada,
          id: subida.id,
          url: subida.url,
        ),
        mensaje: 'Foto guardada.',
      );
    } on Object catch (e) {
      final falla = describirFalla(
        e,
        porDefecto: 'No pudimos subir la foto. Intenta de nuevo.',
      );
      _cambiar(
        terreno,
        clave,
        (foto) => foto.copiarCon(situacion: SituacionFoto.fallida),
        mensaje: falla.mensaje,
        error: true,
        sinRed: falla.sinRed,
      );
    }
  }

  FotoDeTerreno? _buscar(int terreno, String clave) {
    for (final f in _porTerreno[terreno] ?? const <FotoDeTerreno>[]) {
      if (f.clave == clave) return f;
    }
    return null;
  }

  void _cambiar(
    int terreno,
    String clave,
    FotoDeTerreno Function(FotoDeTerreno) cambio, {
    String? mensaje,
    bool error = false,
    bool sinRed = false,
  }) {
    final lista = [
      for (final f in _porTerreno[terreno] ?? const <FotoDeTerreno>[])
        f.clave == clave ? cambio(f) : f,
    ];
    _porTerreno[terreno] = lista;
    if (isClosed || state.terrenoId != terreno) return;
    emit(
      state.copiarCon(
        fotos: lista,
        mensaje: mensaje,
        esError: error,
        sinRed: sinRed,
      ),
    );
  }

  /// Repite la subida de una foto que falló.
  Future<void> reintentar(String clave) => _subir(clave);

  /// Quita una foto: del servidor si ya estaba guardada.
  Future<void> quitar(String clave) async {
    final terreno = state.terrenoId;
    final foto = [
      for (final f in state.fotos)
        if (f.clave == clave) f,
    ].firstOrNull;
    if (foto == null || foto.situacion == SituacionFoto.subiendo) return;
    final resto = [
      for (final f in state.fotos)
        if (f.clave != clave) f,
    ];
    if (terreno == null ||
        foto.id == null ||
        foto.situacion != SituacionFoto.guardada) {
      _emitir(resto, mensaje: 'Quitamos la foto.');
      return;
    }
    try {
      await _repositorio.borrar(terreno, foto.id!);
      _porTerreno[terreno] = resto;
      if (isClosed || state.terrenoId != terreno) return;
      emit(
        state.copiarCon(
          fotos: resto,
          mensaje: 'Quitamos la foto.',
          esError: false,
          sinRed: false,
        ),
      );
    } on OperacionRechazada catch (e) {
      // 404: ya no estaba en el servidor; la pantalla la quita igual.
      if (e.codigo == 404) {
        _porTerreno[terreno] = resto;
        if (!isClosed && state.terrenoId == terreno) {
          emit(state.copiarCon(fotos: resto, mensaje: null, esError: false));
        }
        return;
      }
      emit(state.copiarCon(mensaje: e.mensaje, esError: true, sinRed: false));
    } on Object catch (e) {
      final f = describirFalla(
        e,
        porDefecto: 'No pudimos quitar la foto. Intenta de nuevo.',
      );
      if (!isClosed) {
        emit(
          state.copiarCon(mensaje: f.mensaje, esError: true, sinRed: f.sinRed),
        );
      }
    }
  }

  /// Sube las fotos que se eligieron antes de que el terreno existiera.
  /// Devuelve cuántas no pudieron subir (el terreno ya está creado: el
  /// cliente las agrega luego desde el lote).
  Future<int> subirPendientes(int terrenoId) async {
    var fallidas = 0;
    for (final f in List.of(_pendientes)) {
      final bytes = f.bytes;
      if (bytes == null) continue;
      try {
        await _repositorio.subir(terrenoId, bytes);
      } on Object {
        fallidas++;
      }
    }
    _pendientes = [];
    return fallidas;
  }

  /// Cuántas fotos esperan terreno.
  int get pendientes => _pendientes.length;
}
