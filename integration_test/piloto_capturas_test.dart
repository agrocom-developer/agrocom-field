import 'package:flutter/widgets.dart' show Key;
import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:agrocom_field/piloto/di/dependencias_piloto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_capturas.dart';

void main() {
  binding;
  testWidgets('piloto: recorrido de capturas', (t) async {
    await t.pumpWidget(AppPilotoDemo(dependencias: DependenciasPiloto.demo()));
    await captura(t, 'piloto_01_ofertas');
    await paso('oferta detalle', () async {
      await tocar(t, find.text('Ver detalle y mapa'));
      await captura(t, 'piloto_02_oferta_detalle');
      await bajar(t, 500);
      await captura(t, 'piloto_03_oferta_detalle_abajo');
      await atras(t);
    });
    await paso('servicio', () async {
      await tocar(t, find.text('Servicio').last);
      await captura(t, 'piloto_04_servicio');
      await bajar(t, 600);
      await captura(t, 'piloto_05_servicio_abajo');
    });
    await paso('detalle servicio', () async {
      await tocar(t, find.byKey(const Key('boton_ver_detalle')));
      await captura(t, 'piloto_06_servicio_detalle');
      await bajar(t, 500);
      await captura(t, 'piloto_07_servicio_detalle_abajo');
      await atras(t);
    });
    await paso('sesion vuelo', () async {
      await tocar(t, find.byKey(const Key('boton_abrir_sesion_vuelo')));
      await captura(t, 'piloto_08_sesion_apertura');
      await bajar(t, 600);
      await captura(t, 'piloto_09_sesion_apertura_abajo');
    });
  });
}
