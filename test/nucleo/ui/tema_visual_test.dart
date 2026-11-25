import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_visual/tema_visual_cubit.dart';

class _AlmacenQueFalla implements AlmacenTemaVisual {
  @override
  Future<ModoVisualCampo?> leer() async => throw StateError('sin disco');

  @override
  Future<void> guardar(ModoVisualCampo modo) async =>
      throw StateError('sin disco');
}

void main() {
  test('sin elección el cubit queda en null y carga lo guardado', () async {
    final almacen = AlmacenTemaVisualMemoria(ModoVisualCampo.oscuro);
    final cubit = TemaVisualCubit(almacen);
    expect(cubit.state, isNull);
    await cubit.cargar();
    expect(cubit.state, ModoVisualCampo.oscuro);
    await cubit.close();
  });

  test('elegir cambia el tema y lo guarda', () async {
    final almacen = AlmacenTemaVisualMemoria();
    final cubit = TemaVisualCubit(almacen);
    await cubit.elegir(ModoVisualCampo.campo);
    expect(cubit.state, ModoVisualCampo.campo);
    expect(almacen.modo, ModoVisualCampo.campo);
    await cubit.close();
  });

  test('un almacén roto no impide cambiar el tema', () async {
    final cubit = TemaVisualCubit(_AlmacenQueFalla());
    await cubit.cargar();
    expect(cubit.state, isNull);
    await cubit.elegir(ModoVisualCampo.claro);
    expect(cubit.state, ModoVisualCampo.claro);
    await cubit.close();
  });

  test('el cliente sin elección sigue al sistema; el piloto usa campo', () {
    final cliente = ConfiguracionTema.de(
      elegido: null,
      predeterminado: ModoVisualCampo.claro,
    );
    expect(cliente.modo, ThemeMode.system);
    expect(cliente.claro.brightness, Brightness.light);
    expect(cliente.oscuro.brightness, Brightness.dark);

    final piloto = ConfiguracionTema.de(
      elegido: null,
      predeterminado: ModoVisualCampo.campo,
    );
    expect(piloto.modo, ThemeMode.light);
    expect(piloto.claro, same(piloto.oscuro));
  });

  test('una elección fija el tema aunque el sistema sea otro', () {
    final t = ConfiguracionTema.de(
      elegido: ModoVisualCampo.oscuro,
      predeterminado: ModoVisualCampo.claro,
    );
    expect(t.modo, ThemeMode.light);
    expect(t.claro.brightness, Brightness.dark);
  });
}
