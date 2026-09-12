import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// SHA-256 sobre los bytes YA COMPRIMIDOS de una evidencia (ADR 0009 de
/// `agrocom-api`), mandado como `hash_dispositivo` en `POST /api/evidencias`
/// — el servidor lo recalcula igual y rechaza si no coincide. Función pura,
/// sin estado ni dependencia de plataforma: no hace falta mock de
/// `MethodChannel` para testearla.
String calcularHashEvidencia(Uint8List bytes) =>
    sha256.convert(bytes).toString();
