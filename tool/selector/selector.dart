// Selector de pruebas por impacto de agrocom-field.
//
// Dado el conjunto de archivos cambiados y el grafo de imports de `lib/` y
// `test/`, decide qué pruebas corren. Lógica pura (sin git ni disco) para
// poder probarla con grafos en memoria; la CLI está en
// `tool/tests_afectados.dart`.
//
// Regla de diseño: ante la duda, MÁS pruebas. Todo archivo que no se sabe
// clasificar devuelve la suite completa.

/// Pruebas que corren siempre, afecte o no el diff: contrato de API, reglas
/// de arquitectura/importación, replay del motor de sync y el propio
/// selector.
const List<String> pruebasHumo = [
  'test/nucleo/sync/sync_engine_replay_test.dart',
  'test/nucleo/catalogo/catalogo_contrato_test.dart',
  'test/arquitectura/importaciones_test.dart',
  'test/tool/selector_test.dart',
];

/// Prefijos de ruta que, al cambiar, obligan a correr toda la suite.
const List<String> prefijosCorreTodo = [
  'config/',
  'lib/nucleo/db/',
  'lib/nucleo/sync/',
  '.github/',
  'bin/',
  'tool/',
  'test/fixtures/',
  'assets/',
];

/// Archivos exactos que obligan a correr toda la suite.
const List<String> archivosCorreTodo = [
  'pubspec.lock',
  'pubspec.yaml',
  'analysis_options.yaml',
];

/// Rutas que no pueden afectar a ninguna prueba (documentación y metadatos).
const List<String> prefijosIgnorables = ['docs/', 'prompts/', '.claude/'];
const List<String> archivosIgnorables = [
  '.gitignore',
  '.metadata',
  'agrocom.code-workspace',
];

/// Resultado de la selección.
class Seleccion {
  const Seleccion.todo(this.motivo) : todo = true, pruebas = const [];
  const Seleccion.parcial(this.pruebas, this.motivo) : todo = false;

  /// `true` si corre la suite completa (sin filtro de rutas).
  final bool todo;

  /// Pruebas a correr cuando [todo] es `false`, ordenadas y sin repetir.
  final List<String> pruebas;

  /// Explicación legible de por qué se eligió este conjunto.
  final String motivo;
}

/// Grafo de imports: archivo -> archivos que importa/exporta/declara como
/// `part` (rutas relativas a la raíz del repo, con `/`).
typedef GrafoImports = Map<String, Set<String>>;

bool esPrueba(String ruta) =>
    ruta.startsWith('test/') && ruta.endsWith('_test.dart');

/// Motivo por el que [ruta] fuerza la suite completa, o `null` si no.
String? motivoCorreTodo(String ruta) {
  if (archivosCorreTodo.contains(ruta)) return 'cambió $ruta';
  for (final p in prefijosCorreTodo) {
    if (ruta.startsWith(p)) return 'cambió $ruta (zona crítica $p)';
  }
  // Pruebas compartidas: cualquier .dart bajo test/ que no sea una prueba.
  if (ruta.startsWith('test/') &&
      ruta.endsWith('.dart') &&
      !ruta.endsWith('_test.dart')) {
    return 'cambió $ruta (código de pruebas compartido)';
  }
  return null;
}

bool _ignorable(String ruta) {
  if (archivosIgnorables.contains(ruta)) return true;
  if (ruta.endsWith('.md')) return true;
  return prefijosIgnorables.any(ruta.startsWith);
}

/// Invierte [grafo]: archivo -> archivos que lo importan.
GrafoImports invertir(GrafoImports grafo) {
  final inverso = <String, Set<String>>{};
  grafo.forEach((origen, destinos) {
    for (final d in destinos) {
      inverso.putIfAbsent(d, () => <String>{}).add(origen);
    }
  });
  return inverso;
}

/// Calcula qué pruebas corren para [cambiados].
///
/// [grafo] cubre `lib/` y `test/` (los `part` van como arista en ambos
/// sentidos). [existentes] son los archivos presentes en disco: un archivo
/// de prueba cambiado que ya no existe es un borrado y no se ejecuta.
Seleccion seleccionar({
  required Iterable<String> cambiados,
  required GrafoImports grafo,
  required Set<String> existentes,
}) {
  final cambios = cambiados
      .map((r) => r.replaceAll('\\', '/').trim())
      .where((r) => r.isNotEmpty)
      .toSet();

  for (final ruta in cambios) {
    final motivo = motivoCorreTodo(ruta);
    if (motivo != null) return Seleccion.todo(motivo);
  }

  final faltantes = pruebasHumo.where((p) => !existentes.contains(p)).toList();
  if (faltantes.isNotEmpty) {
    return Seleccion.todo('falta la prueba de humo ${faltantes.join(', ')}');
  }

  final inverso = invertir(grafo);
  final pruebas = <String>{...pruebasHumo};
  final semillas = <String>{};

  for (final ruta in cambios) {
    if (_ignorable(ruta)) continue;
    if (ruta.startsWith('android/')) {
      pruebas.addAll(existentes.where((e) => e.startsWith('test/android/')));
      continue;
    }
    if (ruta.endsWith('.dart') &&
        (ruta.startsWith('lib/') || ruta.startsWith('test/'))) {
      semillas.add(ruta);
      continue;
    }
    // Cualquier otro archivo no clasificado: ante la duda, todo.
    return Seleccion.todo('cambió $ruta (tipo de archivo no clasificado)');
  }

  // Cierre inverso: todo archivo que, directa o transitivamente, importa
  // alguno de los cambiados.
  final visitados = <String>{...semillas};
  final pendientes = <String>[...semillas];
  while (pendientes.isNotEmpty) {
    final actual = pendientes.removeLast();
    for (final dependiente in inverso[actual] ?? const <String>{}) {
      if (visitados.add(dependiente)) pendientes.add(dependiente);
    }
  }
  for (final ruta in visitados) {
    if (esPrueba(ruta) && existentes.contains(ruta)) pruebas.add(ruta);
  }

  final lista = pruebas.toList()..sort();
  return Seleccion.parcial(
    lista,
    '${cambios.length} archivo(s) cambiado(s) -> ${lista.length} prueba(s)',
  );
}
