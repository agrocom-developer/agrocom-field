// Pruebas del selector de pruebas por impacto (`tool/selector/`). Corren
// siempre (están en el humo mínimo): si el selector se rompe, el CI no puede
// fiarse de él.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/selector/grafo.dart';
import '../../tool/selector/selector.dart';

void main() {
  // Grafo de juguete:
  //   test/features/a/a_test.dart  -> lib/features/a/a_bloc.dart -> lib/nucleo/util.dart
  //   test/features/b/b_test.dart  -> lib/features/b/b_bloc.dart -> lib/nucleo/util.dart
  //   test/nucleo/otro/otro_test.dart -> lib/nucleo/otro.dart
  //   lib/nucleo/db/database.dart  <-> lib/nucleo/db/database.g.dart (part)
  final grafo = <String, Set<String>>{
    'test/features/a/a_test.dart': {'lib/features/a/a_bloc.dart'},
    'lib/features/a/a_bloc.dart': {'lib/nucleo/util.dart'},
    'test/features/b/b_test.dart': {'lib/features/b/b_bloc.dart'},
    'lib/features/b/b_bloc.dart': {'lib/nucleo/util.dart'},
    'test/nucleo/otro/otro_test.dart': {'lib/nucleo/otro.dart'},
    'lib/nucleo/otro.dart': <String>{},
    'lib/nucleo/util.dart': <String>{},
    'lib/nucleo/db/database.dart': {'lib/nucleo/db/database.g.dart'},
    'lib/nucleo/db/database.g.dart': {'lib/nucleo/db/database.dart'},
  };
  final existentes = <String>{...grafo.keys, ...pruebasHumo};

  Seleccion sel(List<String> cambiados) =>
      seleccionar(cambiados: cambiados, grafo: grafo, existentes: existentes);

  group('selección parcial', () {
    test('un cambio en una feature corre solo sus pruebas más el humo', () {
      final r = sel(['lib/features/a/a_bloc.dart']);
      expect(r.todo, isFalse);
      expect(r.pruebas, containsAll(['test/features/a/a_test.dart']));
      expect(r.pruebas, isNot(contains('test/features/b/b_test.dart')));
      expect(r.pruebas, isNot(contains('test/nucleo/otro/otro_test.dart')));
      expect(r.pruebas, containsAll(pruebasHumo));
    });

    test('un cambio en núcleo corre las pruebas de todos los dependientes', () {
      final r = sel(['lib/nucleo/util.dart']);
      expect(
        r.pruebas,
        containsAll([
          'test/features/a/a_test.dart',
          'test/features/b/b_test.dart',
        ]),
      );
      expect(r.pruebas, isNot(contains('test/nucleo/otro/otro_test.dart')));
    });

    test('un cambio en un archivo de prueba corre esa prueba', () {
      final r = sel(['test/nucleo/otro/otro_test.dart']);
      expect(r.todo, isFalse);
      expect(r.pruebas, contains('test/nucleo/otro/otro_test.dart'));
      expect(r.pruebas, isNot(contains('test/features/a/a_test.dart')));
    });

    test('una prueba borrada no se ejecuta', () {
      final r = sel(['test/features/zeta/borrada_test.dart']);
      expect(r.todo, isFalse);
      expect(
        r.pruebas,
        isNot(contains('test/features/zeta/borrada_test.dart')),
      );
    });

    test('un lib borrado sigue arrastrando a sus dependientes', () {
      final r = seleccionar(
        cambiados: ['lib/nucleo/util.dart'],
        grafo: grafo,
        existentes: existentes.difference({'lib/nucleo/util.dart'}),
      );
      expect(r.pruebas, contains('test/features/a/a_test.dart'));
    });

    test('solo documentación: queda únicamente el humo', () {
      final r = sel(['docs/gestion/ci-por-impacto.md', 'README.md']);
      expect(r.todo, isFalse);
      expect(r.pruebas, unorderedEquals([...pruebasHumo]..sort()));
    });

    test('un cambio en android/ suma las pruebas de test/android', () {
      final r = seleccionar(
        cambiados: ['android/app/src/main/AndroidManifest.xml'],
        grafo: grafo,
        existentes: {
          ...existentes,
          'test/android/manifest_seguridad_test.dart',
        },
      );
      expect(r.todo, isFalse);
      expect(r.pruebas, contains('test/android/manifest_seguridad_test.dart'));
    });

    test('la lista es estable: ordenada y sin repetidos', () {
      final r = sel(['lib/nucleo/util.dart', 'lib/features/a/a_bloc.dart']);
      expect(r.pruebas, orderedEquals([...r.pruebas]..sort()));
      expect(r.pruebas.toSet().length, r.pruebas.length);
    });

    test(
      'un cambio en el .g.dart (part) arrastra al host y a sus dependientes',
      () {
        final g = <String, Set<String>>{
          ...grafo,
          'test/nucleo/otro/db_uso_test.dart': {'lib/nucleo/db/database.dart'},
        };
        final r = seleccionar(
          cambiados: ['lib/nucleo/db/database.g.dart'],
          grafo: g,
          existentes: {...existentes, 'test/nucleo/otro/db_uso_test.dart'},
        );
        // lib/nucleo/db/ es zona crítica: corre todo.
        expect(r.todo, isTrue);
      },
    );
  });

  group('corre todo', () {
    const casos = {
      'pubspec.lock': 'lockfile',
      'pubspec.yaml': 'dependencias',
      'analysis_options.yaml': 'lints',
      'config/algo.json': 'config/',
      'lib/nucleo/db/database.dart': 'esquema',
      'lib/nucleo/db/tablas/orden.dart': 'esquema',
      'lib/nucleo/sync/sync_engine.dart': 'motor de sync',
      '.github/workflows/ci.yml': 'CI',
      'bin/verify': 'scripts',
      'tool/tests_afectados.dart': 'selector',
      'test/fixtures/sync_catalogo_respuesta.json': 'fixtures',
      'test/helpers/ayuda.dart': 'prueba compartida',
      'assets/fonts/Manrope.ttf': 'assets',
    };
    casos.forEach((ruta, porque) {
      test('$ruta ($porque)', () {
        final r = sel([ruta]);
        expect(r.todo, isTrue);
        expect(r.motivo, contains(ruta));
      });
    });

    test('un archivo no clasificado falla hacia la suite completa', () {
      expect(sel(['algo/raro.xyz']).todo, isTrue);
    });

    test('mezclar un cambio inocuo con uno crítico corre todo', () {
      expect(sel(['docs/vision.md', 'pubspec.lock']).todo, isTrue);
    });

    test('si falta una prueba de humo corre todo', () {
      final r = seleccionar(
        cambiados: ['docs/vision.md'],
        grafo: grafo,
        existentes: {...grafo.keys},
      );
      expect(r.todo, isTrue);
      expect(r.motivo, contains('humo'));
    });
  });

  group('grafo de imports', () {
    test('resuelve package:, relativos y part en ambos sentidos', () {
      const fuente = '''
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:agrocom_field/nucleo/util.dart';
import '../otro/relativo.dart' show Algo;
export 'sub/exportado.dart';
part 'host.g.dart';
''';
      final a = aristas('lib/features/x/host.dart', fuente);
      expect(a['lib/features/x/host.dart'], {
        'lib/nucleo/util.dart',
        'lib/features/otro/relativo.dart',
        'lib/features/x/sub/exportado.dart',
        'lib/features/x/host.g.dart',
      });
      expect(a['lib/features/x/host.g.dart'], {'lib/features/x/host.dart'});
    });

    test('toma todos los URIs de un import condicional', () {
      const fuente = '''
import 'stub.dart'
    if (dart.library.io) 'io.dart'
    if (dart.library.html) 'web.dart';
''';
      final a = aristas('lib/nucleo/x.dart', fuente);
      expect(a['lib/nucleo/x.dart'], {
        'lib/nucleo/stub.dart',
        'lib/nucleo/io.dart',
        'lib/nucleo/web.dart',
      });
    });

    test('part of apunta al host', () {
      final a = aristas('lib/a/parte.dart', "part of 'host.dart';");
      expect(a['lib/a/parte.dart'], {'lib/a/host.dart'});
    });
  });

  group('repo real', () {
    final raiz = Directory.current;
    final real = construirGrafo(raiz);
    final enDisco = real.keys
        .where((r) => File('${raiz.path}/$r').existsSync())
        .toSet();

    test('todas las pruebas de humo existen', () {
      for (final p in pruebasHumo) {
        expect(File('${raiz.path}/$p').existsSync(), isTrue, reason: p);
      }
    });

    test('un cambio en el repositorio de catálogo selecciona sus pruebas', () {
      final r = seleccionar(
        cambiados: ['lib/nucleo/catalogo/catalogo_repository.dart'],
        grafo: real,
        existentes: enDisco,
      );
      expect(r.todo, isFalse);
      expect(
        r.pruebas,
        contains('test/nucleo/catalogo/catalogo_repository_test.dart'),
      );
      expect(r.pruebas, containsAll(pruebasHumo));
    });
  });
}
