// Auditoría de accesibilidad de las pantallas raíz de los tres flavors con
// las guías de Flutter: objetivos táctiles (48 dp en Android, 44 pt en iOS),
// etiqueta semántica en cada control y contraste de texto.
//
// Recorre cada pestaña de la demo, en claro y oscuro (cliente) o en modo
// campo (piloto y auxiliar), con texto al 100 % y al 200 %.

import 'package:agrocom_field/auxiliar/app_auxiliar_demo.dart';
import 'package:agrocom_field/auxiliar/di/dependencias_auxiliar.dart';
import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:agrocom_field/piloto/di/dependencias_piloto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui_seguimiento_calificacion/ayudas.dart';

Future<void> _auditar(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

Future<void> _preparar(WidgetTester tester, Size tamano, double escala) async {
  ConfiguracionMapa.teselas = false;
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = escala;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAllTestValues();
    ConfiguracionMapa.teselas = true;
  });
}

void main() {
  const tamanos = [Size(360, 640), Size(412, 915)];
  const escalas = [1.0, 2.0];

  for (final tamano in tamanos) {
    for (final escala in escalas) {
      final nombre =
          '${tamano.width.toInt()}x${tamano.height.toInt()} '
          'texto ${(escala * 100).toInt()} %';

      for (final oscuro in [false, true]) {
        testWidgets(
          'cliente ${oscuro ? 'oscuro' : 'claro'} $nombre: pestañas',
          (tester) async {
            final semantica = tester.ensureSemantics();
            await _preparar(tester, tamano, escala);
            tester.platformDispatcher.platformBrightnessTestValue = oscuro
                ? Brightness.dark
                : Brightness.light;
            await tester.pumpWidget(
              AppCliente(dependencias: dependenciasDePrueba(almacenDePrueba())),
            );
            await asentar(tester, veces: 12);
            for (final pestana in [
              'Inicio',
              'Solicitar',
              'Servicios',
              'Cuenta',
            ]) {
              await tester.tap(find.text(pestana).last);
              await asentar(tester, veces: 12);
              await _auditar(tester);
            }
            semantica.dispose();
          },
        );
      }

      testWidgets('piloto campo $nombre: pestañas', (tester) async {
        final semantica = tester.ensureSemantics();
        await _preparar(tester, tamano, escala);
        await tester.pumpWidget(
          AppPilotoDemo(dependencias: DependenciasPiloto.demo()),
        );
        await asentar(tester, veces: 12);
        for (final pestana in ['Ofertas', 'Servicio', 'Drones', 'Perfil']) {
          await tester.tap(find.text(pestana).last);
          await asentar(tester, veces: 12);
          await _auditar(tester);
        }
        semantica.dispose();
      });

      testWidgets('auxiliar campo $nombre: pestañas', (tester) async {
        final semantica = tester.ensureSemantics();
        await _preparar(tester, tamano, escala);
        await tester.pumpWidget(
          AppAuxiliarDemo(dependencias: DependenciasAuxiliar.demo()),
        );
        await asentar(tester, veces: 12);
        for (final pestana in ['Servicio', 'Mezcla', 'Ofertas', 'Perfil']) {
          await tester.tap(find.text(pestana).last);
          await asentar(tester, veces: 12);
          await _auditar(tester);
        }
        semantica.dispose();
      });
    }
  }
}
