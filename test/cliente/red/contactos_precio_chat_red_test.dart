// Contactos de referencia, precio final y chat con adjuntos contra los
// ejemplos reales del contrato de `agrocom-api` (`docs/api/ejemplos/`,
// copiados en `test/fixtures/api_cliente/`). El chat con fotos y el precio
// final dependen de los PR #353 y #354 de la API.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:agrocom_field/cliente/contactos/data/contactos_red.dart';
import 'package:agrocom_field/cliente/contactos/domain/contacto.dart';
import 'package:agrocom_field/cliente/precio_final/data/precio_final_red.dart';
import 'package:agrocom_field/cliente/seguimiento/data/seguimiento_red.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_red.dart';

Map<String, dynamic> _ejemplo(String nombre) =>
    jsonDecode(
          File('test/fixtures/api_cliente/$nombre.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

Object? _cuerpo(String nombre) =>
    (_ejemplo(nombre)['respuesta'] as Map)['cuerpo'];

void main() {
  late EntornoRed red;
  setUp(() => red = EntornoRed());

  group('ContactosRed', () {
    test('lista los contactos con el principal primero', () async {
      red.servidor.responder(
        'GET',
        '/api/clientes/mi/contactos',
        cuerpo: _cuerpo('contactos-lista'),
      );
      final lista = await ContactosRed(red.http).listar();
      expect(lista.map((c) => c.nombre), [
        'Rosario Antelo Vaca',
        'Mario Suárez Rojas',
      ]);
      expect(lista.first.esPrincipal, isTrue);
      expect(lista.first.cargo, 'Gerente');
    });

    test('agregar envía solo lo escrito y lee el contacto creado', () async {
      red.servidor.responder(
        'POST',
        '/api/clientes/mi/contactos',
        codigo: 201,
        cuerpo: _cuerpo('contactos-agregar'),
      );
      final c = await ContactosRed(red.http).agregar(
        const DatosContacto(
          nombre: ' Elena Chávez Soliz ',
          telefono: '+591 70011223',
          cargo: 'Administradora',
        ),
      );
      expect(c.id, 4);
      final cuerpo =
          red.servidor.de('POST', '/api/clientes/mi/contactos').single.cuerpo!
              as Map;
      expect(cuerpo, {
        'nombre': 'Elena Chávez Soliz',
        'telefono': '+591 70011223',
        'cargo': 'Administradora',
      });
    });

    test(
      'actualizar usa PUT y marcar principal viaja como es_principal',
      () async {
        red.servidor.responder(
          'PUT',
          '/api/clientes/mi/contactos/4',
          cuerpo: _cuerpo('contactos-agregar'),
        );
        await ContactosRed(red.http).actualizar(
          4,
          const DatosContacto(
            nombre: 'Elena',
            telefono: '70011223',
            esPrincipal: true,
          ),
        );
        final cuerpo =
            red.servidor
                    .de('PUT', '/api/clientes/mi/contactos/4')
                    .single
                    .cuerpo!
                as Map;
        expect(cuerpo['es_principal'], isTrue);
        expect(cuerpo.containsKey('cargo'), isFalse);
      },
    );

    test('una validación 422 llega como operación rechazada', () async {
      red.servidor.responder(
        'POST',
        '/api/clientes/mi/contactos',
        codigo: 422,
        cuerpo: _cuerpo('contactos-agregar-invalido'),
      );
      expect(
        ContactosRed(
          red.http,
        ).agregar(const DatosContacto(nombre: '', telefono: '')),
        throwsA(isA<OperacionRechazada>()),
      );
    });

    test('dar de baja llama DELETE', () async {
      red.servidor.responder(
        'DELETE',
        '/api/clientes/mi/contactos/4',
        codigo: 204,
        cuerpo: null,
      );
      await ContactosRed(red.http).darDeBaja(4);
      expect(
        red.servidor.de('DELETE', '/api/clientes/mi/contactos/4'),
        hasLength(1),
      );
    });

    test('sin red lanza SinConexion', () async {
      red.servidor.sinRed = true;
      expect(ContactosRed(red.http).listar(), throwsA(isA<SinConexion>()));
    });
  });

  group('PrecioFinalRed', () {
    test('pendiente: decimales exactos y sin confirmar', () async {
      red.servidor.responder(
        'GET',
        '/api/solicitudes/18/precio-final',
        cuerpo: _cuerpo('precio-final-ver-pendiente'),
      );
      final p = await PrecioFinalRed(red.http).ver('18');
      expect(p!.hectareasEjecutadas, Decimal.parse('98.5'));
      expect(p.precioHaAcordado, Decimal.parse('121'));
      expect(p.montoFinal, Decimal.parse('11918.50'));
      expect(p.confirmado, isFalse);
      expect(p.confirmadoEn, isNull);
    });

    test('sin cierre del piloto es null', () async {
      red.servidor.responder(
        'GET',
        '/api/solicitudes/18/precio-final',
        cuerpo: {'precio_final': null},
      );
      expect(await PrecioFinalRed(red.http).ver('18'), isNull);
    });

    test('confirmar no lleva cuerpo y devuelve lo confirmado', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes/18/precio-final/confirmar',
        codigo: 201,
        cuerpo: _cuerpo('precio-final-confirmar'),
      );
      final p = await PrecioFinalRed(red.http).confirmar('18');
      expect(p.confirmado, isTrue);
      expect(p.confirmadoEn, isNotNull);
      expect(
        red.servidor
            .de('POST', '/api/solicitudes/18/precio-final/confirmar')
            .single
            .cuerpo,
        isNull,
      );
    });

    test('un 409 estado_invalido es operación rechazada', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes/18/precio-final/confirmar',
        codigo: 409,
        cuerpo: {'message': 'Todavía no terminó.', 'codigo': 'estado_invalido'},
      );
      expect(
        PrecioFinalRed(red.http).confirmar('18'),
        throwsA(isA<OperacionRechazada>()),
      );
    });
  });

  group('SeguimientoRed · chat con adjuntos', () {
    test('lee tipo, evento y ruta de la foto', () async {
      red.servidor.responder(
        'GET',
        '/api/solicitudes/18/mensajes',
        cuerpo: _cuerpo('mensajes-lista'),
      );
      final pagina = await SeguimientoRed(red.http).mensajes('18');
      final tipos = pagina.mensajes.map((m) => m.tipo).toList();
      expect(tipos, [
        TipoMensajeChat.sistema,
        TipoMensajeChat.texto,
        TipoMensajeChat.texto,
        TipoMensajeChat.foto,
      ]);
      expect(pagina.mensajes.first.evento, 'solicitud_adjudicada');
      expect(pagina.mensajes.first.propio, isFalse);
      expect(pagina.mensajes.last.ruta, '/api/mensajes/35/archivo');
      expect(pagina.mensajes.last.texto, 'Así queda el punto de carga.');
    });

    test('enviarFoto sube multipart con uuid y pie', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes/18/mensajes/fotos',
        codigo: 201,
        cuerpo: _cuerpo('mensajes-foto-enviar'),
      );
      final m = await SeguimientoRed(red.http).enviarFoto(
        '18',
        bytes: Uint8List.fromList(List.filled(1888, 7)),
        claveCliente: '9c1d7e40-5a2b-4f3c-8e61-0d4b7a2c9e23',
        pie: ' Así queda el punto de carga. ',
      );
      expect(m.tipo, TipoMensajeChat.foto);
      final peticion = red.servidor
          .de('POST', '/api/solicitudes/18/mensajes/fotos')
          .single;
      expect(peticion.cuerpo, isA<Object>());
    });
  });
}
