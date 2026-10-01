// Etapa 1 de HU-04: `OrdenesRepository` contra una base `drift` en memoria
// (mismo patrón que `test/nucleo/catalogo/catalogo_repository_test.dart`) —
// join reactivo con lote presente/ausente, filtro de `estado` y
// reactividad del `Stream` ante una escritura posterior a la suscripción.

import 'package:agrocom_field/features/ordenes/data/ordenes_repository.dart';
import 'package:agrocom_field/features/ordenes/domain/orden_vigente.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/trabajo_local.dart';
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

/// Trabajo asignado desde el panel con los siete límites climáticos y de
/// vuelo en el mismo [valor] (tarea 23), o todos en `null`.
TrabajoCatalogoCompanion _trabajoCompanion({
  required int id,
  int ordenId = 1,
  String? valor = '15.00',
  DateTime? updatedAt,
}) {
  final limite = Value(valor == null ? null : Decimal.parse(valor));
  return TrabajoCatalogoCompanion.insert(
    id: Value(id),
    uuidCliente: 'uuid-panel-$id',
    ordenId: ordenId,
    loteId: 3,
    hectareasDeclaradas: Decimal.parse('300.00'),
    equipoTrabajoId: 7,
    humedadMinPct: limite,
    vientoMaxKmh: limite,
    temperaturaMaxC: limite,
    humedadMaxPct: limite,
    alturaVueloM: limite,
    velocidadVueloKmh: limite,
    anchoPasadaM: limite,
    updatedAt: updatedAt ?? DateTime.utc(2026, 9, 22, 12),
  );
}

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

  test('TE-23: expone cantidad de lotes y hectáreas solicitadas de la orden '
      'junto a las del lote', () async {
    await db.into(db.loteCatalogo).insert(_loteCompanion());
    await db
        .into(db.ordenCatalogo)
        .insert(
          _ordenCompanion().copyWith(
            cantidadLotes: const Value(2),
            hectareasSolicitadas: Value(Decimal.parse('170.50')),
          ),
        );

    final orden = (await repositorio.ordenesVigentes().first).single;

    expect(orden.cantidadLotes, 2);
    expect(orden.hectareasSolicitadas, Decimal.parse('170.50'));
    expect(orden.loteHectareas, Decimal.parse('120.50'));
    expect(orden.hectareasOrden, Decimal.parse('170.50'));
  });

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

  group('tarea 23: límites climáticos y de vuelo del trabajo asignado', () {
    void esperarLimites(OrdenVigente orden, Decimal? valor) {
      expect(orden.humedadMinPct, valor);
      expect(orden.vientoMaxKmh, valor);
      expect(orden.temperaturaMaxC, valor);
      expect(orden.humedadMaxPct, valor);
      expect(orden.alturaVueloM, valor);
      expect(orden.velocidadVueloKmh, valor);
      expect(orden.anchoPasadaM, valor);
    }

    test('con trabajo asignado, la orden expone los límites del trabajo y '
        'no los de orden_catalogo', () async {
      await db
          .into(db.ordenCatalogo)
          .insert(
            _ordenCompanion().copyWith(
              vientoMaxKmh: Value(Decimal.parse('99.00')),
            ),
          );
      await db.into(db.trabajoCatalogo).insert(_trabajoCompanion(id: 42));

      final orden = (await repositorio.ordenesVigentes().first).single;

      esperarLimites(orden, Decimal.parse('15.00'));
    });

    test('sin trabajo asignado, los límites quedan en null aunque '
        'orden_catalogo traiga valores viejos', () async {
      await db
          .into(db.ordenCatalogo)
          .insert(
            _ordenCompanion().copyWith(
              vientoMaxKmh: Value(Decimal.parse('99.00')),
              anchoPasadaM: Value(Decimal.parse('7.00')),
            ),
          );

      final orden = (await repositorio.ordenesVigentes().first).single;

      esperarLimites(orden, null);
    });

    test('nunca toma los límites del trabajo de otra orden', () async {
      await db.into(db.ordenCatalogo).insert(_ordenCompanion(id: 1));
      await db.into(db.ordenCatalogo).insert(_ordenCompanion(id: 2));
      await db
          .into(db.trabajoCatalogo)
          .insert(_trabajoCompanion(id: 42, ordenId: 2));

      final ordenes = await repositorio.ordenesVigentes().first;

      expect(ordenes, hasLength(2));
      esperarLimites(ordenes.singleWhere((o) => o.id == 1), null);
      esperarLimites(
        ordenes.singleWhere((o) => o.id == 2),
        Decimal.parse('15.00'),
      );
    });

    test('trabajo asignado con los límites sin completar: null, sin '
        'inventar', () async {
      await db.into(db.ordenCatalogo).insert(_ordenCompanion());
      await db
          .into(db.trabajoCatalogo)
          .insert(_trabajoCompanion(id: 42, valor: null));

      final orden = (await repositorio.ordenesVigentes().first).single;

      esperarLimites(orden, null);
    });

    test('con varios trabajos, usa el más reciente por updated_at y una sola '
        'fila por orden', () async {
      await db.into(db.ordenCatalogo).insert(_ordenCompanion());
      await db
          .into(db.trabajoCatalogo)
          .insert(
            _trabajoCompanion(
              id: 43,
              valor: '10.00',
              updatedAt: DateTime.utc(2026, 9, 21, 12),
            ),
          );
      await db
          .into(db.trabajoCatalogo)
          .insert(
            _trabajoCompanion(
              id: 42,
              valor: '20.00',
              updatedAt: DateTime.utc(2026, 9, 23, 12),
            ),
          );

      final ordenes = await repositorio.ordenesVigentes().first;

      expect(ordenes, hasLength(1));
      esperarLimites(ordenes.single, Decimal.parse('20.00'));
    });

    test('ignora el trabajo que este dispositivo ya cerró, como «Inicio»; si '
        'no queda otro, null', () async {
      await db.into(db.ordenCatalogo).insert(_ordenCompanion());
      await db
          .into(db.trabajoCatalogo)
          .insert(
            _trabajoCompanion(
              id: 42,
              valor: '20.00',
              updatedAt: DateTime.utc(2026, 9, 23, 12),
            ),
          );
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

      esperarLimites((await repositorio.ordenesVigentes().first).single, null);

      await db
          .into(db.trabajoCatalogo)
          .insert(
            _trabajoCompanion(
              id: 41,
              valor: '10.00',
              updatedAt: DateTime.utc(2026, 9, 21, 12),
            ),
          );

      esperarLimites(
        (await repositorio.ordenesVigentes().first).single,
        Decimal.parse('10.00'),
      );
    });

    test('reactividad: un trabajo que llega después de suscribirse completa '
        'los límites por el stream', () async {
      await db.into(db.ordenCatalogo).insert(_ordenCompanion());
      final emitidas = <List<OrdenVigente>>[];
      final suscripcion = repositorio.ordenesVigentes().listen(emitidas.add);

      await _esperarHasta(
        () => emitidas.isNotEmpty,
        mensajeTimeout: 'nunca llegó la primera emisión',
      );
      esperarLimites(emitidas.single.single, null);

      await db.into(db.trabajoCatalogo).insert(_trabajoCompanion(id: 42));

      await _esperarHasta(
        () => emitidas.length >= 2,
        mensajeTimeout: 'el stream no reaccionó al trabajo nuevo',
      );
      esperarLimites(emitidas.last.single, Decimal.parse('15.00'));

      await suscripcion.cancel();
    });
  });
}
