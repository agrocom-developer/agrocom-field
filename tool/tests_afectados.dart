// CLI del selector de pruebas por impacto.
//
//   dart tool/tests_afectados.dart [--base origin/develop] [--formato lista|github]
//                                  [--solo-dart] [--archivos a,b,c]
//
// Calcula los archivos cambiados contra la base (merge-base con HEAD, árbol
// de trabajo incluido) y devuelve las pruebas afectadas. Si no se puede
// calcular el diff, devuelve la suite completa: falla hacia MÁS pruebas.
//
// Formato `lista` (por defecto): una ruta por línea, o la única palabra
// `TODO` si corre la suite completa. Con `--solo-dart`, en vez de pruebas,
// imprime los .dart cambiados que existen (para format y analyze).
// Formato `github`: líneas clave=valor para `$GITHUB_OUTPUT`.
//
// Se ejecuta con `dart tool/tests_afectados.dart` (sin `pub get`: solo usa
// librerías del SDK).

import 'dart:io';

import 'selector/grafo.dart';
import 'selector/selector.dart';

Future<void> main(List<String> args) async {
  var base = 'origin/develop';
  var formato = 'lista';
  var soloDart = false;
  List<String>? archivosManual;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--base':
        base = args[++i];
      case '--formato':
        formato = args[++i];
      case '--solo-dart':
        soloDart = true;
      case '--archivos':
        archivosManual = args[++i].split(',');
      default:
        stderr.writeln('Argumento desconocido: ${args[i]}');
        exit(64);
    }
  }

  final raiz = Directory.current;
  final existentes = <String>{};
  final grafo = construirGrafo(raiz);
  existentes.addAll(
    grafo.keys.where((r) => File('${raiz.path}/$r').existsSync()),
  );

  List<String>? cambiados = archivosManual;
  String? errorDiff;
  if (cambiados == null) {
    try {
      cambiados = await _cambiadosGit(base);
    } on Exception catch (e) {
      errorDiff = '$e';
    }
  }

  final Seleccion seleccion;
  if (cambiados == null) {
    seleccion = Seleccion.todo(
      'no se pudo calcular el diff contra $base: $errorDiff',
    );
  } else {
    seleccion = seleccionar(
      cambiados: cambiados,
      grafo: grafo,
      existentes: existentes,
    );
  }

  final dartCambiados =
      (cambiados ?? const <String>[])
          .where(
            (r) =>
                r.endsWith('.dart') &&
                (r.startsWith('lib/') ||
                    r.startsWith('test/') ||
                    r.startsWith('tool/')) &&
                File('${raiz.path}/$r').existsSync(),
          )
          .toList()
        ..sort();

  stderr.writeln('selector: ${seleccion.motivo}');

  if (formato == 'github') {
    final android =
        seleccion.todo ||
        (cambiados ?? const <String>[]).any(
          (r) =>
              r.startsWith('android/') ||
              r.startsWith('ios/') ||
              r.startsWith('assets/') ||
              r.startsWith('pubspec') ||
              r.startsWith('lib/main_') ||
              r == 'lib/nucleo/flavor.dart',
        );
    stdout.writeln('modo=${seleccion.todo ? 'todo' : 'afectado'}');
    stdout.writeln(
      'tests=${seleccion.todo ? '' : seleccion.pruebas.join(' ')}',
    );
    stdout.writeln('dart_cambiados=${dartCambiados.join(' ')}');
    stdout.writeln('android=$android');
    stdout.writeln('motivo=${seleccion.motivo.replaceAll('\n', ' ')}');
    return;
  }

  if (soloDart) {
    dartCambiados.forEach(stdout.writeln);
    return;
  }
  if (seleccion.todo) {
    stdout.writeln('TODO');
  } else {
    seleccion.pruebas.forEach(stdout.writeln);
  }
}

/// Archivos cambiados contra el merge-base con [base]: commits de la rama,
/// cambios en el árbol de trabajo (staged o no) y archivos sin seguimiento.
Future<List<String>> _cambiadosGit(String base) async {
  Future<String> git(List<String> a) async {
    final r = await Process.run('git', a);
    if (r.exitCode != 0) {
      throw Exception('git ${a.join(' ')}: ${r.stderr}'.trim());
    }
    return r.stdout as String;
  }

  final mergeBase = (await git(['merge-base', base, 'HEAD'])).trim();
  final diff = await git(['diff', '--name-only', '--no-renames', mergeBase]);
  final nuevos = await git(['ls-files', '--others', '--exclude-standard']);
  return [
    ...diff.split('\n'),
    ...nuevos.split('\n'),
  ].map((l) => l.trim()).where((l) => l.isNotEmpty).toSet().toList();
}
