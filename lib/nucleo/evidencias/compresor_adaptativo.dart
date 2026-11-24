import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'compresor_evidencia.dart';

/// Tope de una foto subida: 300 KB (invariante 7 de CLAUDE.md).
const topeBytesEvidencia = 300 * 1024;

/// Una pasada de compresión: lado máximo en píxeles y calidad JPEG.
typedef PasadaCompresion =
    Future<Uint8List> Function(Uint8List bytes, int lado, int calidad);

/// Comprime una foto hasta que pese menos de [topeBytesEvidencia]: prueba
/// una escalera de lado y calidad, de menos a más agresiva, y se detiene en
/// la primera que cabe. Si ninguna cabe, lanza [FotoDemasiadoPesada] en vez
/// de subir un archivo que el servidor rechazaría.
class CompresorEvidenciaAdaptativo implements CompresorEvidencia {
  CompresorEvidenciaAdaptativo({PasadaCompresion? pasada})
    : _pasada = pasada ?? _conPlugin;

  final PasadaCompresion _pasada;

  static const escalera = <(int lado, int calidad)>[
    (1280, 70),
    (1280, 55),
    (1024, 50),
    (800, 45),
    (640, 40),
  ];

  static Future<Uint8List> _conPlugin(Uint8List bytes, int lado, int calidad) {
    return FlutterImageCompress.compressWithList(
      bytes,
      minWidth: lado,
      minHeight: lado,
      quality: calidad,
      format: CompressFormat.jpeg,
    );
  }

  @override
  Future<Uint8List> comprimir(Uint8List bytesOriginales) async {
    Uint8List? ultimo;
    for (final (lado, calidad) in escalera) {
      ultimo = await _pasada(bytesOriginales, lado, calidad);
      if (ultimo.lengthInBytes < topeBytesEvidencia) return ultimo;
    }
    throw FotoDemasiadoPesada(ultimo?.lengthInBytes ?? bytesOriginales.length);
  }
}

class FotoDemasiadoPesada implements Exception {
  const FotoDemasiadoPesada(this.bytes);

  final int bytes;

  @override
  String toString() => 'FotoDemasiadoPesada($bytes bytes)';
}
