import 'package:agrocom_field/auxiliar/app_auxiliar_demo.dart';
import 'package:agrocom_field/auxiliar/di/dependencias_auxiliar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_capturas.dart';

/// Capturas del flavor auxiliar con datos ficticios: el servicio adjudicado
/// de su equipo y el perfil. Se ejecutan con `tool/capturar_pantallas.sh`.
void main() {
  binding;
  testWidgets('auxiliar: recorrido de capturas', (t) async {
    await t.pumpWidget(
      AppAuxiliarDemo(dependencias: DependenciasAuxiliar.demo()),
    );
    await captura(t, 'auxiliar_01_servicio', ms: 1500);
    await paso('servicio abajo', () async {
      await bajar(t, 600);
      await captura(t, 'auxiliar_02_servicio_abajo');
    });
    await paso('perfil', () async {
      await tocar(t, find.text('Perfil').last, ms: 1500);
      await captura(t, 'auxiliar_03_perfil');
      await bajar(t, 600);
      await captura(t, 'auxiliar_04_perfil_abajo');
    });
  });
}
