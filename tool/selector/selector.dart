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
  'assets/fonts/',
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
  const Seleccion.todo(this.motivo)
    : todo = true,
      pruebas = const [],
      notas = const [];
  const Seleccion.parcial(this.pruebas, this.motivo, {this.notas = const []})
    : todo = false;

  /// `true` si corre la suite completa (sin filtro de rutas).
  final bool todo;

  /// Pruebas a correr cuando [todo] es `false`, ordenadas y sin repetir.
  final List<String> pruebas;

  /// Explicación legible de por qué se eligió este conjunto.
  final String motivo;

  /// Avisos sobre archivos ignorados o resueltos por una regla especial
  /// (un golden que ninguna prueba referencia, una imagen sin uso).
  final List<String> notas;
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

final RegExp _goldenLiteral = RegExp(
  r'''matchesGoldenFile\(\s*['"]([^'"$]*)''',
);
const List<String> _extensionesImagen = ['.png', '.jpg', '.jpeg', '.webp'];

String _dirDe(String ruta) {
  final i = ruta.lastIndexOf('/');
  return i < 0 ? '' : ruta.substring(0, i);
}

String _nombreDe(String ruta) => ruta.substring(ruta.lastIndexOf('/') + 1);

/// Normaliza `base/rel` resolviendo `.` y `..`.
String _unir(String base, String rel) {
  final partes = base.isEmpty ? <String>[] : base.split('/');
  for (final seg in rel.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (partes.isNotEmpty) partes.removeLast();
    } else {
      partes.add(seg);
    }
  }
  return partes.join('/');
}

/// Carpeta de goldens que [fuente] (un `.dart` de `ruta`) referencia con
/// `matchesGoldenFile('<carpeta>/...')`, resuelta contra la carpeta del
/// archivo, que es como la resuelve `flutter test`. Solo se lee la parte
/// literal anterior al primer `$`.
Set<String> carpetasDeGoldens(String ruta, String fuente) {
  final salida = <String>{};
  for (final m in _goldenLiteral.allMatches(fuente)) {
    final literal = m.group(1)!;
    final i = literal.lastIndexOf('/');
    if (i < 0) continue;
    salida.add(_unir(_dirDe(ruta), literal.substring(0, i)));
  }
  return salida;
}

/// Archivos `.dart` (de [fuentes]) que usan el recurso [ruta]: los que
/// nombran su archivo o, si es un golden, los que referencian su carpeta
/// con `matchesGoldenFile`.
Set<String> _usuariosDe(
  String ruta,
  Map<String, String> fuentes, {
  required bool golden,
}) {
  final nombre = _nombreDe(ruta);
  final dir = _dirDe(ruta);
  final salida = <String>{};
  fuentes.forEach((archivo, fuente) {
    if (fuente.contains(nombre) ||
        (golden && carpetasDeGoldens(archivo, fuente).contains(dir))) {
      salida.add(archivo);
    }
  });
  return salida;
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
/// [fuentes] es el texto de los `.dart` de `lib/` y `test/`: sirve para
/// saber qué código referencia un golden o una imagen cambiados.
Seleccion seleccionar({
  required Iterable<String> cambiados,
  required GrafoImports grafo,
  required Set<String> existentes,
  required Map<String, String> fuentes,
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
  final notas = <String>[];

  for (final ruta in cambios) {
    if (_ignorable(ruta)) continue;
    final minuscula = ruta.toLowerCase();
    final esImagen = _extensionesImagen.any(minuscula.endsWith);
    // Textos de l10n: el impacto lo lleva el código generado, que se
    // versiona. Un .arb sin su código regenerado es un diff inconsistente.
    if (ruta.startsWith('lib/l10n/') && ruta.endsWith('.arb')) {
      if (cambios.contains('lib/l10n/app_localizations.dart')) {
        notas.add('$ruta: el impacto va por lib/l10n/app_localizations*.dart');
        continue;
      }
      return Seleccion.todo(
        'cambió $ruta sin regenerar lib/l10n/app_localizations*.dart',
      );
    }
    // Goldens: solo las pruebas que los referencian.
    if (esImagen && ruta.startsWith('test/') && ruta.contains('/goldens/')) {
      final usuarios = _usuariosDe(ruta, fuentes, golden: true);
      if (usuarios.isEmpty) {
        notas.add('$ruta: ninguna prueba lo referencia, se ignora');
      }
      semillas.addAll(usuarios);
      continue;
    }
    // Fotos e íconos: solo el código que las nombra (y sus pruebas).
    if (esImagen &&
        (ruta.startsWith('assets/imagenes/') ||
            ruta.startsWith('assets/icono_launcher/'))) {
      final usuarios = _usuariosDe(ruta, fuentes, golden: false);
      if (usuarios.isEmpty) {
        notas.add('$ruta: ningún .dart lo referencia, se ignora');
      }
      semillas.addAll(usuarios);
      continue;
    }
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
    notas: notas,
  );
}
