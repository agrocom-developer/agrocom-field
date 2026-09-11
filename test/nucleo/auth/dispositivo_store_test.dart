// Etapa 1 de HU-03: `uuid_dispositivo` se genera una sola vez y se
// reutiliza — nunca se regenera (si se regenerara, el servidor vería cada
// reintento como un dispositivo nuevo).

import 'package:agrocom_field/nucleo/auth/dispositivo_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AlmacenamientoFalso extends Mock implements FlutterSecureStorage {}

void main() {
  late _AlmacenamientoFalso almacenamiento;
  late DispositivoStoreSeguro store;

  setUp(() {
    almacenamiento = _AlmacenamientoFalso();
    store = DispositivoStoreSeguro(almacenamiento);
  });

  test('sin uuid guardado, genera uno nuevo (v4) y lo persiste', () async {
    when(
      () => almacenamiento.read(key: 'uuid_dispositivo'),
    ).thenAnswer((_) async => null);
    when(
      () => almacenamiento.write(
        key: 'uuid_dispositivo',
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    final uuid = await store.obtenerUuidDispositivo();

    expect(
      uuid,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    verify(
      () => almacenamiento.write(key: 'uuid_dispositivo', value: uuid),
    ).called(1);
  });

  test(
    'con uuid ya guardado, lo devuelve tal cual sin volver a escribir',
    () async {
      when(
        () => almacenamiento.read(key: 'uuid_dispositivo'),
      ).thenAnswer((_) async => 'uuid-existente');

      final uuid = await store.obtenerUuidDispositivo();

      expect(uuid, 'uuid-existente');
      verifyNever(
        () => almacenamiento.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    },
  );

  test(
    'dos llamadas consecutivas sin uuid previo devuelven el mismo uuid (no se regenera)',
    () async {
      String? guardado;
      when(
        () => almacenamiento.read(key: 'uuid_dispositivo'),
      ).thenAnswer((_) async => guardado);
      when(
        () => almacenamiento.write(
          key: 'uuid_dispositivo',
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocacion) async {
        guardado = invocacion.namedArguments[#value] as String;
      });

      final primero = await store.obtenerUuidDispositivo();
      final segundo = await store.obtenerUuidDispositivo();

      expect(segundo, primero);
    },
  );
}
