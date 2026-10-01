// TE-23: con ADR 0022 de `agrocom-api` una orden cubre todos los lotes del
// contrato. `OrdenVigente` guarda un solo lote (`loteId`) más la cantidad y
// las hectáreas de todos; estos derivados deciden qué muestra la pantalla.

import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

OrdenVigente _orden({
  int? cantidadLotes,
  Decimal? hectareasSolicitadas,
  Decimal? loteHectareas,
}) => OrdenVigente(
  id: 1,
  contratoId: 1,
  loteId: 3,
  nroAplicacion: 1,
  fechaEmision: '2026-09-20',
  estado: 'vigente',
  updatedAt: DateTime.utc(2026, 9, 20),
  cantidadLotes: cantidadLotes,
  hectareasSolicitadas: hectareasSolicitadas,
  loteHectareas: loteHectareas,
);

void main() {
  group('otrosLotes', () {
    test('es 0 con un solo lote', () {
      expect(_orden(cantidadLotes: 1).otrosLotes, 0);
    });

    test('es 0 si la cantidad todavía no llegó (fila de antes de v10)', () {
      expect(_orden().otrosLotes, 0);
    });

    test('cuenta los lotes de la orden que no son loteId', () {
      expect(_orden(cantidadLotes: 3).otrosLotes, 2);
    });
  });

  group('hectareasOrden', () {
    test('usa la suma de lotes[] y no la superficie de un lote', () {
      final orden = _orden(
        cantidadLotes: 2,
        hectareasSolicitadas: Decimal.parse('170.50'),
        loteHectareas: Decimal.parse('120.50'),
      );
      expect(orden.hectareasOrden, Decimal.parse('170.50'));
    });

    test('sin la suma todavía, cae a la superficie del lote conocido', () {
      final orden = _orden(loteHectareas: Decimal.parse('120.50'));
      expect(orden.hectareasOrden, Decimal.parse('120.50'));
    });

    test('sin ninguno de los dos, es null (la pantalla dice sin datos)', () {
      expect(_orden().hectareasOrden, isNull);
    });
  });
}
