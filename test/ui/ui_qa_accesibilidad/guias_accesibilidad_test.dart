// Auditoría de accesibilidad de las pantallas raíz de los tres flavors con
// las guías de Flutter: objetivos táctiles (48 dp en Android, 44 pt en iOS),
// etiqueta semántica en cada control y contraste de texto.
//
// Recorre cada pestaña de la demo, en claro y oscuro (cliente) o en modo
// campo (piloto), con texto al 100 % y al 200 %.

import 'package:agrocom_field/cliente/app_cliente.dart';
import 'package:agrocom_field/cliente/ofertas/presentation/ofertas_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/chat_pantalla.dart';
import 'package:agrocom_field/cliente/seguimiento/presentation/seguimiento_pantalla.dart';
import 'package:agrocom_field/cliente/solicitudes/presentation/solicitud_detalle_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/piloto/app_piloto_demo.dart';
import 'package:agrocom_field/piloto/di/dependencias_piloto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui_negociacion_cliente/ayudas.dart';

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
              'Solicitudes',
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
        // Abre en el mapa: también se audita antes de cambiar de pestaña.
        await _auditar(tester);
        for (final pestana in ['Ofertas', 'Servicio', 'Drones', 'Perfil']) {
          await tester.tap(find.text(pestana).last);
          await asentar(tester, veces: 12);
          await _auditar(tester);
        }
        semantica.dispose();
      });
    }
  }

  // Las pantallas que se abren desde la lista: comparar ofertas, el detalle,
  // el seguimiento y el chat, con las mismas guías.
  final pantallas = <String, Widget Function()>{
    'ofertas': () => OfertasPantalla(
      solicitudId: '4101',
      reloj: () => ahoraDePrueba,
      intervalo: null,
    ),
    'detalle con ofertas': () =>
        const SolicitudDetallePantalla(solicitudId: '4101'),
    'detalle finalizada': () =>
        const SolicitudDetallePantalla(solicitudId: '4103'),
    'seguimiento': () => SeguimientoPantalla(
      solicitudId: '4102',
      reloj: () => ahoraDePrueba,
      intervalo: null,
    ),
    'chat': () => ChatPantalla(solicitudId: '4102', intervalo: null),
  };
  for (final MapEntry(key: nombre, value: pantalla) in pantallas.entries) {
    for (final v in Variante.matriz) {
      testWidgets('cliente $nombre ${v.sufijo}', (tester) async {
        final semantica = tester.ensureSemantics();
        final almacen = almacenDePrueba();
        await montar(
          tester,
          pantalla: pantalla(),
          dependencias: dependenciasDePrueba(almacen),
          variante: v,
        );
        await precargarFotos(tester);
        await asentar(tester, veces: 12);
        await _auditar(tester);
        semantica.dispose();
      });
    }
  }
}
