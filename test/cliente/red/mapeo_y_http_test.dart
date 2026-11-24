import 'package:agrocom_field/cliente/red/cliente_http.dart';
import 'package:agrocom_field/cliente/red/mapeo_solicitud.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles_red.dart';

void main() {
  group('MapeoSolicitud', () {
    test('cada estado de la API cae en un estado de la app', () {
      expect(
        MapeoSolicitud.estado('borrador'),
        EstadoServicio.buscandoProveedor,
      );
      expect(
        MapeoSolicitud.estado('en_asignacion'),
        EstadoServicio.buscandoProveedor,
      );
      expect(
        MapeoSolicitud.estado('sin_proveedor'),
        EstadoServicio.buscandoProveedor,
      );
      expect(MapeoSolicitud.estado('asignada'), EstadoServicio.asignado);
      expect(MapeoSolicitud.estado('en_camino'), EstadoServicio.asignado);
      expect(MapeoSolicitud.estado('en_ejecucion'), EstadoServicio.enEjecucion);
      expect(
        MapeoSolicitud.estado('suspendida_por_clima'),
        EstadoServicio.enEjecucion,
      );
      expect(MapeoSolicitud.estado('ejecutada'), EstadoServicio.completado);
      expect(MapeoSolicitud.estado('en_disputa'), EstadoServicio.completado);
      expect(MapeoSolicitud.estado('completada'), EstadoServicio.completado);
      expect(MapeoSolicitud.estado('cancelada'), EstadoServicio.cancelado);
    });

    test('separa el producto de la dosis y las vuelve a unir', () {
      final (producto, dosis) = MapeoSolicitud.productoYDosis(
        'Glifosato 480 SL, 2 L/ha',
      );
      expect(producto, 'Glifosato 480 SL');
      expect(dosis, Decimal.parse('2'));
      expect(
        MapeoSolicitud.productoYDosis('Fungicida, 1,5 L/ha').$2,
        Decimal.parse('1.5'),
      );
      expect(
        MapeoSolicitud.productoYDosis('Solo un producto').$2,
        Decimal.zero,
      );
      expect(
        MapeoSolicitud.productoIndicado(
          'Glifosato 480 SL',
          Decimal.parse('2.5'),
        ),
        'Glifosato 480 SL, 2.5 L/ha',
      );
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

    test('el servicio conserva los importes y las hectáreas exactos', () {
      final s = MapeoSolicitud.servicio(
        solicitudJson(
          historial: [pasoHistorial('borrador', '2026-11-24T12:00:00+00:00')],
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
      expect(s.estado, EstadoServicio.completado);
      expect(s.precio, Decimal.parse('7200.00'));
      expect(s.hectareasDeclaradas, Decimal.parse('60'));
      expect(s.hectareasCubiertas, s.hectareasDeclaradas);
      expect(s.dosisLitrosPorHectarea, Decimal.parse('2'));
      expect(s.producto, 'Glifosato 480 SL');
      expect(s.lote.zona, 'Cuatro Cañadas');
      expect(s.lote.poligono, hasLength(4));
      expect(s.fechaDeseada, DateTime(2026, 11, 27));
      expect(s.proveedor?.nombre, 'Agrocom SRL');
      expect(s.puntajeDelCliente, 5);
    });

    test('un servicio recién publicado no tiene proveedor ni avance', () {
      final s = MapeoSolicitud.servicio(
        solicitudJson(
          estado: 'en_asignacion',
          proveedorId: null,
          montoFinal: null,
        ),
      );
      expect(s.estado, EstadoServicio.buscandoProveedor);
      expect(s.proveedor, isNull);
      expect(s.hectareasCubiertas, Decimal.zero);
      expect(s.precio, Decimal.parse('7200.00'));
      expect(s.lote.zona, 'Sin zona asignada');
    });

    test('la estimación trae solo los recargos que cobran algo', () {
      final e = MapeoSolicitud.estimacion(
        {
          'congelada': false,
          'tarifa_base_hectarea': '120.0000',
          'tarifa_hectarea': '132.0000',
          'hectareas': '80.0000',
          'subtotal_base': '9600.00',
          'recargo_urgente': '1920.00',
          'recargo_acceso_dificil': '0.00',
          'recargo_producto': null,
          'monto_estimado': '11520.00',
        },
        dosis: Decimal.parse('2'),
        hectareas: Decimal.parse('80'),
      );
      expect(e.precio, Decimal.parse('11520.00'));
      expect(e.subtotal, Decimal.parse('9600.00'));
      expect(e.precioPorHectarea, Decimal.parse('120'));
      expect(e.litros, Decimal.parse('160'));
      expect(e.recargos, hasLength(1));
      expect(e.recargos.single.monto, Decimal.parse('1920.00'));
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
