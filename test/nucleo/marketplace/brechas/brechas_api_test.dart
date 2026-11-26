// Pruebas de las rutas que la API sumó (PR #334 de `agrocom-api`): token
// push, confirmación de pago, foto de perfil, fotos de terreno y precio de
// referencia. Los cuerpos de ejemplo reproducen los de `docs/api/openapi.yaml`
// de `agrocom-api` (develop).

import 'dart:io';

import 'package:agrocom_field/cliente/red/mapeo_solicitud.dart';
import 'package:agrocom_field/nucleo/api/marketplace_http.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/mapeo_negociacion.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/foto_perfil/foto_perfil_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/pago/pago_confirmado.dart';
import 'package:agrocom_field/nucleo/marketplace/pago/pagos_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/terrenos/fotos_terreno_repositorio.dart';
import 'package:agrocom_field/nucleo/notificaciones/push/dispositivos_push_repositorio.dart';
import 'package:agrocom_field/nucleo/notificaciones/push/token_push_store.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../cliente/red/dobles_red.dart';

const _pagoJson = {
  'id': 3,
  'uuid_cliente': '5b0b8f0e-0b6e-4d0e-9a53-1d9d5b3b6f10',
  'solicitud_id': 8,
  'monto': '9440.10',
  'metodo': 'transferencia',
  'nota': 'Pagó el administrador',
  'confirmado_en': '2026-11-20T15:30:00+00:00',
};

const _uuid = '5b0b8f0e-0b6e-4d0e-9a53-1d9d5b3b6f10';

List<int> _foto([int n = 1000]) => List.filled(n, 7);

void main() {
  late EntornoRed red;
  late MarketplaceHttp http;
  setUp(() {
    red = EntornoRed();
    http = MarketplaceHttp(red.api);
  });

  group('pago confirmado', () {
    test('ver devuelve el pago con el monto decimal exacto', () async {
      red.servidor.responder(
        'GET',
        '/api/solicitudes/8/pago-confirmado',
        cuerpo: {'pago': _pagoJson},
      );
      final pago = await PagosRed(http).ver(8);
      expect(pago!.monto, Decimal.parse('9440.10'));
      expect(pago.metodo, MetodoPago.transferencia);
      expect(pago.confirmadoEn.isUtc, isTrue);
    });

    test('ver sin confirmar devuelve null', () async {
      red.servidor.responder(
        'GET',
        '/api/solicitudes/8/pago-confirmado',
        cuerpo: {'pago': null},
      );
      expect(await PagosRed(http).ver(8), isNull);
    });

    test('confirmar envía uuid_cliente y método, sin monto', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/pago-confirmado',
        codigo: 201,
        cuerpo: {'pago': _pagoJson},
      );
      final pago = await PagosRed(
        http,
      ).confirmar(8, uuidCliente: _uuid, metodo: MetodoPago.transferencia);
      expect(pago.id, 3);
      final enviado =
          red.servidor
                  .de('POST', '/api/solicitudes/8/pago-confirmado')
                  .single
                  .cuerpo!
              as Map;
      expect(enviado, {'uuid_cliente': _uuid, 'metodo': 'transferencia'});
    });

    test('repetir con el mismo uuid_cliente (200) devuelve el pago', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/pago-confirmado',
        cuerpo: {'pago': _pagoJson},
      );
      final pago = await PagosRed(http).confirmar(8, uuidCliente: _uuid);
      expect(pago.uuidCliente, _uuid);
    });

    test('409 pago_ya_confirmado conserva el motivo', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/pago-confirmado',
        codigo: 409,
        cuerpo: {
          'message': 'El pago ya fue confirmado.',
          'codigo': 'pago_ya_confirmado',
        },
      );
      await expectLater(
        PagosRed(http).confirmar(8, uuidCliente: 'otro'),
        throwsA(
          isA<OperacionRechazada>()
              .having((e) => e.codigo, 'codigo', 409)
              .having((e) => e.motivo, 'motivo', MotivoPago.yaConfirmado),
        ),
      );
    });

    test('403 pago_solo_titular y 404 se distinguen', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/pago-confirmado',
        codigo: 403,
        cuerpo: {'message': 'Solo el titular.', 'codigo': 'pago_solo_titular'},
      );
      red.servidor.responder(
        'POST',
        '/api/solicitudes/9/pago-confirmado',
        codigo: 404,
        cuerpo: {'message': 'No encontrada'},
      );
      await expectLater(
        PagosRed(http).confirmar(8, uuidCliente: _uuid),
        throwsA(
          isA<OperacionRechazada>()
              .having((e) => e.codigo, 'codigo', 403)
              .having((e) => e.motivo, 'motivo', MotivoPago.soloTitular),
        ),
      );
      await expectLater(
        PagosRed(http).confirmar(9, uuidCliente: _uuid),
        throwsA(isA<OperacionRechazada>().having((e) => e.codigo, 'c', 404)),
      );
    });

    test('sin red lanza SinConexion', () async {
      red.servidor.sinRed = true;
      await expectLater(
        PagosRed(http).confirmar(8, uuidCliente: _uuid),
        throwsA(isA<SinConexion>()),
      );
    });

    test('demo: un solo pago por solicitud, idempotente', () async {
      final demo = PagosDemo(montos: {8: Decimal.parse('9440.10')});
      final a = await demo.confirmar(8, uuidCliente: 'u1');
      final b = await demo.confirmar(8, uuidCliente: 'u1');
      expect(b, same(a));
      expect(a.monto, Decimal.parse('9440.10'));
      await expectLater(
        demo.confirmar(8, uuidCliente: 'u2'),
        throwsA(
          isA<OperacionRechazada>().having(
            (e) => e.motivo,
            'motivo',
            MotivoPago.yaConfirmado,
          ),
        ),
      );
      expect(await demo.ver(8), same(a));
      expect(await demo.ver(99), isNull);
    });
  });

  group('token push', () {
    const token = 'fcm:cJ3x/abc+def=';

    test('registrar envía token y plataforma y lo guarda seguro', () async {
      red.servidor.responder(
        'POST',
        '/api/dispositivos',
        codigo: 201,
        cuerpo: {'id': 14, 'plataforma': 'android', 'registrado_en': null},
      );
      final almacen = TokenPushEnMemoria();
      await DispositivosPushRed(
        http,
        almacen,
      ).registrar(token, PlataformaPush.android);
      final enviado =
          red.servidor.de('POST', '/api/dispositivos').single.cuerpo! as Map;
      expect(enviado, {'token': token, 'plataforma': 'android'});
      expect(almacen.token, token);
    });

    test('retirar codifica el token en la ruta y lo borra', () async {
      red.servidor.responder(
        'DELETE',
        '/api/dispositivos/${Uri.encodeComponent(token)}',
        codigo: 204,
      );
      final almacen = TokenPushEnMemoria(token);
      await DispositivosPushRed(http, almacen).retirar();
      expect(red.servidor.peticiones, hasLength(1));
      expect(almacen.token, isNull);
    });

    test('retirar con 404 se toma como hecho', () async {
      red.servidor.responder(
        'DELETE',
        '/api/dispositivos/${Uri.encodeComponent(token)}',
        codigo: 404,
        cuerpo: {'message': 'no existe'},
      );
      final almacen = TokenPushEnMemoria(token);
      await DispositivosPushRed(http, almacen).retirar();
      expect(almacen.token, isNull);
    });

    test('retirar sin red conserva el token para reintentar', () async {
      red.servidor.sinRed = true;
      final almacen = TokenPushEnMemoria(token);
      await expectLater(
        DispositivosPushRed(http, almacen).retirar(),
        throwsA(isA<SinConexion>()),
      );
      expect(almacen.token, token);
    });

    test('un fallo no filtra el token en el mensaje', () async {
      red.servidor.responder(
        'POST',
        '/api/dispositivos',
        codigo: 422,
        cuerpo: {'message': 'Token inválido.'},
      );
      try {
        await DispositivosPushRed(
          http,
          TokenPushEnMemoria(),
        ).registrar(token, PlataformaPush.ios);
        fail('debía fallar');
      } on OperacionRechazada catch (e) {
        expect('${e.mensaje} $e', isNot(contains(token)));
      }
    });

    test('el token push no se escribe en preferencias planas', () {
      final fuente = File(
        'lib/nucleo/notificaciones/push/token_push_store.dart',
      ).readAsStringSync();
      expect(fuente, contains('FlutterSecureStorage'));
      expect(fuente, isNot(contains('package:shared_preferences')));
    });
  });

  group('foto de perfil', () {
    test('subir usa PUT /api/perfil/foto y devuelve la URL firmada', () async {
      red.servidor.responder(
        'PUT',
        '/api/perfil/foto',
        cuerpo: {'foto_url': '/api/personas/7/foto?expires=1&signature=ab'},
      );
      final url = await FotoPerfilRed(http).subir(_foto());
      expect(url, contains('/api/personas/7/foto'));
      expect(red.servidor.de('PUT', '/api/perfil/foto'), hasLength(1));
    });

    test('una foto de 300 KB o más ni se envía', () async {
      await expectLater(
        FotoPerfilRed(http).subir(_foto(300 * 1024)),
        throwsA(isA<OperacionRechazada>()),
      );
      expect(red.servidor.peticiones, isEmpty);
    });

    test('quitar usa DELETE y acepta 204', () async {
      red.servidor.responder('DELETE', '/api/perfil/foto', codigo: 204);
      await FotoPerfilRed(http).quitar();
      expect(red.servidor.de('DELETE', '/api/perfil/foto'), hasLength(1));
    });

    test('actual lee foto_url de la sesión, con o sin foto', () async {
      red.servidor.responder(
        'GET',
        '/api/auth/sesion',
        cuerpo: {
          'usuario': {'id': 7, 'name': 'Camila', 'foto_url': '/api/x'},
        },
      );
      expect(await FotoPerfilRed(http).actual(), '/api/x');
      red.servidor.responder(
        'GET',
        '/api/auth/sesion',
        cuerpo: {
          'usuario': {'id': 7, 'name': 'Camila', 'foto_url': null},
        },
      );
      expect(await FotoPerfilRed(http).actual(), isNull);
    });

    test('demo: subir y quitar', () async {
      final demo = FotoPerfilDemo();
      expect(await demo.actual(), isNull);
      await demo.subir(_foto());
      expect(await demo.actual(), isNotNull);
      await demo.quitar();
      expect(await demo.actual(), isNull);
    });
  });

  group('fotos de terreno', () {
    test('subir manda la descripción y devuelve la foto', () async {
      red.servidor.responder(
        'POST',
        '/api/terrenos/12/fotos',
        codigo: 201,
        cuerpo: {
          'foto': {
            'id': 5,
            'descripcion': 'Borde norte',
            'url': '/api/terrenos/fotos/5/archivo?expires=1&signature=ab',
          },
        },
      );
      final foto = await FotosTerrenoRed(
        http,
      ).subir(12, _foto(), descripcion: 'Borde norte');
      expect(foto.id, 5);
      expect(foto.descripcion, 'Borde norte');
    });

    test('borrar usa DELETE y 404 llega como rechazo', () async {
      red.servidor.responder('DELETE', '/api/terrenos/12/fotos/5', codigo: 204);
      red.servidor.responder(
        'DELETE',
        '/api/terrenos/12/fotos/6',
        codigo: 404,
        cuerpo: {'message': 'no existe'},
      );
      final repo = FotosTerrenoRed(http);
      await repo.borrar(12, 5);
      await expectLater(
        repo.borrar(12, 6),
        throwsA(isA<OperacionRechazada>().having((e) => e.codigo, 'c', 404)),
      );
    });

    test(
      '403 (rol que no es cliente) y 422 (máximo) llegan con código',
      () async {
        red.servidor.responder(
          'POST',
          '/api/terrenos/1/fotos',
          codigo: 403,
          cuerpo: {'message': 'Solo clientes.'},
        );
        red.servidor.responder(
          'POST',
          '/api/terrenos/2/fotos',
          codigo: 422,
          cuerpo: {'message': 'El terreno ya tiene 8 fotos.'},
        );
        final repo = FotosTerrenoRed(http);
        await expectLater(
          repo.subir(1, _foto()),
          throwsA(isA<OperacionRechazada>().having((e) => e.codigo, 'c', 403)),
        );
        await expectLater(
          repo.subir(2, _foto()),
          throwsA(
            isA<OperacionRechazada>()
                .having((e) => e.codigo, 'c', 422)
                .having((e) => e.mensaje, 'm', contains('8 fotos')),
          ),
        );
      },
    );

    test('demo: tope de 8 fotos', () async {
      final demo = FotosTerrenoDemo();
      for (var i = 0; i < FotosTerrenoRepositorio.maximo; i++) {
        await demo.subir(1, _foto());
      }
      await expectLater(
        demo.subir(1, _foto()),
        throwsA(isA<OperacionRechazada>()),
      );
      await demo.borrar(1, demo.de(1).first.id);
      expect(demo.de(1), hasLength(7));
    });

    test('terreno.fotos se mapea al dominio y sin fotos queda vacío', () {
      expect(FotoTerreno.lista(null), isEmpty);
      final fotos = FotoTerreno.lista([
        {'id': 5, 'url': '/api/terrenos/fotos/5/archivo', 'descripcion': null},
        'basura',
      ]);
      expect(fotos.single.id, 5);
    });
  });

  group('mapeo de lo que la API sumó a recursos existentes', () {
    test('la oferta trae la foto del piloto (o null)', () {
      Map<String, dynamic> oferta(Object? foto) => {
        'id': 1,
        'solicitud_id': 8,
        'precio_ha': '124.0000',
        'monto_estimado': '7440.00',
        'proveedor': {'id': 2, 'nombre': 'Camila Rojas', 'foto_url': foto},
      };
      expect(
        MapeoSolicitud.oferta(
          oferta('/api/personas/7/foto?x=1'),
        ).proveedor.fotoUrl,
        '/api/personas/7/foto?x=1',
      );
      expect(MapeoSolicitud.oferta(oferta(null)).proveedor.fotoUrl, isNull);
    });

    test('el terreno trae sus fotos en el lote del cliente y del piloto', () {
      final terreno = {
        'id': 12,
        'nombre': 'Lote Norte',
        'hectareas': '120.5000',
        'fotos': [
          {'id': 5, 'url': '/api/terrenos/fotos/5/archivo', 'descripcion': 'a'},
        ],
      };
      final lote = MapeoSolicitud.lote(terreno);
      expect(lote.fotos.single.id, 5);
      expect(lote.hectareas, Decimal.parse('120.5'));

      final abierta = MapeoNegociacion.solicitud({
        'id': 8,
        'hectareas_solicitadas': '60.0000',
        'precio_ha_propuesto': '120.0000',
        'terreno': {
          ...terreno,
          'geometria': {
            'type': 'Polygon',
            'coordinates': [
              [
                [-63.0, -17.0],
                [-63.0, -17.1],
                [-63.1, -17.1],
                [-63.0, -17.0],
              ],
            ],
          },
        },
      });
      expect(abierta.terreno!.fotos.single.url, contains('/fotos/5/'));
    });
  });
}
