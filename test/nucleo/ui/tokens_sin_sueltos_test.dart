// Las pantallas no declaran colores ni radios propios: usan los tokens de
// `lib/nucleo/ui` (DESIGN.md). Este test recorre `lib/` fuera de
// `nucleo/ui` y falla ante un color o radio literal.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final archivos = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.contains('lib/nucleo/ui/'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .toList();

  void sinCoincidencias(RegExp patron, String que) {
    final malos = <String>[];
    for (final f in archivos) {
      final lineas = f.readAsLinesSync();
      for (var i = 0; i < lineas.length; i++) {
        if (patron.hasMatch(lineas[i])) malos.add('${f.path}:${i + 1}');
      }
    }
    expect(malos, isEmpty, reason: '$que fuera de nucleo/ui: $malos');
  }

  test('ninguna pantalla declara un color literal', () {
    sinCoincidencias(RegExp(r'Color\(\s*0x|Color\.from'), 'Color literal');
  });

  test('ninguna pantalla declara un radio literal', () {
    sinCoincidencias(
      RegExp(r'Radius\.(circular|all)\(\s*[0-9]'),
      'Radio literal',
    );
  });
}
