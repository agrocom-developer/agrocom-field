import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Los textos de `lib/l10n/app_es.arb` van en español neutro (guía en
/// `docs/diseno/guia-de-textos.md`).
///
/// Falla si reaparece alguna construcción que ya se corrigió: el reintento
/// dicho a medias, el voseo, los regionalismos y las palabras que la app no
/// usa para un concepto. Para agregar una, suma su patrón a [_prohibidas] con
/// la forma correcta.
void main() {
  final textos = <String, String>{
    for (final e
        in (jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync())
                as Map<String, dynamic>)
            .entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };

  test('el ARB se leyó y tiene textos', () {
    expect(textos.length, greaterThan(500));
  });

  for (final p in _prohibidas) {
    test('ningún texto usa «${p.etiqueta}»: ${p.alternativa}', () {
      final usos = [
        for (final e in textos.entries)
          if (p.patron.hasMatch(e.value)) '${e.key}: ${e.value}',
      ];
      expect(
        usos,
        isEmpty,
        reason:
            'Usa «${p.alternativa}» en lugar de «${p.etiqueta}»:\n'
            '${usos.join('\n')}',
      );
    });
  }

  test('el detector reconoce lo prohibido y deja pasar lo correcto', () {
    bool hay(String texto) => _prohibidas.any((p) => p.patron.hasMatch(texto));
    expect(hay('Intenta de nuevo en un momento.'), isTrue);
    expect(hay('Tenés que elegir un piloto'), isTrue);
    expect(hay('Se guarda acá'), isTrue);
    expect(hay('Vuelve a intentarlo en un momento.'), isFalse);
    expect(hay('Aquí aparecen tus solicitudes.'), isFalse);
  });
}

class _Prohibida {
  const _Prohibida(this.etiqueta, this.patron, this.alternativa);
  final String etiqueta;
  final RegExp patron;
  final String alternativa;
}

RegExp _palabra(String alternativas) => RegExp(
  r'(?<![\wáéíóúñÁÉÍÓÚÑ])(?:' + alternativas + r')(?![\wáéíóúñÁÉÍÓÚÑ])',
  caseSensitive: false,
);

final _prohibidas = <_Prohibida>[
  _Prohibida(
    'Intenta de nuevo',
    _palabra(
      r'intenta(?:r)? de nuevo|intenta(?= *[.,:;]|$)|inténtalo|'
      r'prueba de nuevo|reintenta',
    ),
    'Vuelve a intentarlo',
  ),
  _Prohibida('acá', _palabra('acá'), 'aquí'),
  _Prohibida('a pedido', _palabra('a pedido'), 'cuando lo necesites'),
  _Prohibida('pedido', _palabra('pedidos?'), 'solicitud'),
  _Prohibida('dar de baja', _palabra('dar de baja|dado de baja'), 'Eliminar'),
  _Prohibida(
    'voseo',
    _palabra(
      r'vos|tenés|podés|querés|sos|hacé|elegí|revisá|volvé|intentá|'
      r'escribí|ingresá|mirá|esperá|planificá|tocá|avisá|recibís|'
      r'cargaste el',
    ),
    'tuteo (tú tienes, puedes, quieres...)',
  ),
  _Prohibida('celular', _palabra('celulares?'), 'teléfono'),
  _Prohibida('jala', _palabra('jala|jalar'), 'desliza'),
  _Prohibida('disputa', _palabra('disputas?'), 'reclamo'),
  _Prohibida('Agrocom Field', _palabra('agrocom field'), 'Agrocom'),
  _Prohibida(
    'Cargar documentos o fotos',
    _palabra(
      r'(?:cargaste|cargar|carga|cargué) (?:los |tus |un |una )?'
      r'(?:documentos?|fotos?)',
    ),
    'Subir',
  ),
  _Prohibida('Entrar / Entra', _palabra(r'entra|entrar'), 'Ingresar'),
  _Prohibida('Avisos', _palabra('avisos?'), 'Notificaciones'),
  _Prohibida(
    'sincronización fallida',
    _palabra('sincronización fallida'),
    'un texto que diga qué hacer',
  ),
  _Prohibida('payload', _palabra('payload'), 'sin jerga técnica'),
];
