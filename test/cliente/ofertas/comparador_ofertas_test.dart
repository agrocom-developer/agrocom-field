import 'package:agrocom_field/cliente/ofertas/data/ofertas_red.dart';
import 'package:agrocom_field/cliente/ofertas/domain/comparador_ofertas.dart';
import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/proveedor.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../red/dobles_red.dart';

OfertaRecibida _oferta(
  String id, {
  required String precio,
  double calificacion = 4.0,
  TipoProveedor tipo = TipoProveedor.independiente,
  String litros = '40',
  String monto = '1000',
  DateTime? creada,
  EstadoOferta estado = EstadoOferta.vigente,
}) => OfertaRecibida(
  id: id,
  solicitudId: '1',
  numero: 1,
  autor: AutorOferta.proveedor,
  precioHa: Decimal.parse(precio),
  montoEstimado: Decimal.parse(monto),
  estado: estado,
  creadaEn: creada ?? DateTime(2026, 11, 20),
  proveedor: ProveedorOfertante(
    id: 'p$id',
    nombre: 'Piloto $id',
    calificacion: calificacion,
    calificaciones: 5,
    tasaCancelacion: 0,
    capacidadLitros: Decimal.parse(litros),
    tipo: tipo,
  ),
);

void main() {
  final ofertas = [
    _oferta('a', precio: '120', calificacion: 4.2, monto: '9600'),
    _oferta(
      'b',
      precio: '105',
      calificacion: 4.9,
      tipo: TipoProveedor.propioAgrocom,
      litros: '30',
      monto: '8400',
      creada: DateTime(2026, 11, 22),
    ),
    _oferta(
      'c',
      precio: '110',
      calificacion: 4.9,
      tipo: TipoProveedor.duenoDeDrones,
      monto: '8800',
      creada: DateTime(2026, 11, 21),
    ),
    _oferta('d', precio: '90', estado: EstadoOferta.vencida),
  ];

  List<String> ids(FiltrosOfertas f) => [
    for (final o in ComparadorOfertas.aplicar(ofertas, f)) o.id,
  ];

  group('orden', () {
    test('recomendado: propios, luego calificación, luego precio', () {
      expect(ids(const FiltrosOfertas()), ['b', 'c', 'a', 'd']);
    });

    test('por precio, con las vencidas al final', () {
      expect(ids(const FiltrosOfertas(orden: OrdenOfertas.precio)), [
        'b',
        'c',
        'a',
        'd',
      ]);
    });

    test('por calificación, desempata el menor precio', () {
      expect(ids(const FiltrosOfertas(orden: OrdenOfertas.calificacion)), [
        'b',
        'c',
        'a',
        'd',
      ]);
    });

    test('lo más reciente primero', () {
      expect(ids(const FiltrosOfertas(orden: OrdenOfertas.reciente)), [
        'b',
        'c',
        'a',
        'd',
      ]);
    });
  });

  group('filtros', () {
    test('rango de precio por hectárea', () {
      final f = FiltrosOfertas(
        precioHaMin: Decimal.parse('106'),
        precioHaMax: Decimal.parse('115'),
      );
      expect(ids(f), ['c']);
    });

    test('total máximo', () {
      expect(ids(FiltrosOfertas(montoMax: Decimal.parse('9000'))), [
        'b',
        'c',
        'd',
      ]);
    });

    test('calificación mínima y tipo de proveedor', () {
      expect(ids(FiltrosOfertas(calificacionMin: Decimal.parse('4.5'))), [
        'b',
        'c',
      ]);
      expect(
        ids(const FiltrosOfertas(tipoProveedor: TipoProveedor.propioAgrocom)),
        ['b'],
      );
    });

    test('capacidad mínima del tanque', () {
      expect(ids(FiltrosOfertas(capacidadTanqueMin: Decimal.parse('35'))), [
        'c',
        'a',
        'd',
      ]);
    });

    test('cuenta los filtros activos sin contar el orden', () {
      expect(const FiltrosOfertas(orden: OrdenOfertas.precio).activos, 0);
      expect(
        FiltrosOfertas(
          precioHaMin: Decimal.one,
          tipoProveedor: TipoProveedor.independiente,
        ).activos,
        2,
      );
    });

    test('aConsulta usa los nombres del contrato', () {
      final f = FiltrosOfertas(
        orden: OrdenOfertas.calificacion,
        precioHaMin: Decimal.parse('100'),
        precioHaMax: Decimal.parse('130'),
        montoMax: Decimal.parse('10000'),
        calificacionMin: Decimal.parse('4.5'),
        tipoProveedor: TipoProveedor.duenoDeDrones,
        capacidadTanqueMin: Decimal.parse('30'),
      );
      expect(f.aConsulta(), {
        'orden': 'calificacion',
        'precio_ha_min': '100',
        'precio_ha_max': '130',
        'monto_max': '10000',
        'calificacion_min': '4.5',
        'tipo_proveedor': 'tercero',
        'capacidad_tanque_min': '30',
      });
    });
  });

  group('LecturaFiltro', () {
    test('acepta coma decimal y rechaza lo que no es número', () {
      expect(LecturaFiltro.leer('120,5'), Decimal.parse('120.5'));
      expect(LecturaFiltro.leer(''), isNull);
      expect(LecturaFiltro.esValido(''), isTrue);
      expect(LecturaFiltro.esValido('abc'), isFalse);
    });
  });

  group('OfertasRed', () {
    test('pide el comparador con orden y filtros', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'GET',
        '/api/solicitudes/5/ofertas',
        cuerpo: {
          'ofertas': [ofertaJson(id: 21, solicitudId: 5)],
        },
      );
      await OfertasRed(red.http, red.fuente).deLaSolicitud(
        '5',
        filtros: FiltrosOfertas(
          orden: OrdenOfertas.precio,
          calificacionMin: Decimal.parse('4'),
        ),
      );
      final p = red.servidor.de('GET', '/api/solicitudes/5/ofertas').single;
      expect(p.query, {'orden': 'precio', 'calificacion_min': '4'});
    });

    test('contraofertar envía la justificación y nunca el total', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'POST',
        '/api/ofertas/21/contraofertar',
        codigo: 201,
        cuerpo: {'oferta': ofertaJson(id: 30, numero: 2, autor: 'cliente')},
      );
      await OfertasRed(red.http, red.fuente).contraofertar(
        '21',
        precioHa: Decimal.parse('122'),
        claveIdempotencia: 'clave-1',
        justificacionPrecio: ' Incluye\ntraslado ',
      );
      final cuerpo =
          red.servidor
                  .de('POST', '/api/ofertas/21/contraofertar')
                  .single
                  .cuerpo!
              as Map;
      expect(cuerpo['justificacion_precio'], 'Incluye traslado');
      expect(cuerpo.containsKey('monto_estimado'), isFalse);
      expect(cuerpo.containsKey('total'), isFalse);
    });

    test('sin justificación no se envía la clave', () async {
      final red = EntornoRed();
      red.servidor.responder(
        'POST',
        '/api/ofertas/21/contraofertar',
        codigo: 201,
        cuerpo: {'oferta': ofertaJson(id: 30, numero: 2, autor: 'cliente')},
      );
      await OfertasRed(red.http, red.fuente).contraofertar(
        '21',
        precioHa: Decimal.parse('122'),
        claveIdempotencia: 'clave-2',
        justificacionPrecio: '   ',
      );
      final cuerpo =
          red.servidor
                  .de('POST', '/api/ofertas/21/contraofertar')
                  .single
                  .cuerpo!
              as Map;
      expect(cuerpo.containsKey('justificacion_precio'), isFalse);
    });
  });
}
