import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/cola_sync.dart';
import 'package:agrocom_field/nucleo/sync/outbox_repository.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late OutboxRepository repositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = OutboxRepository(db);
  });

  tearDown(() => db.close());

  Future<void> encolar({
    required String uuidCliente,
    required int secuencia,
    EstadoSync estado = EstadoSync.pendiente,
  }) {
    return db
        .into(db.colaSync)
        .insert(
          ColaSyncCompanion.insert(
            uuidCliente: uuidCliente,
            tipoEntidad: 'trabajo',
            payload: '{}',
            secuencia: secuencia,
            estado: Value(estado),
          ),
        );
  }

  group('leerPendientes', () {
    test(
      'devuelve solo las filas pendiente, ordenadas por secuencia',
      () async {
        await encolar(uuidCliente: 'c', secuencia: 3);
        await encolar(uuidCliente: 'a', secuencia: 1);
        await encolar(
          uuidCliente: 'confirmada',
          secuencia: 0,
          estado: EstadoSync.confirmado,
        );
        await encolar(uuidCliente: 'b', secuencia: 2);
        await encolar(
          uuidCliente: 'rechazada',
          secuencia: -1,
          estado: EstadoSync.rechazado,
        );

        final pendientes = await repositorio.leerPendientes();

        expect(pendientes.map((f) => f.uuidCliente).toList(), ['a', 'b', 'c']);
      },
    );

    test('ignora el orden de inserción, respeta solo secuencia', () async {
      await encolar(uuidCliente: 'tercero', secuencia: 30);
      await encolar(uuidCliente: 'primero', secuencia: 10);
      await encolar(uuidCliente: 'segundo', secuencia: 20);

      final pendientes = await repositorio.leerPendientes();

      expect(pendientes.map((f) => f.secuencia).toList(), [10, 20, 30]);
    });
  });

  group('marcarConfirmado', () {
    test(
      'cambia el estado a confirmado y deja de aparecer en pendientes',
      () async {
        await encolar(uuidCliente: 'x', secuencia: 1);

        await repositorio.marcarConfirmado('x');

        final fila = await (db.select(
          db.colaSync,
        )..where((t) => t.uuidCliente.equals('x'))).getSingle();
        expect(fila.estado, EstadoSync.confirmado);
        expect(await repositorio.leerPendientes(), isEmpty);
      },
    );

    test('no reescribe una fila ya confirmado (invariante 6)', () async {
      await encolar(
        uuidCliente: 'y',
        secuencia: 1,
        estado: EstadoSync.confirmado,
      );

      await repositorio.marcarConfirmado('y');

      final fila = await (db.select(
        db.colaSync,
      )..where((t) => t.uuidCliente.equals('y'))).getSingle();
      expect(fila.estado, EstadoSync.confirmado);
    });
  });

  group('marcarRechazado', () {
    test('cambia el estado a rechazado y guarda el motivo', () async {
      await encolar(uuidCliente: 'z', secuencia: 1);

      await repositorio.marcarRechazado(
        'z',
        'el trabajo referenciado no existe',
      );

      final fila = await (db.select(
        db.colaSync,
      )..where((t) => t.uuidCliente.equals('z'))).getSingle();
      expect(fila.estado, EstadoSync.rechazado);
      expect(fila.motivoRechazo, 'el trabajo referenciado no existe');
    });

    test('no reescribe una fila ya confirmado (invariante 6)', () async {
      await encolar(
        uuidCliente: 'w',
        secuencia: 1,
        estado: EstadoSync.confirmado,
      );

      await repositorio.marcarRechazado(
        'w',
        'motivo tardío, no debería aplicar',
      );

      final fila = await (db.select(
        db.colaSync,
      )..where((t) => t.uuidCliente.equals('w'))).getSingle();
      expect(fila.estado, EstadoSync.confirmado);
      expect(fila.motivoRechazo, isNull);
    });
  });
}
