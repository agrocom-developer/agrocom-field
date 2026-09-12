import 'dart:convert';
import 'dart:typed_data';

import 'package:agrocom_field/nucleo/evidencias/hash_evidencia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula el SHA-256 correcto sobre los bytes recibidos', () {
    final bytes = Uint8List.fromList(utf8.encode('contenido de prueba'));

    final hash = calcularHashEvidencia(bytes);

    // Valor de referencia: `echo -n "contenido de prueba" | shasum -a 256`.
    expect(
      hash,
      'f3a7a67ab20351ddf47e87ecbf0e5a0868fc0e257d0aea65d018b0405b9a34f3',
    );
  });

  test('bytes distintos producen hashes distintos', () {
    final hashA = calcularHashEvidencia(Uint8List.fromList([1, 2, 3]));
    final hashB = calcularHashEvidencia(Uint8List.fromList([1, 2, 4]));

    expect(hashA, isNot(hashB));
  });

  test('los mismos bytes producen siempre el mismo hash (determinismo)', () {
    final bytes = Uint8List.fromList([9, 8, 7, 6]);

    expect(calcularHashEvidencia(bytes), calcularHashEvidencia(bytes));
  });
}
