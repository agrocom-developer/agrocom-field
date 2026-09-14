import 'dart:io';
import 'dart:typed_data';

import 'package:agrocom_field/nucleo/db/database.dart';
import 'package:agrocom_field/nucleo/db/tablas/evidencia_local.dart';
import 'package:agrocom_field/nucleo/evidencias/compresor_evidencia.dart';
import 'package:agrocom_field/nucleo/evidencias/evidencia_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CompresorFalso extends Mock implements CompresorEvidencia {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  late AppDatabase db;
  late Directory directorioTemporal;
  late _CompresorFalso compresor;
  late EvidenciaRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    directorioTemporal = Directory.systemTemp.createTempSync(
      'evidencias_test_',
    );
    compresor = _CompresorFalso();
    repository = EvidenciaRepository(
      db,
      compresor: compresor,
      directorioEvidencias: directorioTemporal,
    );
  });

  tearDown(() async {
    await db.close();
    if (directorioTemporal.existsSync()) {
      directorioTemporal.deleteSync(recursive: true);
    }
  });

  test(
    'comprime, hashea, persiste el archivo y encola la fila pendiente',
    () async {
      final original = Uint8List.fromList(List.filled(20, 5));
      final comprimido = Uint8List.fromList([1, 2, 3, 4]);
      when(
        () => compresor.comprimir(original),
      ).thenAnswer((_) async => comprimido);

      final uuidCliente = await repository.capturarEvidencia(
        bytesOriginales: original,
        tipo: 'foto_incidencia',
        fecha: DateTime.utc(2026, 9, 11, 12),
      );

      final fila = await (db.select(
        db.evidenciaLocal,
      )..where((t) => t.uuidCliente.equals(uuidCliente))).getSingle();

      expect(fila.tipo, 'foto_incidencia');
      expect(fila.estado, EstadoEvidenciaLocal.pendiente);
      expect(fila.motivoRechazo, isNull);
      // `drift` devuelve la hora local reconstruida desde el epoch guardado
      // — mismo instante, `isUtc` distinto — así que se normaliza a UTC
      // antes de comparar (Dart considera `isUtc` en `DateTime.==`).
      expect(fila.fecha.toUtc(), DateTime.utc(2026, 9, 11, 12));

      // El hash se calcula sobre los bytes COMPRIMIDOS, no los originales.
      final archivo = File(fila.rutaArchivoLocal);
      expect(archivo.existsSync(), isTrue);
      expect(archivo.readAsBytesSync(), comprimido);

      final hashEsperado =
          '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a';
      expect(fila.hashSha256, hashEsperado);
    },
  );

  test(
    'dos capturas sucesivas generan uuid_cliente y archivos distintos',
    () async {
      when(
        () => compresor.comprimir(any()),
      ).thenAnswer((_) async => Uint8List.fromList([1]));

      final primero = await repository.capturarEvidencia(
        bytesOriginales: Uint8List.fromList([1]),
        tipo: 'captura_rc',
        fecha: DateTime.utc(2026, 9, 11),
      );
      final segundo = await repository.capturarEvidencia(
        bytesOriginales: Uint8List.fromList([2]),
        tipo: 'captura_rc',
        fecha: DateTime.utc(2026, 9, 11),
      );

      expect(primero, isNot(segundo));
      final filas = await db.select(db.evidenciaLocal).get();
      expect(filas, hasLength(2));
      expect(filas.map((f) => f.rutaArchivoLocal).toSet(), hasLength(2));
    },
  );

  test('crea el directorio de evidencias si todavía no existe', () async {
    final subdirectorioInexistente = Directory(
      '${directorioTemporal.path}/aun-no-existe',
    );
    repository = EvidenciaRepository(
      db,
      compresor: compresor,
      directorioEvidencias: subdirectorioInexistente,
    );
    when(
      () => compresor.comprimir(any()),
    ).thenAnswer((_) async => Uint8List.fromList([9, 9]));

    await repository.capturarEvidencia(
      bytesOriginales: Uint8List.fromList([1, 2, 3]),
      tipo: 'imagen_campo',
      fecha: DateTime.utc(2026, 9, 11),
    );

    expect(subdirectorioInexistente.existsSync(), isTrue);
    expect(subdirectorioInexistente.listSync(), hasLength(1));
  });
}
