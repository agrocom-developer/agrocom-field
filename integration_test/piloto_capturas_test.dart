import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:agrocom_field/piloto/di/dependencias_piloto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_capturas.dart';

/// Capturas del flavor piloto con datos ficticios, una por destino de la
/// barra de navegación (mapa, ofertas, servicio, drones, perfil) y su
/// continuación. Se ejecutan con `tool/capturar_pantallas.sh`.
void main() {
  binding;
  ConfiguracionMapa.teselas = false;
  testWidgets('piloto: recorrido de capturas', (t) async {
    await t.pumpWidget(AppPilotoDemo(dependencias: DependenciasPiloto.demo()));
    await captura(t, 'piloto_01_mapa', ms: 1500);
    for (final (indice, destino) in [
      (2, 'ofertas'),
      (3, 'servicio'),
      (4, 'drones'),
      (5, 'perfil'),
    ]) {
      await paso(destino, () async {
        await tocar(t, find.text(_etiquetas[destino]!).last, ms: 1500);
        await captura(
          t,
          'piloto_${indice.toString().padLeft(2, '0')}_$destino',
        );
        await bajar(t, 600);
        await captura(
          t,
          'piloto_${indice.toString().padLeft(2, '0')}_${destino}_abajo',
        );
      });
    }
  });
}

const _etiquetas = {
  'ofertas': 'Ofertas',
  'servicio': 'Servicio',
  'drones': 'Drones',
  'perfil': 'Perfil',
};
