// Tarea 27: `InicioRepository.enCurso()` contra `drift` en memoria — lo que
// el dispositivo tiene en curso sale de `SesionLocal`/`TrabajoLocal`, se ve
// aunque el trabajo esté retirado o no tenga fila en el catálogo, y entre
// varios abiertos gana el más reciente por `ColaSync.secuencia`, nunca por
// reloj.

import 'package:agrocom_field/features/inicio/data/inicio_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/sesion_repository.dart';
import 'package:agrocom_field/features/sesion_vuelo/data/trabajo_repository.dart';
import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late InicioRepository repositorio;
  late TrabajoRepository trabajoRepositorio;
  late SesionRepository sesionRepositorio;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repositorio = InicioRepository(db);
    trabajoRepositorio = TrabajoRepository(db);
    sesionRepositorio = SesionRepository(db);
  });

  tearDown(() => db.close());

  Future<String> abrirTrabajoDeLaApp({required DateTime inicio}) async =>
      (await trabajoRepositorio.abrirTrabajo(
        ordenId: 1,
        loteId: 3,
        nroAplicacion: 1,
        inicio: inicio,
      )).uuidCliente;

  Future<String> abrirSesion(
    String trabajo, {
    required DateTime inicio,
  }) async => (await sesionRepositorio.abrirSesion(
    trabajoUuidCliente: trabajo,
    pilotoId: 7,
    inicio: inicio,
    vientoKmh: Decimal.parse('10'),
    temperaturaC: Decimal.parse('20'),
    humedadPct: Decimal.parse('50'),
  )).uuidCliente;

  Future<void> sembrarLote() => db
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

  test('sin nada abierto emite null', () async {
    expect(await repositorio.enCurso().first, isNull);
  });

  test('trabajo abierto por la app, sin fila en el catálogo ni sesión: '
      '«Trabajo en curso» con el inicio del trabajo', () async {
    await sembrarLote();
    final inicio = DateTime.utc(2026, 10, 1, 9);
    final trabajo = await abrirTrabajoDeLaApp(inicio: inicio);

    final enCurso = (await repositorio.enCurso().first)!;

    expect(enCurso.trabajoUuidCliente, trabajo);
    expect(enCurso.conSesion, isFalse);
    // `drift` devuelve la hora local: se compara el instante.
    expect(enCurso.inicio.isAtSameMomentAs(inicio), isTrue);
    expect(enCurso.loteCodigo, 'L-14');
    expect(enCurso.motivoRetiro, isNull);
  });

  test('sesión abierta sobre un trabajo asignado y después retirado: se '
      'muestra igual, con el motivo de retiro', () async {
    await sembrarLote();
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
    await trabajoRepositorio.abrirTrabajoAsignado(
      uuidCliente: 'uuid-panel-42',
      ordenId: 1,
      loteId: 3,
      nroAplicacion: 2,
      inicio: DateTime.utc(2026, 10, 1, 9),
    );
    final inicioSesion = DateTime.utc(2026, 10, 1, 9, 30);
    final sesion = await abrirSesion('uuid-panel-42', inicio: inicioSesion);
    await (db.update(db.trabajoCatalogo)..where((t) => t.id.equals(42))).write(
      const TrabajoCatalogoCompanion(motivoRetiro: Value('reasignado')),
    );

    final enCurso = (await repositorio.enCurso().first)!;

    expect(enCurso.trabajoUuidCliente, 'uuid-panel-42');
    expect(enCurso.sesionUuidCliente, sesion);
    expect(enCurso.inicio.isAtSameMomentAs(inicioSesion), isTrue);
    expect(enCurso.loteCodigo, 'L-14');
    expect(enCurso.motivoRetiro, 'reasignado');
  });

  test(
    'varios abiertos: la sesión abierta gana sobre un trabajo sin sesión, '
    'y entre iguales el de secuencia mayor, aunque su reloj diga antes',
    () async {
      // Relojes al revés a propósito: lo que ordena es la secuencia local.
      final primero = await abrirTrabajoDeLaApp(
        inicio: DateTime.utc(2026, 10, 1, 12),
      );
      final segundo = await abrirTrabajoDeLaApp(
        inicio: DateTime.utc(2026, 10, 1, 8),
      );
      expect((await repositorio.enCurso().first)!.trabajoUuidCliente, segundo);

      final sesionPrimero = await abrirSesion(
        primero,
        inicio: DateTime.utc(2026, 10, 1, 13),
      );
      final conSesion = (await repositorio.enCurso().first)!;
      expect(conSesion.trabajoUuidCliente, primero);
      expect(conSesion.sesionUuidCliente, sesionPrimero);

      final sesionSegundo = await abrirSesion(
        segundo,
        inicio: DateTime.utc(2026, 10, 1, 7),
      );
      expect(
        (await repositorio.enCurso().first)!.sesionUuidCliente,
        sesionSegundo,
      );
    },
  );

  test('es reactivo: al cerrar la sesión pasa a «Trabajo en curso», y al '
      'cerrar el trabajo a null', () async {
    final trabajo = await abrirTrabajoDeLaApp(
      inicio: DateTime.utc(2026, 10, 1, 9),
    );
    final sesion = await abrirSesion(
      trabajo,
      inicio: DateTime.utc(2026, 10, 1, 9, 30),
    );

    final emisiones = repositorio.enCurso().map((e) => e?.conSesion);
    final esperadas = expectLater(emisiones, emitsInOrder([true, false, null]));

    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sesionRepositorio.cerrarSesion(
      sesionUuidCliente: sesion,
      fin: DateTime.utc(2026, 10, 1, 10),
      motivoCierre: 'completado',
      hectareasDeclaradas: Decimal.parse('5'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await trabajoRepositorio.cerrarTrabajo(
      trabajoUuidCliente: trabajo,
      fin: DateTime.utc(2026, 10, 1, 11),
      evidenciaImagenCampoUuidCliente: 'evidencia-campo-1',
    );

    await esperadas;
  });
}
