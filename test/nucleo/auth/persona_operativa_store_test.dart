// Etapa 1 de HU-05: `persona_id` de `UsuarioCampo` se persiste con el mismo
// mecanismo que `DispositivoStore`/`TokenStore` — acá solo se cubre el
// store en sí (leer/guardar/borrar, incluyendo el caso nulo).

import 'package:agrocom_field/nucleo/auth/persona_operativa_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AlmacenamientoFalso extends Mock implements FlutterSecureStorage {}

void main() {
  late _AlmacenamientoFalso almacenamiento;
  late PersonaOperativaStoreSeguro store;

  setUp(() {
    almacenamiento = _AlmacenamientoFalso();
    store = PersonaOperativaStoreSeguro(almacenamiento);
  });

  test('sin valor guardado, leerPersonaId devuelve null', () async {
    when(
      () => almacenamiento.read(key: 'persona_id_operativa'),
    ).thenAnswer((_) async => null);

    expect(await store.leerPersonaId(), isNull);
  });

  test('con valor guardado, leerPersonaId lo parsea a int', () async {
    when(
      () => almacenamiento.read(key: 'persona_id_operativa'),
    ).thenAnswer((_) async => '3');

    expect(await store.leerPersonaId(), 3);
  });

  test('guardarPersonaId con un id escribe el valor como string', () async {
    when(
      () => almacenamiento.write(
        key: 'persona_id_operativa',
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    await store.guardarPersonaId(3);

    verify(
      () => almacenamiento.write(key: 'persona_id_operativa', value: '3'),
    ).called(1);
  });

  test(
    'guardarPersonaId con null borra la clave en vez de escribir "null"',
    () async {
      when(
        () => almacenamiento.delete(key: 'persona_id_operativa'),
      ).thenAnswer((_) async {});

      await store.guardarPersonaId(null);

      verify(
        () => almacenamiento.delete(key: 'persona_id_operativa'),
      ).called(1);
      verifyNever(
        () => almacenamiento.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    },
  );

  test('borrarPersonaId elimina la clave', () async {
    when(
      () => almacenamiento.delete(key: 'persona_id_operativa'),
    ).thenAnswer((_) async {});

    await store.borrarPersonaId();

    verify(() => almacenamiento.delete(key: 'persona_id_operativa')).called(1);
  });
}
