// Etapa 1 de HU-04: `OrdenesRepository` contra una base `drift` en memoria
// (mismo patrón que `test/nucleo/catalogo/catalogo_repository_test.dart`) —
// join reactivo con lote presente/ausente, filtro de `estado` y
// reactividad del `Stream` ante una escritura posterior a la suscripción.

import 'package:agrocom_field/features/ordenes/data/ordenes_repository.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

OrdenCatalogoCompanion _ordenCompanion({
  int id = 1,
  int loteId = 3,
  String estado = 'vigente',
  String fechaEmision = '2026-08-26',
}) => OrdenCatalogoCompanion.insert(
  id: Value(id),
  contratoId: 1,
  loteId: loteId,
  nroAplicacion: 1,
  litrosHa: Value(Decimal.parse('10.00')),
  fechaEmision: fechaEmision,
  estado: estado,
  updatedAt: DateTime.utc(2026, 8, 26, 12),
);

LoteCatalogoCompanion _loteCompanion({
  int id = 3,
  String codigo = 'L-01',
  String hectareas = '120.50',
}) => LoteCatalogoCompanion.insert(
  id: Value(id),
  propiedadId: 1,
  codigo: codigo,
  hectareas: Decimal.parse(hectareas),
  updatedAt: DateTime.utc(2026, 8, 26, 12),
);

/// Espera activa acotada — evita el flaqueo de un delay fijo sin acoplarse
/// al mecanismo interno de `drift` para reencolar una query tras un write.
Future<void> _esperarHasta(
  bool Function() condicion, {
  String? mensajeTimeout,
}) async {
  final limite = DateTime.now().add(const Duration(seconds: 2));
  while (!condicion()) {
    if (DateTime.now().isAfter(limite)) {
      fail(mensajeTimeout ?? 'tiempo de espera agotado');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late AppDatabase db;
  late OrdenesRepository repositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = OrdenesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('sin ordenes cargadas, el stream emite una lista vacia', () async {
    final ordenes = await repositorio.ordenesVigentes().first;
    expect(ordenes, isEmpty);
  });

  test('orden con lote ya sincronizado incluye codigo y hectareas', () async {
    await db.into(db.loteCatalogo).insert(_loteCompanion());
    await db.into(db.ordenCatalogo).insert(_ordenCompanion());

    final ordenes = await repositorio.ordenesVigentes().first;

    expect(ordenes, hasLength(1));
    expect(ordenes.single.loteCodigo, 'L-01');
    expect(ordenes.single.loteHectareas, Decimal.parse('120.50'));
  });

  test(
    'orden cuyo lote todavia no llego deja los campos de lote en null',
    () async {
      await db.into(db.ordenCatalogo).insert(_ordenCompanion(loteId: 99));

      final ordenes = await repositorio.ordenesVigentes().first;

      expect(ordenes, hasLength(1));
      expect(ordenes.single.loteCodigo, isNull);
      expect(ordenes.single.loteHectareas, isNull);
    },
  );

  test('filtra las ordenes que no estan vigentes', () async {
    await db
        .into(db.ordenCatalogo)
        .insert(_ordenCompanion(id: 1, estado: 'vigente'));
    await db
        .into(db.ordenCatalogo)
        .insert(_ordenCompanion(id: 2, estado: 'ejecutada'));

    final ordenes = await repositorio.ordenesVigentes().first;

    expect(ordenes.map((o) => o.id), [1]);
  });

  test('ordena por fecha de emision descendente', () async {
    await db
        .into(db.ordenCatalogo)
        .insert(_ordenCompanion(id: 1, fechaEmision: '2026-08-01'));
    await db
        .into(db.ordenCatalogo)
        .insert(_ordenCompanion(id: 2, fechaEmision: '2026-08-20'));
    await db
        .into(db.ordenCatalogo)
        .insert(_ordenCompanion(id: 3, fechaEmision: '2026-08-10'));

    final ordenes = await repositorio.ordenesVigentes().first;

    expect(ordenes.map((o) => o.id).toList(), [2, 3, 1]);
  });

  test(
    'reactividad: una fila insertada despues de suscribirse llega por el stream',
    () async {
      final emitidas = <List<OrdenVigente>>[];
      final suscripcion = repositorio.ordenesVigentes().listen(emitidas.add);

      await _esperarHasta(
        () => emitidas.isNotEmpty,
        mensajeTimeout: 'nunca llegó la primera emisión (lista vacía)',
      );
      expect(emitidas.single, isEmpty);

      await db.into(db.ordenCatalogo).insert(_ordenCompanion());

      await _esperarHasta(
        () => emitidas.length >= 2,
        mensajeTimeout: 'el stream no reaccionó al insert',
      );
      expect(emitidas[1], hasLength(1));

      await suscripcion.cancel();
    },
  );
}
