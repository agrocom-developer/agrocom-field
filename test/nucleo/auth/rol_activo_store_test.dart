// Etapa 1 de HU-69 (ADR 0005): el rol activo se persiste con el mismo
// mecanismo que `DispositivoStore`/`PersonaOperativaStore`, serializado
// como JSON en una sola clave — acá solo se cubre el store en sí
// (leer/guardar/borrar).

import 'package:agrocom_field/nucleo/auth/rol_activo.dart';
import 'package:agrocom_field/nucleo/auth/rol_activo_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AlmacenamientoFalso extends Mock implements FlutterSecureStorage {}

void main() {
  late _AlmacenamientoFalso almacenamiento;
  late RolActivoStoreSeguro store;

  setUp(() {
    almacenamiento = _AlmacenamientoFalso();
    store = RolActivoStoreSeguro(almacenamiento);
  });

  test('sin valor guardado, leerRolActivo devuelve null', () async {
    when(
      () => almacenamiento.read(key: 'rol_activo'),
    ).thenAnswer((_) async => null);

    expect(await store.leerRolActivo(), isNull);
  });

  test('con valor guardado, leerRolActivo lo decodifica', () async {
    when(() => almacenamiento.read(key: 'rol_activo')).thenAnswer(
      (_) async => '{"id":1,"name":"piloto","description":"Piloto de dron"}',
    );

    expect(
      await store.leerRolActivo(),
      const RolActivo(id: 1, name: 'piloto', description: 'Piloto de dron'),
    );
  });

  test('guardarRolActivo lo escribe como JSON', () async {
    when(
      () => almacenamiento.write(
        key: 'rol_activo',
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    await store.guardarRolActivo(
      const RolActivo(id: 2, name: 'auxiliar', description: null),
    );

    verify(
      () => almacenamiento.write(
        key: 'rol_activo',
        value: '{"id":2,"name":"auxiliar","description":null}',
      ),
    ).called(1);
  });

  test('borrarRolActivo elimina la clave', () async {
    when(
      () => almacenamiento.delete(key: 'rol_activo'),
    ).thenAnswer((_) async {});

    await store.borrarRolActivo();

    verify(() => almacenamiento.delete(key: 'rol_activo')).called(1);
  });
}
