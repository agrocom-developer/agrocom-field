// HU-70: reglas puras de `TrabajoAsignado` — qué dosis se muestra (nunca
// las dos) y cuándo se puede crear la aplicación sin inventar datos.

import 'package:agrocom_field/features/inicio/domain/trabajo_asignado.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

TrabajoAsignado _trabajo({
  Decimal? litrosHa,
  Decimal? kilosPorVuelo,
  int? nroAplicacion,
}) => TrabajoAsignado(
  id: 42,
  uuidCliente: 'uuid-panel-42',
  ordenId: 1,
  loteId: 3,
  hectareasDeclaradas: Decimal.parse('300.00'),
  equipoTrabajoId: 7,
  updatedAt: DateTime.utc(2026, 9, 22),
  litrosHa: litrosHa,
  kilosPorVuelo: kilosPorVuelo,
  nroAplicacion: nroAplicacion,
);

void main() {
  group('dosis', () {
    test('insumo líquido: L/ha', () {
      final dosis = _trabajo(litrosHa: Decimal.parse('12')).dosis!;
      expect(dosis.valor, Decimal.parse('12'));
      expect(dosis.unidad, 'L/ha');
    });

    test('insumo sólido: kg/vuelo', () {
      final dosis = _trabajo(kilosPorVuelo: Decimal.parse('8.5')).dosis!;
      expect(dosis.valor, Decimal.parse('8.5'));
      expect(dosis.unidad, 'kg/vuelo');
    });

    test('sin orden en el catálogo: null, nunca un valor inventado', () {
      expect(_trabajo().dosis, isNull);
    });
  });

  group('puedeCrearAplicacion', () {
    test('con la orden ya bajada (nroAplicacion conocido)', () {
      expect(_trabajo(nroAplicacion: 2).puedeCrearAplicacion, isTrue);
    });

    test('sin la orden todavía: no, faltaría nroAplicacion', () {
      expect(_trabajo().puedeCrearAplicacion, isFalse);
    });
  });
}
