import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reglas de importación de ADR 0009 (arquitectura de las tres superficies
/// móviles). Recorre los `import`/`export` de `lib/` y falla si se viola una.
void main() {
  final lib = Directory('lib').absolute;
  final archivos = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final patron = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );

  /// Ruta relativa a `lib/` ('cliente/app_cliente.dart') de lo que importa
  /// [archivo]; ignora paquetes ajenos y `dart:`.
  List<String> importsDe(File archivo) {
    final resultado = <String>[];
    for (final m in patron.allMatches(archivo.readAsStringSync())) {
      final ruta = m.group(1)!;
      if (ruta.startsWith('dart:')) continue;
      if (ruta.startsWith('package:agrocom_field/')) {
        resultado.add(ruta.substring('package:agrocom_field/'.length));
      } else if (!ruta.startsWith('package:')) {
        final destino = archivo.uri.resolve(ruta).toFilePath();
        resultado.add(destino.substring(lib.path.length + 1));
      }
    }
    return resultado;
  }

  String relativa(File f) => f.path.substring(lib.path.length + 1);

  List<File> de(String carpeta) =>
      archivos.where((f) => relativa(f).startsWith('$carpeta/')).toList();

  const flavors = ['cliente', 'piloto', 'auxiliar'];

  for (final flavor in flavors) {
    test('lib/$flavor no importa a otro flavor', () {
      final otros = flavors.where((f) => f != flavor);
      final violaciones = [
        for (final f in de(flavor))
          for (final i in importsDe(f))
            if (otros.any((o) => i.startsWith('$o/'))) '${relativa(f)} -> $i',
      ];
      expect(violaciones, isEmpty);
    });
  }

  test('nucleo no importa de ningún flavor', () {
    final violaciones = [
      for (final f in de('nucleo'))
        for (final i in importsDe(f))
          if (flavors.any((fl) => i.startsWith('$fl/'))) '${relativa(f)} -> $i',
    ];
    expect(violaciones, isEmpty);
  });

  test('domain no importa de data ni de presentation', () {
    final violaciones = [
      for (final f in archivos)
        if (relativa(f).contains('/domain/') ||
            relativa(f).contains('/dominio/'))
          for (final i in importsDe(f))
            if (i.contains('/data/') || i.contains('/presentation/'))
              '${relativa(f)} -> $i',
    ];
    expect(violaciones, isEmpty);
  });

  // `lib/features/` (anterior al marketplace) se migra a los flavors feature
  // por feature; la regla rige para lo que ya vive en ellos.
  test('presentation no importa de data en los flavors', () {
    final violaciones = [
      for (final f in archivos)
        if (flavors.any((fl) => relativa(f).startsWith('$fl/')) &&
            relativa(f).contains('/presentation/'))
          for (final i in importsDe(f))
            if (i.contains('/data/')) '${relativa(f)} -> $i',
    ];
    expect(violaciones, isEmpty);
  });

  test('el flavor cliente no alcanza nucleo/sync ni nucleo/db', () {
    // Cierre transitivo desde el entrypoint: ni directa ni indirectamente.
    final visitados = <String>{};
    final cola = ['main_cliente.dart'];
    final camino = <String, String>{};
    while (cola.isNotEmpty) {
      final actual = cola.removeLast();
      if (!visitados.add(actual)) continue;
      final f = File('${lib.path}/$actual');
      if (!f.existsSync()) continue;
      for (final i in importsDe(f)) {
        camino.putIfAbsent(i, () => actual);
        cola.add(i);
      }
    }
    final prohibidos = visitados
        .where(
          (r) => r.startsWith('nucleo/sync/') || r.startsWith('nucleo/db/'),
        )
        .map((r) => '$r (importado por ${camino[r]})')
        .toList();
    expect(prohibidos, isEmpty);
  });

  test('lo demo no se importa desde nucleo salvo los datos compartidos', () {
    final violaciones = [
      for (final f in de('nucleo'))
        if (!relativa(f).startsWith('nucleo/marketplace/'))
          for (final i in importsDe(f))
            if (i.contains('/demo/')) '${relativa(f)} -> $i',
    ];
    expect(violaciones, isEmpty);
  });
}
