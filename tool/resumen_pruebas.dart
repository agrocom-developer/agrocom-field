// Resumen de tiempos de `flutter test`, a partir del reporter JSON.
//
//   flutter test --file-reporter json:build/pruebas.json ...
//   dart tool/resumen_pruebas.dart --entrada build/pruebas.json \
//       --titulo "Pruebas afectadas" --presupuesto 600 \
//       [--salida "$GITHUB_STEP_SUMMARY"]
//
// Publica (Markdown, a `--salida` o a stdout): tiempo total, tiempo por
// carpeta (suma de duraciones de pruebas y de carga de cada archivo) y las
// 10 pruebas más lentas. Si el total supera `--presupuesto` (segundos),
// avisa con un `::warning::` de GitHub Actions. Nunca falla por el
// presupuesto: es una alerta, no una compuerta.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? entrada;
  String titulo = 'Pruebas';
  int? presupuesto;
  String? salida;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--entrada':
        entrada = args[++i];
      case '--titulo':
        titulo = args[++i];
      case '--presupuesto':
        presupuesto = int.tryParse(args[++i]);
      case '--salida':
        salida = args[++i];
      default:
        stderr.writeln('Argumento desconocido: ${args[i]}');
        exit(64);
    }
  }
  if (entrada == null || !File(entrada).existsSync()) {
    stdout.writeln('::warning::Sin reporte JSON de pruebas ($entrada)');
    return;
  }

  final suites = <int, String>{};
  final inicios = <int, ({int t, String nombre, int suite})>{};
  final porCarpeta = <String, int>{};
  final lentas = <({int ms, String nombre, String archivo})>[];
  var total = 0;
  var cantidad = 0;
  var fallidas = 0;

  for (final linea in File(entrada).readAsLinesSync()) {
    if (!linea.startsWith('{')) continue;
    final Map<String, dynamic> e;
    try {
      e = jsonDecode(linea) as Map<String, dynamic>;
    } on FormatException {
      continue;
    }
    final t = (e['time'] as num?)?.toInt() ?? 0;
    if (t > total) total = t;
    switch (e['type']) {
      case 'suite':
        final s = e['suite'] as Map<String, dynamic>;
        suites[s['id'] as int] = _relativa(s['path'] as String);
      case 'testStart':
        final p = e['test'] as Map<String, dynamic>;
        inicios[p['id'] as int] = (
          t: t,
          nombre: p['name'] as String,
          suite: (p['suiteID'] as num?)?.toInt() ?? -1,
        );
      case 'testDone':
        final ini = inicios[e['testID'] as int];
        if (ini == null) continue;
        final dur = t - ini.t;
        final archivo = suites[ini.suite] ?? '?';
        porCarpeta.update(
          _carpeta(archivo),
          (v) => v + dur,
          ifAbsent: () => dur,
        );
        final oculta = e['hidden'] == true;
        if (!oculta) {
          cantidad++;
          lentas.add((ms: dur, nombre: ini.nombre, archivo: archivo));
          if (e['result'] != 'success') fallidas++;
        }
    }
  }

  lentas.sort((a, b) => b.ms.compareTo(a.ms));
  final carpetas = porCarpeta.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final md = StringBuffer()
    ..writeln('### $titulo')
    ..writeln()
    ..writeln('- Tiempo total (reloj): **${_fmt(total)}**')
    ..writeln('- Pruebas ejecutadas: **$cantidad** ($fallidas con fallo)');
  if (presupuesto != null) {
    final dentro = total <= presupuesto * 1000;
    md.writeln(
      '- Presupuesto: ${_fmt(presupuesto * 1000)} '
      '(${dentro ? 'dentro' : '**excedido**'})',
    );
  }
  md
    ..writeln()
    ..writeln('| Carpeta | Tiempo acumulado |')
    ..writeln('|---|---|');
  for (final c in carpetas) {
    md.writeln('| `${c.key}` | ${_fmt(c.value)} |');
  }
  md
    ..writeln()
    ..writeln('**10 pruebas más lentas**')
    ..writeln()
    ..writeln('| Prueba | Archivo | Tiempo |')
    ..writeln('|---|---|---|');
  for (final l in lentas.take(10)) {
    md.writeln(
      '| ${l.nombre.replaceAll('|', '\\|')} | `${l.archivo}` | ${_fmt(l.ms)} |',
    );
  }
  md.writeln();

  if (salida != null) {
    File(salida).writeAsStringSync(md.toString(), mode: FileMode.append);
  } else {
    stdout.write(md);
  }
  if (presupuesto != null && total > presupuesto * 1000) {
    stdout.writeln(
      '::warning::$titulo tardó ${_fmt(total)} y supera el presupuesto de '
      '${_fmt(presupuesto * 1000)}',
    );
  }
}

String _relativa(String ruta) {
  final i = ruta.indexOf('/test/');
  if (i >= 0) return ruta.substring(i + 1);
  return ruta;
}

/// Agrupa `test/features/x/...` y `test/nucleo/x/...` por su módulo; el resto
/// por su carpeta inmediata.
String _carpeta(String archivo) {
  final p = archivo.split('/');
  if (p.length >= 4 && (p[1] == 'features' || p[1] == 'nucleo')) {
    return '${p[0]}/${p[1]}/${p[2]}';
  }
  if (p.length >= 3) return '${p[0]}/${p[1]}';
  return p.first;
}

String _fmt(int ms) {
  if (ms < 1000) return '$ms ms';
  final s = ms / 1000;
  if (s < 60) return '${s.toStringAsFixed(1)} s';
  return '${s ~/ 60} min ${(s % 60).round()} s';
}
