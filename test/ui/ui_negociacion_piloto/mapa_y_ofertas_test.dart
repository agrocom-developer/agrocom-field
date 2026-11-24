// Mapa de solicitudes abiertas, detalle, primera oferta, mis ofertas, chat y
// avisos del piloto, en modo campo: comportamiento, estados (carga, vacío,
// error, sin red, éxito), texto al 200 % y goldens.

import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/avisos_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/chat_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mapa_solicitudes_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mis_ofertas_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/solicitud_detalle_pantalla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas.dart';

void main() {
  setUpAll(cargarFuentes);

  late EntornoNegociacion entorno;
  setUp(() => entorno = EntornoNegociacion());

  Future<void> esperar(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('Mapa de solicitudes', () {
    for (final (tamano, escala) in matriz) {
      testWidgets('se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await montar(
          tester,
          const MapaSolicitudesPantalla(),
          dependencias: entorno.dependencias,
          tamano: tamano,
          escala: escala,
        );
        await esperar(tester);
        expect(find.text('Solicitudes abiertas'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'mapa_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('muestra las solicitudes, el resumen y las zonas', (
      tester,
    ) async {
      await montar(
        tester,
        const MapaSolicitudesPantalla(),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      expect(find.widgetWithText(ChoiceChip, 'Valles'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Chiquitania'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Dónde hay trabajo'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Dónde hay trabajo'), findsOneWidget);
    });

    testWidgets('filtrar por zona deja solo las solicitudes de esa zona', (
      tester,
    ) async {
      await montar(
        tester,
        const MapaSolicitudesPantalla(),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Valles'));
      await esperar(tester);
      expect(find.textContaining('60 ha'), findsWidgets);
      expect(find.textContaining('250 ha'), findsNothing);
      await golden(tester, 'mapa_filtrado_valles_412x915_x1');
    });

    testWidgets('sin solicitudes en la zona, el vacío orienta', (tester) async {
      await montar(
        tester,
        const MapaSolicitudesPantalla(),
        dependencias: entorno.dependencias,
        tamano: telefonoChico,
      );
      await esperar(tester);
      final chaco = find.widgetWithText(ChoiceChip, 'Chaco');
      await tester.scrollUntilVisible(
        chaco,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(chaco));
      await tester.pump();
      await tester.tap(chaco);
      await esperar(tester);
      expect(find.text('Ninguna solicitud con estos filtros'), findsOneWidget);
      await golden(tester, 'mapa_vacio_360x640_x1');
    });

    testWidgets('sin conexión explica por qué y deja reintentar', (
      tester,
    ) async {
      entorno.almacenNegociacion.enLinea = false;
      await montar(
        tester,
        const MapaSolicitudesPantalla(),
        dependencias: entorno.dependencias,
        tamano: telefonoChico,
      );
      await esperar(tester);
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.textContaining('competencia'), findsOneWidget);
      await golden(tester, 'mapa_sin_red_360x640_x1');
      entorno.almacenNegociacion.enLinea = true;
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      expect(find.text('Sin conexión'), findsNothing);
    });

    testWidgets('el panel de filtros pide hectáreas, precio, cultivo y orden', (
      tester,
    ) async {
      await montar(
        tester,
        const MapaSolicitudesPantalla(),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      await tester.tap(find.byTooltip('Filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Filtrar solicitudes'), findsOneWidget);
      expect(find.text('Ordenar por'), findsOneWidget);
      await golden(tester, 'mapa_filtros_412x915_x1');
      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.tap(find.text('Ver solicitudes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('250 ha'), findsWidgets);
      expect(find.textContaining('40 ha'), findsNothing);
    });
  });

  group('Detalle de la solicitud y primera oferta', () {
    Future<void> abrir(
      WidgetTester tester, {
      int id = 1,
      Size tamano = telefonoGrande,
      double escala = 1.0,
    }) async {
      final solicitud = entorno.almacenNegociacion.solicitudes.firstWhere(
        (s) => s.id == id,
      );
      await montar(
        tester,
        SolicitudDetallePantalla(solicitud: solicitud),
        dependencias: entorno.dependencias,
        tamano: tamano,
        escala: escala,
        envolverEnScaffold: false,
      );
      await esperar(tester);
    }

    for (final (tamano, escala) in matriz) {
      testWidgets('se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await abrir(tester, id: 3, tamano: tamano, escala: escala);
        expect(find.text('El cliente propone'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'detalle_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('muestra el estado del terreno y no revela al cliente', (
      tester,
    ) async {
      await abrir(tester, id: 3);
      await irA(tester, find.text('Estado del terreno'));
      expect(find.text('Acceso difícil'), findsOneWidget);
      expect(find.textContaining('no ves su nombre'), findsOneWidget);
    });

    testWidgets('aceptar el precio propuesto envía la oferta', (tester) async {
      await abrir(tester, id: 1);
      await irA(tester, find.textContaining('Aceptar Bs 121'));
      await tester.tap(find.textContaining('Aceptar Bs 121'));
      await esperar(tester);
      expect(find.textContaining('Oferta enviada'), findsOneWidget);
      expect(entorno.almacenNegociacion.ofertas.first.solicitudId, 1);
      await golden(tester, 'detalle_oferta_enviada_412x915_x1');
    });

    testWidgets('contraofertar pide el precio, muestra el total y lo envía', (
      tester,
    ) async {
      await abrir(tester, id: 1);
      await irA(tester, find.text('Contraofertar mi precio'));
      await tester.tap(find.text('Contraofertar mi precio'));
      await tester.pumpAndSettle();
      expect(find.text('Tu contraoferta'), findsOneWidget);

      // El mismo precio que propone el cliente no es una contraoferta.
      await tester.enterText(find.byType(TextFormField).first, '121');
      await tester.tap(find.text('Enviar contraoferta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Es el mismo precio'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '118,5');
      await tester.pump();
      expect(find.textContaining('= Bs 4.740'), findsOneWidget);
      await golden(tester, 'detalle_contraoferta_412x915_x1');
      await tester.tap(find.text('Enviar contraoferta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Oferta enviada: Bs 118,5'), findsOneWidget);
      expect(
        entorno.almacenNegociacion.ofertas.first.precioHa.toString(),
        '118.5',
      );
    });

    testWidgets('una solicitud con negociación cerrada no admite ofertar', (
      tester,
    ) async {
      await abrir(tester, id: 2);
      await irA(tester, find.textContaining('ya se cerró'));
      expect(find.textContaining('Aceptar Bs'), findsNothing);
    });

    testWidgets('sin conexión al ofertar conserva todo y avisa', (
      tester,
    ) async {
      await abrir(tester, id: 1);
      entorno.almacenNegociacion.enLinea = false;
      await irA(tester, find.textContaining('Aceptar Bs 121'));
      await tester.tap(find.textContaining('Aceptar Bs 121'));
      await esperar(tester);
      expect(find.textContaining('No hay conexión'), findsOneWidget);
      expect(find.textContaining('Aceptar Bs 121'), findsOneWidget);
      entorno.almacenNegociacion.enLinea = true;
      await tester.tap(find.textContaining('Aceptar Bs 121'));
      await esperar(tester);
      expect(find.textContaining('Oferta enviada'), findsOneWidget);
    });
  });

  group('Mis ofertas', () {
    for (final (tamano, escala) in matriz) {
      testWidgets('se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await montar(
          tester,
          const MisOfertasPantalla(),
          dependencias: entorno.dependencias,
          tamano: tamano,
          escala: escala,
        );
        await esperar(tester);
        expect(find.text('Mis ofertas'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'ofertas_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('la contraoferta del cliente se acepta y queda adjudicada', (
      tester,
    ) async {
      await montar(
        tester,
        const MisOfertasPantalla(),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      expect(find.text('Te toca responder'), findsOneWidget);
      expect(find.text('Esperando al cliente'), findsOneWidget);
      await tester.tap(find.textContaining('Aceptar Bs 122'));
      await esperar(tester);
      expect(find.textContaining('te eligió'), findsOneWidget);
      expect(find.text('Adjudicada'), findsOneWidget);
      await golden(tester, 'ofertas_adjudicada_412x915_x1');
    });

    testWidgets('contraofertar de vuelta reemplaza la oferta del cliente', (
      tester,
    ) async {
      await montar(
        tester,
        const MisOfertasPantalla(),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      await tester.tap(find.text('Contraofertar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '125');
      await tester.tap(find.text('Enviar contraoferta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enviaste tu contraoferta'), findsOneWidget);
      expect(find.text('Te toca responder'), findsNothing);
    });

    testWidgets('retirar la oferta propia la cierra', (tester) async {
      await montar(
        tester,
        const MisOfertasPantalla(),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      await irA(tester, find.text('Retirar mi oferta'));
      await tester.tap(find.text('Retirar mi oferta'));
      await esperar(tester);
      expect(find.textContaining('Retiraste tu oferta'), findsOneWidget);
    });

    testWidgets('sin conexión no deja responder y lo dice', (tester) async {
      entorno.almacenNegociacion.enLinea = false;
      await montar(
        tester,
        const MisOfertasPantalla(),
        dependencias: entorno.dependencias,
        tamano: telefonoChico,
      );
      await esperar(tester);
      expect(find.text('Sin conexión'), findsOneWidget);
      await golden(tester, 'ofertas_sin_red_360x640_x1');
    });
  });

  group('Chat con el cliente', () {
    testWidgets('lee la conversación y envía un mensaje', (tester) async {
      await montar(
        tester,
        const ChatPantalla(solicitudId: 10),
        dependencias: entorno.dependencias,
        envolverEnScaffold: false,
      );
      await esperar(tester);
      expect(
        find.text('Gracias por avisar. Mañana paso por el lote.'),
        findsOneWidget,
      );
      await golden(tester, 'chat_412x915_x1');
      await tester.enterText(find.byType(TextField), 'Llego a las 7');
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await esperar(tester);
      expect(find.text('Llego a las 7'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('sin mensajes, el vacío orienta', (tester) async {
      await montar(
        tester,
        const ChatPantalla(solicitudId: 9),
        dependencias: entorno.dependencias,
        envolverEnScaffold: false,
        tamano: telefonoChico,
        escala: 2.0,
      );
      await esperar(tester);
      expect(find.text('Todavía no hay mensajes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await golden(tester, 'chat_vacio_360x640_x2');
    });
  });

  group('Avisos', () {
    for (final (tamano, escala) in matriz) {
      testWidgets('se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await montar(
          tester,
          const AvisosPantalla(),
          dependencias: entorno.dependencias,
          tamano: tamano,
          escala: escala,
          envolverEnScaffold: false,
        );
        await esperar(tester);
        expect(find.text('Nuevas solicitudes'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'avisos_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('apagar las nuevas solicitudes se guarda', (tester) async {
      await montar(
        tester,
        const AvisosPantalla(),
        dependencias: entorno.dependencias,
        envolverEnScaffold: false,
      );
      await esperar(tester);
      await tester.tap(find.byType(Switch).first);
      await esperar(tester);
      expect(
        entorno.almacenNegociacion.preferencias.nuevasSolicitudes,
        isFalse,
      );
    });

    testWidgets('elegir una zona se guarda', (tester) async {
      await montar(
        tester,
        const AvisosPantalla(),
        dependencias: entorno.dependencias,
        envolverEnScaffold: false,
      );
      await esperar(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Valles'));
      await esperar(tester);
      expect(
        entorno.almacenNegociacion.preferencias.macrorregiones.map(
          (m) => m.etiqueta,
        ),
        ['Valles'],
      );
    });
  });
}
