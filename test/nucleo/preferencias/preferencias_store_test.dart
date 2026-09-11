// TE-16 (plan de sprints, Sprint 15): store de preferencias de UI, sin
// pantalla propia todavía (HU-59 sigue bloqueada). Se cubre solo el store:
// valores por defecto, guardar/releer, persistencia entre reinicios
// simulados y el borrado de `idioma` al guardar `null`.

import 'package:agrocom_field/nucleo/flavor.dart';
import 'package:agrocom_field/nucleo/preferencias/preferencias_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sin nada guardado, devuelve los valores por defecto', () async {
    final store = PreferenciasStoreLocal();

    expect(await store.leerTema(), ThemeMode.system);
    expect(await store.leerIdioma(), isNull);
    expect(await store.leerUltimoFlavor(), isNull);
  });

  test('guardar y releer cada preferencia devuelve el mismo valor', () async {
    final store = PreferenciasStoreLocal();

    await store.guardarTema(ThemeMode.dark);
    await store.guardarIdioma('pt');
    await store.guardarUltimoFlavor(Flavor.piloto);

    expect(await store.leerTema(), ThemeMode.dark);
    expect(await store.leerIdioma(), 'pt');
    expect(await store.leerUltimoFlavor(), Flavor.piloto);
  });

  test('persiste entre reinicios (nueva instancia del store)', () async {
    final storeAntes = PreferenciasStoreLocal();
    await storeAntes.guardarTema(ThemeMode.light);
    await storeAntes.guardarIdioma('es');
    await storeAntes.guardarUltimoFlavor(Flavor.auxiliar);

    final storeDespues = PreferenciasStoreLocal();

    expect(await storeDespues.leerTema(), ThemeMode.light);
    expect(await storeDespues.leerIdioma(), 'es');
    expect(await storeDespues.leerUltimoFlavor(), Flavor.auxiliar);
  });

  test('guardar idioma null borra una preferencia ya guardada', () async {
    final store = PreferenciasStoreLocal();
    await store.guardarIdioma('es');
    expect(await store.leerIdioma(), 'es');

    await store.guardarIdioma(null);

    expect(await store.leerIdioma(), isNull);
  });
}
