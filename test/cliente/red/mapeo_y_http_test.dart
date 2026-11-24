import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/cliente/red/cliente_http.dart';
import 'package:agrocom_field/cliente/red/mapeo_solicitud.dart';
import 'package:agrocom_field/cliente/seguimiento/domain/seguimiento.dart';
import 'package:agrocom_field/cliente/solicitudes/domain/solicitud.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_red.dart';

void main() {
  group('MapeoSolicitud', () {
    test('cada estado de la API cae en un estado de la app', () {
      expect(EstadoSolicitud.desdeApi('borrador'), EstadoSolicitud.borrador);
      expect(EstadoSolicitud.desdeApi('abierta'), EstadoSolicitud.abierta);
      expect(
        EstadoSolicitud.desdeApi('con_ofertas'),
        EstadoSolicitud.conOfertas,
      );
      expect(
        EstadoSolicitud.desdeApi('adjudicada'),
        EstadoSolicitud.adjudicada,
      );
      expect(
        EstadoSolicitud.desdeApi('en_ejecucion'),
        EstadoSolicitud.enEjecucion,
      );
      expect(
        EstadoSolicitud.desdeApi('finalizada'),
        EstadoSolicitud.finalizada,
      );
      expect(
        EstadoSolicitud.desdeApi('calificada'),
        EstadoSolicitud.calificada,
      );
      expect(EstadoSolicitud.desdeApi('disputada'), EstadoSolicitud.disputada);
      expect(EstadoSolicitud.desdeApi('expirada'), EstadoSolicitud.expirada);
      expect(EstadoSolicitud.desdeApi('cancelada'), EstadoSolicitud.cancelada);
    });

    test('lee el GeoJSON (longitud, latitud) y quita el vértice repetido', () {
      final poligono = MapeoSolicitud.poligono(
        {
          'type': 'Polygon',
          'coordinates': [
            [
              [-62.5, -17.3],
              [-62.4, -17.3],
              [-62.4, -17.2],
              [-62.5, -17.3],
            ],
          ],
        },
        hectareas: Decimal.parse('10'),
        centro: MapeoSolicitud.centroPorDefecto,
      );
      expect(poligono, const [
        GeoPunto(-17.3, -62.5),
        GeoPunto(-17.3, -62.4),
        GeoPunto(-17.2, -62.4),
      ]);
    });

    test('sin geometría arma un contorno de reserva con la superficie', () {
      final poligono = MapeoSolicitud.poligono(
        null,
        hectareas: Decimal.parse('100'),
        centro: const GeoPunto(-17.0, -62.0),
      );
      expect(poligono, hasLength(4));
      expect(poligonoContiene(poligono, const GeoPunto(-17.0, -62.0)), isTrue);
      final ha = hectareasDePoligono(poligono);
      expect((ha - Decimal.parse('100')).abs() < Decimal.parse('1'), isTrue);
    });

    test('un contorno dibujado viaja como GeoJSON cerrado', () {
      final json = MapeoSolicitud.geoJson(const [
        GeoPunto(-17.0, -62.0),
        GeoPunto(-17.0, -61.9),
        GeoPunto(-16.9, -61.9),
      ]);
      final anillo = (json['coordinates'] as List).first as List;
      expect(anillo, hasLength(4));
      expect(anillo.first, [-62.0, -17.0]);
      expect(anillo.last, anillo.first);
    });

    test('la solicitud conserva los importes y las hectáreas exactos', () {
      final s = MapeoSolicitud.solicitud(
        solicitudJson(
          historial: [
            pasoHistorial('borrador', '2026-11-24T12:00:00+00:00'),
            pasoHistorial('abierta', '2026-11-24T12:01:00+00:00'),
          ],
        ),
        zonas: const {
          6: ZonaCatalogo(
            id: 6,
            nombre: 'Cuatro Cañadas',
            centro: GeoPunto(-17.35, -62.56),
          ),
        },
        puntajeDelCliente: 5,
        nombreProveedor: 'Agrocom SRL',
      );
      expect(s.id, '8');
      expect(s.estado, EstadoSolicitud.calificada);
      expect(s.hectareas, Decimal.parse('60'));
      expect(s.precioHaPropuesto, Decimal.parse('120'));
      expect(s.precioHaAcordado, Decimal.parse('124'));
      expect(s.montoFinal, Decimal.parse('7440.00'));
      expect(s.totalAPagar, Decimal.parse('7440.00'));
      expect(s.hectareasEjecutadas, Decimal.parse('60'));
      expect(s.producto, 'Glifosato 480 SL, 2 L/ha');
      expect(s.lote.zona, 'Cuatro Cañadas');
      expect(s.lote.poligono, hasLength(4));
      expect(s.ventanaDesde, DateTime(2026, 11, 27));
      expect(s.ventanaHasta, DateTime(2026, 12, 6));
      expect(s.nombreProveedor, 'Agrocom SRL');
      expect(s.puntajeDelCliente, 5);
      expect(s.proveedorId, '1');
      expect(s.ofertaAdjudicadaId, '14');
      expect(s.historial.map((c) => c.estado), [
        EstadoSolicitud.borrador,
        EstadoSolicitud.abierta,
      ]);
    });

    test(
      'una solicitud abierta propone precio y no tiene acordado ni piloto',
      () {
        final s = MapeoSolicitud.solicitud(
          solicitudJson(
            estado: 'abierta',
            proveedorId: null,
            ofertaAdjudicadaId: null,
            precioAcordado: null,
            montoFinal: null,
            ejecutadas: null,
            porcentaje: '0.00',
          ),
          ofertasVigentes: 2,
        );
        expect(s.estado, EstadoSolicitud.abierta);
        expect(s.precioHaAcordado, isNull);
        expect(s.montoFinal, isNull);
        expect(s.proveedorId, isNull);
        expect(s.precioHaVigente, Decimal.parse('120'));
        expect(s.totalAPagar, Decimal.parse('7440.00'));
        expect(s.ofertasVigentes, 2);
        expect(s.lote.zona, 'Sin zona asignada');
      },
    );

    test('la oferta trae el precio, el piloto y su dron', () {
      final o = MapeoSolicitud.oferta(
        ofertaJson(
          precioHa: '118.5000',
          tipo: 'contraoferta',
          numero: 3,
          definitiva: true,
          nota: 'Mejor precio',
        ),
      );
      expect(o.id, '20');
      expect(o.numero, 3);
      expect(o.autor, AutorOferta.proveedor);
      expect(o.aceptaPropuesta, isFalse);
      expect(o.esDefinitiva, isTrue);
      expect(o.precioHa, Decimal.parse('118.5'));
      expect(o.estado, EstadoOferta.vigente);
      expect(o.nota, 'Mejor precio');
      expect(o.distanciaKm, Decimal.parse('22.52'));
      expect(o.proveedor.nombre, 'Mamani Agroservicios');
      expect(o.proveedor.calificacion, 4.5);
      expect(o.proveedor.calificaciones, 8);
      expect(o.proveedor.tasaCancelacion, closeTo(0.1, 1e-9));
      expect(o.proveedor.dron, 'DJI Agras T40');
      expect(o.proveedor.capacidadLitros, Decimal.parse('40'));
    });

    test('una oferta vigente espera al cliente solo si la hizo el piloto', () {
      final ahora = DateTime.utc(2026, 11, 24, 12);
      final delPiloto = MapeoSolicitud.oferta(ofertaJson());
      final delCliente = MapeoSolicitud.oferta(
        ofertaJson(autor: 'cliente', numero: 2),
      );
      final vencida = MapeoSolicitud.oferta(
        ofertaJson(venceEn: '2026-11-24T11:00:00+00:00'),
      );
      expect(delPiloto.esperaAlCliente(ahora), isTrue);
      expect(delCliente.esperaAlCliente(ahora), isFalse);
      expect(delCliente.esperaAlPiloto(ahora), isTrue);
      expect(vencida.esperaAlCliente(ahora), isFalse);
      expect(vencida.restante(ahora), Duration.zero);
    });

    test('el tipo de aplicación sale del producto escrito', () {
      expect(MapeoSolicitud.tipoAplicacion('Glifosato 480 SL'), 'herbicida');
      expect(
        MapeoSolicitud.tipoAplicacion('Insecticida piretroide'),
        'insecticida',
      );
      expect(MapeoSolicitud.tipoAplicacion('Fungicida triazol'), 'fungicida');
      expect(
        MapeoSolicitud.tipoAplicacion('Fertilizante foliar'),
        'fertilizante_foliar',
      );
      expect(MapeoSolicitud.tipoAplicacion('Otra cosa'), 'otro');
    });

    test('las fechas de calendario viajan sin hora', () {
      expect(MapeoSolicitud.diaApi(DateTime(2026, 3, 5)), '2026-03-05');
      expect(MapeoSolicitud.dia('2026-12-06'), DateTime(2026, 12, 6));
    });
  });

  group('ClienteHttp', () {
    late EntornoRed red;
    setUp(() => red = EntornoRed());

    test('devuelve el JSON decodificado y manda el token', () async {
      red.servidor.responder(
        'GET',
        '/api/clientes/mi',
        cuerpo: {'cliente': {}},
      );
      final r = await red.http.obtener('/api/clientes/mi');
      expect(r, {'cliente': {}});
      expect(red.servidor.peticiones.single.token, 'Bearer tok');
    });

    test('sin red lanza SinConexion', () async {
      red.servidor.sinRed = true;
      await expectLater(
        red.http.obtener('/api/clientes/mi'),
        throwsA(isA<SinConexion>()),
      );
    });

    test('un 422 muestra el motivo del servidor', () async {
      red.servidor.responder(
        'POST',
        '/api/solicitudes',
        codigo: 422,
        cuerpo: {'message': 'Las hectáreas superan las del terreno.'},
      );
      await expectLater(
        red.http.enviar('/api/solicitudes'),
        throwsA(
          isA<OperacionRechazada>().having(
            (e) => e.mensaje,
            'mensaje',
            'Las hectáreas superan las del terreno.',
          ),
        ),
      );
    });

    test('los demás códigos dicen qué hacer, en español', () async {
      expect(
        ClienteHttp.mensajeDeServidor(404, null),
        contains('No encontramos'),
      );
      expect(
        ClienteHttp.mensajeDeServidor(500, null),
        contains('Intenta de nuevo'),
      );
      expect(ClienteHttp.mensajeDeServidor(429, null), contains('Espera'));
      expect(
        ClienteHttp.mensajeDeServidor(401, null),
        contains('sesión venció'),
      );
    });

    test('un 409 puede tratarse como éxito idempotente', () async {
      red.servidor.responder('POST', '/api/x', codigo: 409, cuerpo: {});
      final r = await red.http.enviar('/api/x', conflictoComoExito: true);
      expect(r[ClienteHttp.claveConflicto], isTrue);
      await expectLater(
        red.http.enviar('/api/x'),
        throwsA(isA<OperacionRechazada>()),
      );
    });

    test('un 409 de la negociación avisa que la oferta cambió', () async {
      red.servidor.responder(
        'POST',
        '/api/ofertas/20/aceptar',
        codigo: 409,
        cuerpo: {
          'message': 'La oferta ya no está vigente.',
          'codigo': 'oferta_no_vigente',
        },
      );
      await expectLater(
        red.http.enviar('/api/ofertas/20/aceptar'),
        throwsA(
          isA<OfertaCambio>().having(
            (e) => e.mensaje,
            'mensaje',
            'La oferta ya no está vigente.',
          ),
        ),
      );
      red.servidor.responder(
        'POST',
        '/api/solicitudes/8/mensajes',
        codigo: 409,
        cuerpo: {'message': 'El chat se cerró.', 'codigo': 'chat_cerrado'},
      );
      await expectLater(
        red.http.enviar('/api/solicitudes/8/mensajes'),
        throwsA(isA<ChatCerrado>()),
      );
    });

    test('un 404 opcional devuelve null', () async {
      expect(await red.http.obtenerOpcional('/api/nada'), isNull);
    });

    test('un 401 avisa que la sesión venció, salvo en el login', () async {
      var avisos = 0;
      red.api.alSesionExpirada = () => avisos++;
      red.servidor
        ..responder('GET', '/api/clientes/mi', codigo: 401, cuerpo: {})
        ..responder('POST', '/api/auth/token', codigo: 401, cuerpo: {});
      await expectLater(
        red.http.obtener('/api/clientes/mi'),
        throwsA(isA<OperacionRechazada>()),
      );
      expect(avisos, 1);
      await expectLater(
        red.http.enviar('/api/auth/token'),
        throwsA(isA<OperacionRechazada>()),
      );
      expect(avisos, 1);
    });
  });
}
