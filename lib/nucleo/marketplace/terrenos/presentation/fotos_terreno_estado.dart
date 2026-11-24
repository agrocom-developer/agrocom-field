import 'dart:typed_data';

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
