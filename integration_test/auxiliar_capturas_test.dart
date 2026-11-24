import 'package:agrocom_field/auxiliar/app_auxiliar_demo.dart';
import 'package:agrocom_field/auxiliar/di/dependencias_auxiliar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_capturas.dart';

void main() {
  binding;
  testWidgets('auxiliar: recorrido de capturas', (t) async {
    await t.pumpWidget(
      AppAuxiliarDemo(dependencias: DependenciasAuxiliar.demo()),
    );
    await captura(t, 'auxiliar_01_servicio');
    await paso('servicio abajo', () async {
      await bajar(t, 600);
      await captura(t, 'auxiliar_02_servicio_abajo');
    });
    await paso('mezcla', () async {
      await tocar(t, find.text('Mezcla').last);
      await captura(t, 'auxiliar_03_mezcla');
      await bajar(t, 500);
      await captura(t, 'auxiliar_04_mezcla_abajo');
    });
    await paso('nueva carga', () async {
      final f = find.byIcon(Icons.add_rounded);
      if (f.evaluate().isNotEmpty) {
        await tocar(t, f);
        await captura(t, 'auxiliar_05_nueva_carga');
        await atras(t);
      }
    });
    await paso('ofertas', () async {
      await tocar(t, find.text('Ofertas').last);
      await captura(t, 'auxiliar_06_ofertas');
      await tocar(t, porPrefijo('oferta-'));
      await captura(t, 'auxiliar_07_oferta_detalle');
      await bajar(t, 500);
      await captura(t, 'auxiliar_08_oferta_detalle_abajo');
      await atras(t);
    });
    await paso('perfil', () async {
      await tocar(t, find.text('Perfil').last);
      await captura(t, 'auxiliar_09_perfil');
      await bajar(t, 600);
      await captura(t, 'auxiliar_10_perfil_abajo');
      await bajar(t, -600);
      await tocar(t, find.byKey(const Key('perfil-ver-drones')));
      await captura(t, 'auxiliar_11_drones');
    });
  });
}
