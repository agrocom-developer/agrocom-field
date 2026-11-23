import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/demo/recorrido_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';

void main() {
  final ahora = DateTime(2026, 11, 23, 9);
  final datos = DatosDemo(reloj: () => ahora);

  test('los lotes caen en la zona agrícola de Santa Cruz, Bolivia', () {
    for (final lote in datos.lotes) {
      final c = lote.centro;
      expect(c.latitud, inInclusiveRange(-18.0, -16.5), reason: lote.nombre);
      expect(c.longitud, inInclusiveRange(-63.2, -62.3), reason: lote.nombre);
      expect(lote.poligono.length, greaterThanOrEqualTo(4));
    }
  });

  test('hectáreas y dinero son decimales exactos', () {
    final s = datos.servicios.first;
    expect(s.hectareasDeclaradas, isA<Decimal>());
    expect(s.litrosTotales, Decimal.parse('288.00'));
    expect(s.precio, Decimal.parse('10800.00'));
  });

  test('el servicio en curso tiene proveedor, dron y avance parcial', () {
    final s = datos.servicios.first;
    expect(s.estado, EstadoServicio.enEjecucion);
    expect(s.proveedor, isNotNull);
    expect(s.dron, isNotNull);
    expect(s.progreso, inExclusiveRange(0.0, 1.0));
  });

  test(
    'hay historial con servicios completados, cancelados y sin calificar',
    () {
      final estados = datos.servicios.map((s) => s.estado).toSet();
      expect(estados, containsAll(EstadoServicio.values));
      expect(
        datos.servicios.where(
          (s) =>
              s.estado == EstadoServicio.completado &&
              s.puntajeDelCliente == null,
        ),
        isNotEmpty,
      );
    },
  );

  test('las ofertas se ofrecen primero a la flota propia', () {
    final ofertas = datos.ofertasIniciales();
    expect(ofertas.first.esDeAgrocom, isTrue);
    expect(ofertas.first.restante(ahora), const Duration(minutes: 3));
  });

  test('el recorrido arranca y termina en el lote y el avance es monótono', () {
    final servicio = datos.servicios.first;
    final r = RecorridoDemo.paraLote(servicio.lote);
    expect(r.en(0), r.puntos.first);
    expect(r.en(1), r.puntos.last);
    var previo = 0;
    for (var i = 0; i <= 10; i++) {
      final trazo = r.trazadoHasta(i / 10);
      expect(trazo.length, greaterThanOrEqualTo(previo));
      previo = trazo.length;
    }
    final f = r.fotograma(servicio, servicio.hectareasDeclaradas);
    expect(f.estado, EstadoServicio.completado);
    expect(f.progreso, 1.0);
  });
}
