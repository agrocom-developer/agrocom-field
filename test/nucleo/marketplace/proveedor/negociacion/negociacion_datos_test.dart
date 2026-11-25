// Datos de la negociación del piloto: traducción del JSON de la API al
// dominio, repositorios de red contra un servidor falso y el aviso local de
// solicitudes nuevas.

import 'package:agrocom_field/nucleo/api/marketplace_http.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/mapeo_negociacion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/negociacion_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/data/negociacion_red.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/avisador_solicitudes.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/negociacion.dart';
import 'package:agrocom_field/nucleo/notificaciones/notificador_local.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../cliente/red/dobles_red.dart';

Map<String, dynamic> _abierta({
  int id = 16,
  String ha = '40.0000',
  String precio = '121.0000',
  String macro = 'norte_integrado',
  Object? terreno,
}) => {
  'id': id,
  'centro': {'latitud': -17.5351, 'longitud': -63.1978},
  'hectareas_solicitadas': ha,
  'precio_ha_propuesto': precio,
  'zona': 'Warnes',
  'zona_id': 2,
  'macrorregion': macro,
  'cultivo': 'Soya',
  'tipo_aplicacion': 'herbicida',
  'ventana_desde': '2026-12-06',
  'ventana_hasta': '2026-12-09',
  'ofertas_vigentes': 1,
  'mi_negociacion': null,
  'distancia_km': null,
  'vence_en': '2026-12-01T04:03:45+00:00',
  'terreno': ?terreno,
};

Map<String, dynamic> _oferta({
  int id = 5,
  String autor = 'cliente',
  String estado = 'vigente',
  bool definitiva = false,
}) => {
  'id': id,
  'uuid_cliente': 'uuid-$id',
  'solicitud_id': 6,
  'numero': 2,
  'autor': autor,
  'tipo': 'contraoferta',
  'precio_ha': '122.0000',
  'monto_estimado': '12200.00',
  'estado': estado,
  'es_definitiva': definitiva,
  'nota': 'Tengo otra oferta más baja',
  'vence_en': '2026-11-26T06:03:45+00:00',
};

class _NotificadorFalso implements NotificadorLocal {
  final mostradas = <(String, String)>[];

  @override
  Future<bool> pedirPermiso() async => true;

  @override
  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
  }) async => mostradas.add((titulo, cuerpo));
}

void main() {
  group('mapeo', () {
    test(
      'una solicitud del mapa conserva hectáreas y precio como decimal exacto',
      () {
        final s = MapeoNegociacion.solicitud(_abierta(ha: '40.1000'));
        expect(s.hectareas, Decimal.parse('40.1'));
        expect(s.precioHaPropuesto, Decimal.parse('121'));
        expect(s.montoPropuesto, Decimal.parse('4852.1'));
        expect(s.macrorregion, Macrorregion.norteIntegrado);
        expect(s.ubicacion, const GeoPunto(-17.5351, -63.1978));
      },
    );

    test('el detalle trae el polígono GeoJSON sin el vértice repetido', () {
      final s = MapeoNegociacion.solicitud(
        _abierta(
          terreno: {
            'nombre': 'Lote Norte',
            'hectareas': '80.0000',
            'acceso_dificil': true,
            'referencias_acceso': 'Camino vecinal',
            'geometria': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [-63.2, -17.5],
                  [-63.1, -17.5],
                  [-63.1, -17.4],
                  [-63.2, -17.5],
                ],
              ],
            },
          },
        ),
      );
      expect(s.terreno!.poligono, hasLength(3));
      expect(s.terreno!.poligono.first, const GeoPunto(-17.5, -63.2));
      expect(s.accesoDificil, isTrue);
      expect(s.referenciasAcceso, 'Camino vecinal');
    });

    test('una oferta del cliente vigente le toca responder al piloto', () {
      final o = MapeoNegociacion.oferta(_oferta());
      expect(o.esperaMiRespuesta, isTrue);
      expect(o.esperaAlCliente, isFalse);
      expect(o.hectareas, Decimal.parse('100'));
      final propia = MapeoNegociacion.oferta(_oferta(autor: 'proveedor'));
      expect(propia.esperaAlCliente, isTrue);
      final cerrada = MapeoNegociacion.oferta(_oferta(estado: 'reemplazada'));
      expect(cerrada.estado.activa, isFalse);
    });

    test('la oferta lee la zona y el lote que manda el servidor', () {
      final sinLote = MapeoNegociacion.oferta({
        ..._oferta(),
        'zona': 'Montero',
        'zona_id': 3,
        'lote': null,
      });
      final adjudicada = MapeoNegociacion.oferta({
        ..._oferta(),
        'zona': 'Montero',
        'lote': 'Lote Sur',
      });
      expect(sinLote.zona, 'Montero');
      expect(sinLote.lote, isNull);
      expect(adjudicada.lote, 'Lote Sur');
      expect(MapeoNegociacion.oferta(_oferta()).zona, isNull);
    });

    test('las preferencias viajan de ida y vuelta', () {
      const p = PreferenciasAviso(
        macrorregiones: [Macrorregion.valles, Macrorregion.chiquitania],
        mensajes: false,
      );
      final json = MapeoNegociacion.preferenciasAJson(p);
      final vuelta = MapeoNegociacion.preferencias(json);
      expect(vuelta.macrorregiones, p.macrorregiones);
      expect(vuelta.mensajes, isFalse);
      expect(vuelta.nuevasSolicitudes, isTrue);
    });

    test('la consulta del mapa envía solo los filtros que se pusieron', () {
      final q = MapeoNegociacion.consulta(
        FiltrosMapa(
          macrorregion: Macrorregion.valles,
          hectareasMin: Decimal.parse('50'),
          orden: OrdenMapa.precioHa,
        ),
        lat: -17.8,
        lon: -63.1,
      );
      expect(q, {
        'macrorregion': 'valles',
        'hectareas_min': '50',
        'orden': 'precio_ha',
        'lat': -17.8,
        'lon': -63.1,
      });
    });

    test('las preferencias deciden qué solicitud merece un aviso', () {
      final grande = MapeoNegociacion.solicitud(_abierta(ha: '120'));
      final chica = MapeoNegociacion.solicitud(_abierta(ha: '10'));
      final valles = MapeoNegociacion.solicitud(_abierta(macro: 'valles'));
      final p = PreferenciasAviso(
        macrorregiones: const [Macrorregion.norteIntegrado],
        hectareasMinimas: Decimal.parse('50'),
      );
      expect(p.aplicaA(grande), isTrue);
      expect(p.aplicaA(chica), isFalse);
      expect(p.aplicaA(valles), isFalse);
      expect(
        const PreferenciasAviso(nuevasSolicitudes: false).aplicaA(grande),
        isFalse,
      );
    });
  });

  group('red', () {
    late EntornoRed e;
    late MarketplaceHttp http;

    setUp(() {
      e = EntornoRed();
      http = MarketplaceHttp(e.api);
    });

    test('el mapa pide los filtros, lee la página y trae el cursor', () async {
      e.servidor.responder(
        'GET',
        '/api/solicitudes-abiertas',
        cuerpo: {
          'solicitudes': [_abierta()],
          'siguiente_cursor': 'Mg==',
        },
      );
      final pagina = await MercadoRed(
        http,
      ).solicitudes(const FiltrosMapa(macrorregion: Macrorregion.valles));
      expect(pagina.solicitudes.single.id, 16);
      expect(pagina.siguienteCursor, 'Mg==');
      final p = e.servidor.de('GET', '/api/solicitudes-abiertas').single;
      expect(p.query['macrorregion'], 'valles');
      expect(p.token, 'Bearer tok');
    });

    test('aceptar el precio propuesto no manda precio', () async {
      e.servidor.responder(
        'POST',
        '/api/solicitudes/16/ofertas',
        codigo: 201,
        cuerpo: {'oferta': _oferta(autor: 'proveedor')},
      );
      await MercadoRed(http).ofertar(
        solicitudId: 16,
        uuidCliente: 'clave-1',
        tipo: TipoOferta.aceptaPropuesta,
      );
      final cuerpo =
          e.servidor.de('POST', '/api/solicitudes/16/ofertas').single.cuerpo!
              as Map;
      expect(cuerpo['tipo'], 'acepta_propuesta');
      expect(cuerpo['uuid_cliente'], 'clave-1');
      expect(cuerpo.containsKey('precio_ha'), isFalse);
    });

    test('contraofertar manda el precio como texto decimal', () async {
      e.servidor.responder(
        'POST',
        '/api/solicitudes/16/ofertas',
        codigo: 201,
        cuerpo: {'oferta': _oferta(autor: 'proveedor')},
      );
      await MercadoRed(http).ofertar(
        solicitudId: 16,
        uuidCliente: 'clave-1',
        tipo: TipoOferta.contraoferta,
        precioHa: Decimal.parse('118.50'),
        nota: '  Con auxiliar  ',
      );
      final cuerpo =
          e.servidor.de('POST', '/api/solicitudes/16/ofertas').single.cuerpo!
              as Map;
      expect(cuerpo['precio_ha'], '118.5');
      expect(cuerpo['nota'], 'Con auxiliar');
    });

    test('un 409 trae el código de negocio y un mensaje en español', () async {
      e.servidor.responder(
        'POST',
        '/api/ofertas/5/aceptar',
        codigo: 409,
        cuerpo: {
          'message': 'El cliente ya eligió a otro piloto.',
          'codigo': 'solicitud_ya_adjudicada',
        },
      );
      await expectLater(
        NegociacionRed(http).aceptar(5),
        throwsA(
          isA<OperacionRechazada>()
              .having((e) => e.motivo, 'motivo', 'solicitud_ya_adjudicada')
              .having((e) => e.codigo, 'codigo', 409)
              .having(
                (e) => e.mensaje,
                'mensaje',
                'El cliente ya eligió a otro piloto.',
              ),
        ),
      );
    });

    test('sin red lanza SinConexion', () async {
      e.servidor.sinRed = true;
      await expectLater(
        NegociacionRed(http).misOfertas(),
        throwsA(isA<SinConexion>()),
      );
    });

    test('el chat envía el texto recortado con su clave', () async {
      e.servidor.responder(
        'POST',
        '/api/solicitudes/10/mensajes',
        codigo: 201,
        cuerpo: {
          'mensaje': {
            'id': 1,
            'uuid_cliente': 'm1',
            'solicitud_id': 10,
            'propio': true,
            'texto': 'Hola',
            'creado_en': '2026-11-24T12:00:00+00:00',
          },
        },
      );
      final m = await MensajesRed(
        http,
      ).enviar(10, uuidCliente: 'm1', texto: '  Hola  ');
      expect(m.propio, isTrue);
      final cuerpo =
          e.servidor.de('POST', '/api/solicitudes/10/mensajes').single.cuerpo!
              as Map;
      expect(cuerpo, {'uuid_cliente': 'm1', 'texto': 'Hola'});
    });

    test('guardar preferencias usa PUT y devuelve lo guardado', () async {
      e.servidor.responder(
        'PUT',
        '/api/notificaciones/preferencias',
        cuerpo: {
          'preferencias': MapeoNegociacion.preferenciasAJson(
            const PreferenciasAviso(nuevasSolicitudes: false),
          ),
        },
      );
      final p = await AvisosRed(
        http,
      ).guardar(const PreferenciasAviso(nuevasSolicitudes: false));
      expect(p.nuevasSolicitudes, isFalse);
    });

    test(
      'el resumen por zona lee solicitudes, hectáreas y precio medio',
      () async {
        e.servidor.responder(
          'GET',
          '/api/solicitudes-abiertas/resumen-zonas',
          cuerpo: {
            'zonas': [
              {
                'zona_id': 11,
                'zona': 'Vallegrande',
                'macrorregion': 'valles',
                'solicitudes': 1,
                'hectareas_total': '60.0000',
                'precio_ha_promedio': '130.0000',
              },
            ],
          },
        );
        final zonas = await MercadoRed(http).resumenZonas(const FiltrosMapa());
        expect(zonas.single.macrorregion, Macrorregion.valles);
        expect(zonas.single.hectareas, Decimal.parse('60'));
        expect(zonas.single.precioHaPromedio, Decimal.parse('130'));
      },
    );
  });

  group('aviso local de solicitudes nuevas', () {
    late AlmacenNegociacionDemo almacen;
    late _NotificadorFalso notificador;
    late SolicitudesVistasMemoria vistas;
    late AvisadorSolicitudesNuevas avisador;

    setUp(() {
      almacen = AlmacenNegociacionDemo(latencia: Duration.zero);
      notificador = _NotificadorFalso();
      vistas = SolicitudesVistasMemoria();
      avisador = AvisadorSolicitudesNuevas(
        mercado: MercadoDemo(almacen),
        avisos: AvisosDemo(almacen),
        notificador: notificador,
        vistas: vistas,
      );
    });

    test('la primera vez solo registra lo que hay, sin avisar', () async {
      expect(await avisador.revisar(), 0);
      expect(notificador.mostradas, isEmpty);
      expect((await vistas.leer())!.length, 6);
    });

    test('una solicitud nueva en sus zonas avisa una sola vez', () async {
      await avisador.revisar();
      await vistas.guardar({1, 2, 3, 4, 5}); // la 6 «llega» ahora
      expect(await avisador.revisar(), 1);
      expect(
        notificador.mostradas.single.$1,
        contains('San José de Chiquitos'),
      );
      expect(await avisador.revisar(), 0);
      expect(notificador.mostradas, hasLength(1));
    });

    test('varias nuevas se resumen en un solo aviso', () async {
      await avisador.revisar();
      await vistas.guardar({1, 2, 3});
      expect(await avisador.revisar(), 3);
      expect(notificador.mostradas.single.$1, '3 solicitudes nuevas');
    });

    test('con los avisos apagados no se notifica nada', () async {
      almacen.preferencias = const PreferenciasAviso(nuevasSolicitudes: false);
      await avisador.revisar();
      await vistas.guardar({1});
      expect(await avisador.revisar(), 0);
      expect(notificador.mostradas, isEmpty);
    });

    test('solo avisa de las zonas elegidas', () async {
      almacen.preferencias = const PreferenciasAviso(
        macrorregiones: [Macrorregion.valles],
      );
      await avisador.revisar();
      await vistas.guardar({1, 2, 4, 5, 6}); // falta Vallegrande (valles)
      expect(await avisador.revisar(), 1);
      expect(notificador.mostradas.single.$1, contains('Vallegrande'));
    });
  });
}
