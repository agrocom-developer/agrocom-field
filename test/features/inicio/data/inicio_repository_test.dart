// HU-70: `InicioRepository` contra `drift` en memoria — la regla de «el
// trabajo asignado» (más reciente por `updated_at`, sin los cerrados en
// este dispositivo), el join con orden/lote y la reactividad del `Stream`.

import 'package:agrocom_field/features/inicio/data/inicio_repository.dart';
import 'package:agrocom_field/features/inicio/domain/trabajo_asignado.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/trabajo_local.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

TrabajoCatalogoCompanion _trabajo({
  required int id,
  String? uuidCliente,
  int ordenId = 1,
  int loteId = 3,
  String hectareas = '300.00',
  DateTime? updatedAt,
}) => TrabajoCatalogoCompanion.insert(
  id: Value(id),
  uuidCliente: uuidCliente ?? 'uuid-panel-$id',
  ordenId: ordenId,
  loteId: loteId,
  hectareasDeclaradas: Decimal.parse(hectareas),
  equipoTrabajoId: 7,
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 22, 12),
);

void main() {
  late AppDatabase db;
  late InicioRepository repositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = InicioRepository(db);
  });

  tearDown(() => db.close());

  test('sin trabajos asignados emite null (estado vacío)', () async {
    expect(await repositorio.trabajoAsignado().first, isNull);
  });

  test('resuelve lote, orden y dosis por join local', () async {
    await db
        .into(db.ordenCatalogo)
        .insert(
          OrdenCatalogoCompanion.insert(
            id: const Value(1),
            contratoId: 1,
            loteId: 3,
            cantidadLotes: const Value(2),
            nroAplicacion: 4,
            kilosPorVuelo: Value(Decimal.parse('8.50')),
            fechaEmision: '2026-09-20',
            estado: 'vigente',
            updatedAt: DateTime.utc(2026, 9, 20),
          ),
        );
    await db
        .into(db.loteCatalogo)
        .insert(
          LoteCatalogoCompanion.insert(
            id: const Value(3),
            propiedadId: 1,
            codigo: 'L-14',
            hectareas: Decimal.parse('120.50'),
            updatedAt: DateTime.utc(2026, 9, 20),
          ),
        );
    await db.into(db.trabajoCatalogo).insert(_trabajo(id: 42));

    final trabajo = (await repositorio.trabajoAsignado().first)!;

    expect(trabajo.uuidCliente, 'uuid-panel-42');
    expect(trabajo.hectareasDeclaradas, Decimal.parse('300.00'));
    expect(trabajo.loteCodigo, 'L-14');
    expect(trabajo.nroAplicacion, 4);
    expect(trabajo.litrosHa, isNull);
    expect(trabajo.kilosPorVuelo, Decimal.parse('8.50'));
    expect(trabajo.cantidadLotesOrden, 2);
  });

  test('sin orden ni lote todavía, el trabajo aparece igual con esos datos '
      'en null', () async {
    await db.into(db.trabajoCatalogo).insert(_trabajo(id: 42));

    final trabajo = (await repositorio.trabajoAsignado().first)!;

    expect(trabajo.loteCodigo, isNull);
    expect(trabajo.nroAplicacion, isNull);
    expect(trabajo.dosis, isNull);
    expect(trabajo.puedeCrearAplicacion, isFalse);
  });

  test('con varios, elige el más reciente por updated_at y, a igual '
      'updated_at, el de id mayor', () async {
    await db
        .into(db.trabajoCatalogo)
        .insert(_trabajo(id: 50, updatedAt: DateTime.utc(2026, 9, 21)));
    await db
        .into(db.trabajoCatalogo)
        .insert(_trabajo(id: 42, updatedAt: DateTime.utc(2026, 9, 23)));
    await db
        .into(db.trabajoCatalogo)
        .insert(_trabajo(id: 43, updatedAt: DateTime.utc(2026, 9, 23)));

    expect((await repositorio.trabajoAsignado().first)!.id, 43);
  });

  test('un trabajo que este dispositivo ya cerró deja de ser el asignado; '
      'uno abierto localmente sigue siéndolo', () async {
    await db
        .into(db.trabajoCatalogo)
        .insert(_trabajo(id: 42, updatedAt: DateTime.utc(2026, 9, 23)));
    await db
        .into(db.trabajoCatalogo)
        .insert(_trabajo(id: 41, updatedAt: DateTime.utc(2026, 9, 22)));
    await db
        .into(db.trabajoLocal)
        .insert(
          TrabajoLocalCompanion.insert(
            uuidCliente: 'uuid-panel-42',
            ordenId: 1,
            loteId: 3,
            nroAplicacion: 1,
            inicio: DateTime.utc(2026, 9, 23, 8),
            estado: const Value(EstadoTrabajoLocal.cerrado),
          ),
        );
    await db
        .into(db.trabajoLocal)
        .insert(
          TrabajoLocalCompanion.insert(
            uuidCliente: 'uuid-panel-41',
            ordenId: 1,
            loteId: 3,
            nroAplicacion: 1,
            inicio: DateTime.utc(2026, 9, 22, 8),
          ),
        );

    expect((await repositorio.trabajoAsignado().first)!.id, 41);
  });

  test('el stream reacciona a un pull posterior a la suscripción', () async {
    final emisiones = <TrabajoAsignado?>[];
    final suscripcion = repositorio.trabajoAsignado().listen(emisiones.add);
    addTearDown(suscripcion.cancel);

    await pumpEventQueue();
    await db.into(db.trabajoCatalogo).insert(_trabajo(id: 42));
    await pumpEventQueue();

    expect(emisiones.first, isNull);
    expect(emisiones.last?.id, 42);
  });

  test('tarea 23: los límites salen de la fila del propio trabajo, no de la '
      'orden', () async {
    await db
        .into(db.ordenCatalogo)
        .insert(
          OrdenCatalogoCompanion.insert(
            id: const Value(1),
            contratoId: 1,
            loteId: 3,
            nroAplicacion: 4,
            vientoMaxKmh: Value(Decimal.parse('99.00')),
            fechaEmision: '2026-09-20',
            estado: 'vigente',
            updatedAt: DateTime.utc(2026, 9, 20),
          ),
        );
    await db
        .into(db.trabajoCatalogo)
        .insert(
          _trabajo(id: 42).copyWith(
            humedadMinPct: Value(Decimal.parse('60.00')),
            vientoMaxKmh: Value(Decimal.parse('15.00')),
            temperaturaMaxC: Value(Decimal.parse('32.00')),
            humedadMaxPct: Value(Decimal.parse('90.00')),
            alturaVueloM: Value(Decimal.parse('3.00')),
            velocidadVueloKmh: Value(Decimal.parse('18.00')),
            anchoPasadaM: Value(Decimal.parse('7.00')),
          ),
        );

    final trabajo = (await repositorio.trabajoAsignado().first)!;

    expect(trabajo.humedadMinPct, Decimal.parse('60.00'));
    expect(trabajo.vientoMaxKmh, Decimal.parse('15.00'));
    expect(trabajo.temperaturaMaxC, Decimal.parse('32.00'));
    expect(trabajo.humedadMaxPct, Decimal.parse('90.00'));
    expect(trabajo.alturaVueloM, Decimal.parse('3.00'));
    expect(trabajo.velocidadVueloKmh, Decimal.parse('18.00'));
    expect(trabajo.anchoPasadaM, Decimal.parse('7.00'));
  });

  test('tarea 23: trabajo sin límites completados (o bajado antes de v12): '
      'null, aunque la orden traiga valores viejos', () async {
    await db
        .into(db.ordenCatalogo)
        .insert(
          OrdenCatalogoCompanion.insert(
            id: const Value(1),
            contratoId: 1,
            loteId: 3,
            nroAplicacion: 4,
            vientoMaxKmh: Value(Decimal.parse('99.00')),
            fechaEmision: '2026-09-20',
            estado: 'vigente',
            updatedAt: DateTime.utc(2026, 9, 20),
          ),
        );
    await db.into(db.trabajoCatalogo).insert(_trabajo(id: 42));

    final trabajo = (await repositorio.trabajoAsignado().first)!;

    expect(trabajo.humedadMinPct, isNull);
    expect(trabajo.vientoMaxKmh, isNull);
    expect(trabajo.temperaturaMaxC, isNull);
    expect(trabajo.humedadMaxPct, isNull);
    expect(trabajo.alturaVueloM, isNull);
    expect(trabajo.velocidadVueloKmh, isNull);
    expect(trabajo.anchoPasadaM, isNull);
  });
}
