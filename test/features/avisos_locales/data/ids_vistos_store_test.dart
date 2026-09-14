// Etapa 2 de HU-62: mismo patrón que
// test/nucleo/preferencias/preferencias_store_test.dart — valores por
// defecto, guardar/releer y persistencia entre reinicios simulados.

import 'package:agrocom_field/features/avisos_locales/data/ids_vistos_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sin nada guardado, devuelve un conjunto vacío', () async {
    final store = IdsVistosStoreLocal();

    expect(await store.leerVistos(), isEmpty);
  });

  test('guardar y releer devuelve el mismo conjunto', () async {
    final store = IdsVistosStoreLocal();

    await store.guardarVistos({1, 2, 3});

    expect(await store.leerVistos(), {1, 2, 3});
  });

  test('persiste entre reinicios (nueva instancia del store)', () async {
    final storeAntes = IdsVistosStoreLocal();
    await storeAntes.guardarVistos({7, 8});

    final storeDespues = IdsVistosStoreLocal();

    expect(await storeDespues.leerVistos(), {7, 8});
  });

  test('guardar un conjunto nuevo reemplaza el anterior', () async {
    final store = IdsVistosStoreLocal();
    await store.guardarVistos({1, 2});

    await store.guardarVistos({1, 2, 3});

    expect(await store.leerVistos(), {1, 2, 3});
  });
}
