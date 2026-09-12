import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Comprime una imagen ya capturada a <300 KB (invariante 8 de CLAUDE.md),
/// antes de que `EvidenciaRepository` la persista y encole. Abstracta para
/// poder fakear en tests que no necesiten compresión real, mismo patrón que
/// `nucleo/linterna/linterna_controlador.dart`.
abstract class CompresorEvidencia {
  Future<Uint8List> comprimir(Uint8List bytesOriginales);
}

/// Envuelve `flutter_image_compress`. Configuración de calidad y tamaño
/// fija (`quality: 70`, `minWidth`/`minHeight: 1280`) — sin reintento de
/// calidad variable si el primer intento no llega a 300 KB, tal como pide
/// TE-07: ese ajuste fino queda para una tarea posterior, no bloqueante acá.
class CompresorEvidenciaFlutterImageCompress implements CompresorEvidencia {
  @override
  Future<Uint8List> comprimir(Uint8List bytesOriginales) {
    return FlutterImageCompress.compressWithList(
      bytesOriginales,
      minWidth: 1280,
      minHeight: 1280,
      quality: 70,
      format: CompressFormat.jpeg,
    );
  }
}
