import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ningún texto visible vive en duro en `lib/` (ADR 0022).
///
/// Revisa el código fuente y falla si encuentra literales de texto visible:
/// `Text('...')`, `tooltip:`, `labelText:`, `hintText:`, `semanticLabel:` y
/// demás argumentos con nombre de texto. En las carpetas de pantallas
/// (`presentation/`, `componentes/`, `ui/`) revisa además cualquier literal con
/// aspecto de frase (con espacios, acentos, signos o inicial mayúscula).
///
/// Un texto nuevo va a `lib/l10n/app_es.arb` y se lee con `AppLocalizations`.
/// Si de verdad no es texto de pantalla, se agrega a las excepciones de abajo
/// con su motivo.
void main() {
  test('lib/ no tiene textos visibles en duro', () {
    final hallazgos = <String>[];
    for (final archivo in _archivosDart()) {
      final ruta = archivo.path.replaceAll(r'\', '/');
      if (_archivosExentos.keys.any(ruta.endsWith) ||
          _carpetasExentas.keys.any(ruta.contains)) {
        continue;
      }
      final fuente = archivo.readAsStringSync();
      for (final h in buscarTextosEnDuro(
        fuente,
        revisarTodoLiteral: _esPantalla(ruta),
      )) {
        if (_literalesPermitidos.contains(h.cuerpo)) continue;
        hallazgos.add('$ruta:${h.linea}: ${h.fragmento}');
      }
    }
    expect(
      hallazgos,
      isEmpty,
      reason:
          'Hay ${hallazgos.length} textos visibles en duro. Pásalos a '
          'lib/l10n/app_es.arb y léelos con AppLocalizations (ADR 0022):\n'
          '${hallazgos.join('\n')}',
    );
  });

  group('el detector', () {
    test('encuentra los literales de texto visible', () {
      const fuente = '''
Widget build(BuildContext context) => Column(children: [
  const Text('Hola'),
  IconButton(tooltip: 'Volver', onPressed: null, icon: Icon(Icons.add)),
  TextField(decoration: InputDecoration(labelText: 'Nombre', hintText: "Tu nombre")),
  Semantics(label: 'Avance \${x}', child: SizedBox()),
]);
''';
      final r = buscarTextosEnDuro(fuente, revisarTodoLiteral: false);
      expect(r.map((h) => h.cuerpo), [
        'Hola',
        'Volver',
        'Nombre',
        'Tu nombre',
        r'Avance ${x}',
      ]);
    });

    test('ignora l10n, claves, rutas y literales sin letras', () {
      const fuente = '''
Widget build(BuildContext context) => Column(children: [
  Text(l10n.titulo),
  Text('\$n'),
  Text('12'),
  Container(key: const ValueKey('boton-guardar')),
  Text('·'),
]);
// Text('comentario')
''';
      expect(buscarTextosEnDuro(fuente, revisarTodoLiteral: true), isEmpty);
    });

    test(
      'en pantallas revisa cualquier frase, también dentro de ternarios',
      () {
        const fuente = '''
final t = ok ? 'Todo listo' : 'Intenta de nuevo';
final ruta = '/api/solicitudes';
final tipo = 'cliente';
''';
        final r = buscarTextosEnDuro(fuente, revisarTodoLiteral: true);
        expect(r.map((h) => h.cuerpo), ['Todo listo', 'Intenta de nuevo']);
      },
    );
  });
}

/// Literales que no son texto de pantalla: la marca y atribuciones propias.
const _literalesPermitidos = {'Agrocom', 'AGROCOM', 'OpenStreetMap', 'Bs'};

/// Archivos exentos, con su motivo.
const _archivosExentos = <String, String>{
  'lib/main_cliente.dart': 'Arranque: el título de marca «Agrocom».',
  'lib/main_piloto.dart': 'Arranque: el título de marca «Agrocom».',
};

/// Carpetas exentas, con su motivo.
const _carpetasExentas = <String, String>{
  'lib/l10n/': 'Código generado de gen-l10n.',
  'lib/nucleo/ui/vitrina_campo/':
      'Catálogo de diseño con datos de ejemplo; solo se monta en pruebas '
      'y capturas, no en el producto.',
  'lib/cliente/demo/':
      'Almacén de demostración: simula las respuestas del servidor.',
  '/data/': 'Capa de datos: respuestas simuladas y mensajes del servidor.',
  '/domain/': 'Dominio: valores y enums; la pantalla los traduce.',
};

bool _esPantalla(String ruta) =>
    ruta.contains('/presentation/') ||
    ruta.contains('/componentes/') ||
    ruta.contains('/marketplace/ui/') ||
    ruta.contains('/tema_visual/') ||
    ruta.contains('/version/');

Iterable<File> _archivosDart() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

/// Un literal de texto visible hallado en el código.
class Hallazgo {
  const Hallazgo(this.linea, this.cuerpo, this.fragmento);
  final int linea;
  final String cuerpo;
  final String fragmento;
}

final _argumentosDeTexto = RegExp(
  r'\b(?:tooltip|labelText|hintText|helperText|errorText|semanticLabel|'
  r'semanticsLabel|counterText|prefixText|suffixText|label|hint|etiqueta|'
  r'titulo|subtitulo|mensaje|texto|text|detalle|semantica|apoyo|ayuda|cuerpo|'
  r'encabezado|descripcion)\s*:\s*',
);
final _widgetTexto = RegExp(r'\b(?:Text|SelectableText)\(\s*(?:const\s+)?');
final _antesSeguro = RegExp(
  r'(import|export|part|ValueKey|Key|RegExp|clave|key|asset|fontFamily|'
  r'package|name|ruta|path|case|debugLabel|heroTag|restorationId|tag|'
  r'Uri\.parse|toStringAsFixed|replaceAll|split|join|padLeft|padRight|'
  r'contains|startsWith|endsWith|fromJson|jsonDecode|DateFormat|NumberFormat|'
  r'Locale|identifier|id|uuid|\w+Id|==|!=|\]|print|log|debugPrint|throw|'
  r'Exception|assert|motivo|codigo|tipo|campo|rol|estado|valor|ctx)'
  r'\s*[:(\[]?\s*(?:const\s+)?$',
);

/// Busca literales de texto visible en [fuente]. Con [revisarTodoLiteral] mira
/// cualquier literal con aspecto de frase, no solo los de widgets de texto.
List<Hallazgo> buscarTextosEnDuro(
  String fuente, {
  required bool revisarTodoLiteral,
}) {
  final hallazgos = <int, Hallazgo>{};

  void agregar(int inicio, bool exigirFrase) {
    final fin = _finLiteral(fuente, inicio);
    if (fin < 0) return;
    final cuerpo = fuente.substring(inicio, fin).replaceFirst('r', '');
    final texto = cuerpo.substring(1, cuerpo.length - 1);
    if (!_conLetras(texto)) return;
    if (exigirFrase && !_pareceFrase(texto)) return;
    final linea = '\n'.allMatches(fuente.substring(0, inicio)).length + 1;
    hallazgos[inicio] = Hallazgo(linea, texto, cuerpo);
  }

  for (final m in [
    ..._widgetTexto.allMatches(fuente),
    ..._argumentosDeTexto.allMatches(fuente),
  ]) {
    if (_enComentario(fuente, m.start)) continue;
    if (m.end < fuente.length && "'\"r".contains(fuente[m.end])) {
      agregar(m.end, false);
    }
  }

  if (revisarTodoLiteral) {
    var i = 0;
    while (i < fuente.length) {
      final c = fuente[i];
      if (c == '/' && fuente.startsWith('//', i)) {
        final salto = fuente.indexOf('\n', i);
        i = salto < 0 ? fuente.length : salto;
        continue;
      }
      if (c == "'" || c == '"') {
        final fin = _finLiteral(fuente, i);
        if (fin < 0) {
          i++;
          continue;
        }
        final desde = i < 80 ? 0 : i - 80;
        final linea = fuente.substring(desde, i).split('\n').last.trimRight();
        if (!_antesSeguro.hasMatch(linea)) agregar(i, true);
        i = fin;
        continue;
      }
      i++;
    }
  }
  final lista = hallazgos.values.toList()
    ..sort((a, b) => a.linea.compareTo(b.linea));
  return lista;
}

bool _enComentario(String fuente, int posicion) {
  final inicioLinea = fuente.lastIndexOf('\n', posicion) + 1;
  return fuente.substring(inicioLinea, posicion).contains('//');
}

bool _conLetras(String texto) {
  final sinVariables = texto.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
  return RegExp('[A-Za-zÁÉÍÓÚáéíóúñÑ]{2}').hasMatch(sinVariables);
}

bool _pareceFrase(String texto) {
  if (texto.startsWith('/') ||
      texto.startsWith('http') ||
      texto.startsWith('assets')) {
    return false;
  }
  if (RegExp(r'\s').hasMatch(texto) ||
      RegExp('[ÁÉÍÓÚáéíóúñÑ¿¡«»…·—]').hasMatch(texto)) {
    return true;
  }
  return RegExp('^[A-ZÁÉÍÓÚ][a-záéíóúñA-Z]{2,}').hasMatch(texto);
}

/// Índice posterior al cierre del literal que empieza en [inicio], o -1 si no
/// es un literal de una línea.
int _finLiteral(String s, int inicio) {
  var j = inicio;
  var crudo = false;
  if (s[j] == 'r' && j + 1 < s.length && "'\"".contains(s[j + 1])) {
    crudo = true;
    j++;
  }
  if (j >= s.length || !"'\"".contains(s[j])) return -1;
  final comilla = s[j];
  if (s.startsWith(comilla * 3, j)) return -1;
  j++;
  while (j < s.length) {
    final c = s[j];
    if (c == '\n') return -1;
    if (!crudo && c == r'\') {
      j += 2;
      continue;
    }
    if (!crudo && c == r'$' && j + 1 < s.length && s[j + 1] == '{') {
      var d = 1;
      j += 2;
      while (j < s.length && d > 0) {
        if ("'\"".contains(s[j])) {
          final k = _finLiteral(s, j);
          if (k < 0) return -1;
          j = k;
          continue;
        }
        if (s[j] == '{') d++;
        if (s[j] == '}') d--;
        j++;
      }
      continue;
    }
    if (c == comilla) return j + 1;
    j++;
  }
  return -1;
}
