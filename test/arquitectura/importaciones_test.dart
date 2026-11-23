// Reglas de importación de la arquitectura (ADR 0005, invariante 7 de
// CLAUDE.md). Es parte del humo mínimo del CI: corre en todo PR.
//
// - `nucleo/` no importa de `features/` (salvo la raíz de composición
//   `nucleo/di/`).
// - `piloto/` y `auxiliar/` (si existen) no se importan entre sí.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _import = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Pares (archivo, uri) de cada import/export bajo [carpeta].
List<(String, String)> _imports(String carpeta) {
  final dir = Directory(carpeta);
  if (!dir.existsSync()) return const [];
  final salida = <(String, String)>[];
  for (final e in dir.listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    for (final m in _import.allMatches(e.readAsStringSync())) {
      salida.add((e.path, m.group(1)!));
    }
  }
  return salida;
}

void main() {
  test('nucleo/ no importa de features/', () {
    // `nucleo/di/` es la raíz de composición: es el único lugar de `nucleo/`
    // que conoce los repositorios de las features para registrarlos.
    final malos = _imports('lib/nucleo')
        .where((p) => !p.$1.replaceAll('\\', '/').startsWith('lib/nucleo/di/'))
        .where((p) => p.$2.contains('/features/') || p.$2.contains('features/'))
        .where(
          (p) =>
              p.$2.startsWith('package:agrocom_field/features/') ||
              p.$2.startsWith('../features/') ||
              p.$2.contains('../../features/'),
        )
        .toList();
    expect(malos, isEmpty, reason: 'nucleo/ depende de features/: $malos');
  });

  test('piloto/ y auxiliar/ no se importan entre sí', () {
    final malos = <String>[];
    for (final (de, a) in [('piloto', 'auxiliar'), ('auxiliar', 'piloto')]) {
      for (final raiz in ['lib/$de', 'lib/features/$de', 'lib/nucleo/$de']) {
        for (final (archivo, uri) in _imports(raiz)) {
          if (uri.contains('/$a/') || uri.startsWith('$a/')) {
            malos.add('$archivo -> $uri');
          }
        }
      }
    }
    expect(malos, isEmpty, reason: 'imports cruzados entre flavors: $malos');
  });
}
