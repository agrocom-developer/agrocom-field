// Tarea 27: un trabajo de una orden `pausada` sigue siendo «el trabajo
// asignado» (`agrocom-api` #313 no lo retira), pero llega a «Inicio» con la
// orden marcada como pausada, y deja de estarlo cuando el pull la desmarca.

import 'package:agrocom_field/features/inicio/data/inicio_repository.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late InicioRepository repositorio;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = InicioRepository(db);
    await db
        .into(db.ordenCatalogo)
        .insert(
          OrdenCatalogoCompanion.insert(
            id: const Value(1),
            contratoId: 1,
            loteId: 3,
            nroAplicacion: 2,
            fechaEmision: '2026-09-20',
            estado: 'vigente',
            updatedAt: DateTime.utc(2026, 9, 20),
          ),
        );
    await db
        .into(db.trabajoCatalogo)
        .insert(
          TrabajoCatalogoCompanion.insert(
            id: const Value(42),
            uuidCliente: 'uuid-panel-42',
            ordenId: 1,
            loteId: 3,
            hectareasDeclaradas: Decimal.parse('300.00'),
            equipoTrabajoId: 7,
            updatedAt: DateTime.utc(2026, 9, 22),
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> marcarOrden(String? motivo) =>
      (db.update(db.ordenCatalogo)..where((t) => t.id.equals(1))).write(
        OrdenCatalogoCompanion(motivoRetiro: Value(motivo)),
      );

  test(
    'orden pausada: el trabajo sigue asignado, con la orden pausada',
    () async {
      await marcarOrden('pausada');

      final trabajo = (await repositorio.trabajoAsignado().first)!;

      expect(trabajo.uuidCliente, 'uuid-panel-42');
      expect(trabajo.ordenMotivoRetiro, 'pausada');
      expect(trabajo.ordenPausada, isTrue);
      expect(trabajo.puedeCrearAplicacion, isTrue);
    },
  );

  test('pausada → reanudada: el stream lo refleja solo, sin otro pull del '
      'trabajo', () async {
    await marcarOrden('pausada');
    final emisiones = repositorio.trabajoAsignado().map((t) => t?.ordenPausada);
    final esperadas = expectLater(emisiones, emitsInOrder([true, false]));

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await marcarOrden(null);

    await esperadas;
  });
}
