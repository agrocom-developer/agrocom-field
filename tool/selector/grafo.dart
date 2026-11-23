// Construcción del grafo de imports a partir de los archivos .dart de disco.

import 'dart:io';

const String _paquete = 'agrocom_field';

final RegExp _directiva = RegExp(
  r'^\s*(import|export|part)\s+([^;]*);',
  multiLine: true,
);
final RegExp _uri = RegExp(r'''['"]([^'"]+)['"]''');

/// Rutas (relativas a [raiz], con `/`) de los .dart de `lib/` y `test/`.
List<String> listarDart(Directory raiz) {
  final salida = <String>[];
  for (final carpeta in ['lib', 'test']) {
    final dir = Directory('${raiz.path}/$carpeta');
    if (!dir.existsSync()) continue;
    for (final e in dir.listSync(recursive: true, followLinks: false)) {
      if (e is File && e.path.endsWith('.dart')) {
        salida.add(_relativa(raiz, e.path));
      }
    }
  }
  salida.sort();
  return salida;
}

String _relativa(Directory raiz, String ruta) {
  var base = raiz.absolute.path.replaceAll('\\', '/');
  if (!base.endsWith('/')) base = '$base/';
  final r = ruta.replaceAll('\\', '/');
  final abs = r.startsWith(base) ? r.substring(base.length) : r;
  return abs.startsWith('./') ? abs.substring(2) : abs;
}

/// Resuelve [uri] declarado en [origen]; `null` si apunta fuera del repo
/// (`dart:` y paquetes de terceros).
String? resolver(String origen, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    const prefijo = 'package:$_paquete/';
    if (!uri.startsWith(prefijo)) return null;
    return 'lib/${uri.substring(prefijo.length)}';
  }
  final partes = origen.split('/')..removeLast();
  for (final seg in uri.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (partes.isNotEmpty) partes.removeLast();
    } else {
      partes.add(seg);
    }
  }
  return partes.join('/');
}

/// Aristas de [origen] según su [fuente]. Un import condicional trae varios
/// URIs en la misma directiva y se toman todos. Un `part 'x.dart'` suma
/// además la arista inversa (x -> origen), de modo que host y parte quedan
/// unidos en las dos direcciones; `part of` ya apunta al host por sí solo.
Map<String, Set<String>> aristas(String origen, String fuente) {
  final salida = <String, Set<String>>{origen: <String>{}};
  for (final m in _directiva.allMatches(fuente)) {
    final tipo = m.group(1)!;
    final cuerpo = m.group(2)!;
    for (final u in _uri.allMatches(cuerpo)) {
      final destino = resolver(origen, u.group(1)!);
      if (destino == null) continue;
      salida[origen]!.add(destino);
      if (tipo == 'part' && !cuerpo.trimLeft().startsWith('of')) {
        salida.putIfAbsent(destino, () => <String>{}).add(origen);
      }
    }
  }
  return salida;
}

/// Grafo completo de [raiz].
Map<String, Set<String>> construirGrafo(Directory raiz) {
  final grafo = <String, Set<String>>{};
  for (final ruta in listarDart(raiz)) {
    final fuente = File('${raiz.path}/$ruta').readAsStringSync();
    aristas(ruta, fuente).forEach((k, v) {
      grafo.putIfAbsent(k, () => <String>{}).addAll(v);
    });
  }
  return grafo;
}
