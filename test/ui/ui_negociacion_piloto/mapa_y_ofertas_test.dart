// Mapa de solicitudes abiertas, detalle, primera oferta, mis ofertas, chat y
// avisos del piloto, en modo campo: comportamiento, estados (carga, vacío,
// error, sin red, éxito), texto al 200 % y goldens.

import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/avisos_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/chat_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mapa_solicitudes.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mapa_solicitudes_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/mis_ofertas_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/solicitud_detalle_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/superficie_marketplace.dart';
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
    // El panel de zonas es la fila de filtros de arriba (el primer
    // `ListView`); la hoja inferior lleva el suyo.
    Finder chip(String texto) => find.descendant(
      of: find.byType(ListView).first,
      matching: find.text(texto),
    );

    Future<void> abrir(
      WidgetTester tester, {
      Size tamano = telefonoGrande,
      double escala = 1.0,
    }) async {
      await montar(
        tester,
        MapaSolicitudesPantalla(reloj: relojFijo),
        dependencias: entorno.dependencias,
        tamano: tamano,
        escala: escala,
      );
      await esperar(tester);
    }

    for (final (tamano, escala) in matriz) {
      testWidgets('se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await abrir(tester, tamano: tamano, escala: escala);
        expect(find.text('Buscar zona o lote'), findsOneWidget);
        expect(find.byType(MapaSolicitudes), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'mapa_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('muestra los pines, los filtros rápidos y el resumen', (
      tester,
    ) async {
      await abrir(tester);
      // Un pin por solicitud: el de Warnes vence hoy y lo dice.
      expect(find.text('Bs 121 · hoy'), findsOneWidget);
      expect(find.text('Bs 118'), findsOneWidget);
      expect(chip('Cerca de mí'), findsOneWidget);
      expect(chip('+50 ha'), findsOneWidget);
      expect(chip('Vence hoy'), findsOneWidget);
      expect(chip('Valles'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Dónde hay trabajo'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Dónde hay trabajo'), findsOneWidget);
    });

    testWidgets('elegir un pin abre la solicitud con sus dos salidas', (
      tester,
    ) async {
      await abrir(tester);
      await tester.tap(find.text('Bs 118'));
      await esperar(tester);
      expect(find.text('Lote de sorgo'), findsOneWidget);
      expect(find.text('Superficie'), findsOneWidget);
      expect(find.text('Precio ofrecido'), findsOneWidget);
      expect(find.text('Contraofertar'), findsOneWidget);
      expect(find.text('Aceptar 118'), findsOneWidget);
      await golden(tester, 'mapa_seleccion_412x915_x1');
    });

    testWidgets('aceptar desde el mapa envía la oferta al precio del cliente', (
      tester,
    ) async {
      await abrir(tester);
      await tester.tap(find.text('Bs 118'));
      await esperar(tester);
      await tester.tap(find.text('Aceptar 118'));
      await esperar(tester);
      expect(find.textContaining('Oferta enviada'), findsOneWidget);
      expect(entorno.almacenNegociacion.ofertas.first.solicitudId, 6);
    });

    testWidgets('sin red, aceptar avisa «Sin señal» y se puede reintentar', (
      tester,
    ) async {
      await abrir(tester);
      await tester.tap(find.text('Bs 118'));
      await esperar(tester);
      entorno.almacenNegociacion.enLinea = false;
      await tester.tap(find.text('Aceptar 118'));
      await esperar(tester);
      expect(
        find.textContaining('Sin señal · aceptar necesita red'),
        findsOneWidget,
      );
      entorno.almacenNegociacion.enLinea = true;
      await tester.tap(find.text('Aceptar 118'));
      await esperar(tester);
      expect(find.textContaining('Oferta enviada'), findsOneWidget);
    });

    testWidgets('contraofertar abre la negociación con el cliente', (
      tester,
    ) async {
      await abrir(tester);
      await tester.tap(find.text('Bs 118'));
      await esperar(tester);
      await tester.tap(find.text('Contraofertar'));
      await esperar(tester);
      expect(find.text('Negociación con el cliente'), findsOneWidget);
      expect(find.text('Ronda 2 de 5'), findsOneWidget);
    });

    testWidgets('filtrar por zona deja solo las solicitudes de esa zona', (
      tester,
    ) async {
      await abrir(tester);
      await tester.tap(chip('Valles'));
      await esperar(tester);
      expect(find.textContaining('60 ha'), findsWidgets);
      expect(find.textContaining('250 ha'), findsNothing);
      await golden(tester, 'mapa_filtrado_valles_412x915_x1');
    });

    testWidgets('«Vence hoy» deja solo lo que vence hoy', (tester) async {
      await abrir(tester);
      await tester.tap(chip('Vence hoy'));
      await esperar(tester);
      expect(find.text('Bs 121 · hoy'), findsOneWidget);
      expect(find.text('Bs 118'), findsNothing);
    });

    testWidgets('buscar por texto acota la lista y el mapa', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byType(TextField), 'chiquitos');
      await esperar(tester);
      expect(find.text('Bs 118'), findsOneWidget);
      expect(find.text('Bs 121 · hoy'), findsNothing);
    });

    testWidgets('sin solicitudes en la zona, el vacío orienta', (tester) async {
      await abrir(tester, tamano: telefonoChico);
      // Los filtros no caben: el de Chaco está al final de la fila.
      await tester.drag(
        find.descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        ),
        const Offset(-900, 0),
      );
      await tester.pump();
      await tester.tap(find.text('Chaco'));
      await esperar(tester);
      expect(find.text('Ninguna solicitud con estos filtros'), findsOneWidget);
      await golden(tester, 'mapa_vacio_360x640_x1');
    });

    testWidgets('sin conexión explica por qué y deja reintentar', (
      tester,
    ) async {
      entorno.almacenNegociacion.enLinea = false;
      await abrir(tester, tamano: telefonoChico);
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(
        find.textContaining('para mostrar lo que hay disponible'),
        findsOneWidget,
      );
      expect(find.textContaining('Sin señal ·'), findsWidgets);
      await golden(tester, 'mapa_sin_red_360x640_x1');
      entorno.almacenNegociacion.enLinea = true;
      await tester.ensureVisible(find.text('Reintentar ahora'));
      await tester.pump();
      await tester.tap(find.text('Reintentar ahora'));
      await esperar(tester);
      expect(find.text('Sin conexión'), findsNothing);
    });

    testWidgets('el panel de filtros pide hectáreas, precio, cultivo y orden', (
      tester,
    ) async {
      await abrir(tester);
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
      await irA(tester, find.textContaining('no ves su nombre'));
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

    testWidgets('contraofertar abre la negociación con el stepper', (
      tester,
    ) async {
      await abrir(tester, id: 1);
      await irA(tester, find.text('Contraofertar mi precio'));
      await tester.tap(find.text('Contraofertar mi precio'));
      await esperar(tester);
      expect(find.text('Negociación con el cliente'), findsOneWidget);
      expect(find.text('Enviar 121'), findsOneWidget);
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
      expect(
        find.textContaining('vuelve a intentarlo cuando tengas señal'),
        findsOneWidget,
      );
      expect(find.textContaining('Aceptar Bs 121'), findsOneWidget);
      entorno.almacenNegociacion.enLinea = true;
      await tester.tap(find.textContaining('Aceptar Bs 121'));
      await esperar(tester);
      expect(find.textContaining('Oferta enviada'), findsOneWidget);
    });
  });

  group('Mis ofertas', () {
    Future<void> abrir(
      WidgetTester tester, {
      Size tamano = telefonoGrande,
      double escala = 1.0,
    }) async {
      await montar(
        tester,
        const MisOfertasPantalla(),
        dependencias: entorno.dependencias,
        tamano: tamano,
        escala: escala,
      );
      await esperar(tester);
    }

    for (final (tamano, escala) in matriz) {
      testWidgets('se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await abrir(tester, tamano: tamano, escala: escala);
        expect(find.text('Mis ofertas'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'ofertas_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('separa Activas, Ganadas y Cerradas con su cuenta', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text('Activas 2'), findsOneWidget);
      expect(find.text('Ganadas 0'), findsOneWidget);
      expect(find.text('Tu turno · R4/5'), findsOneWidget);
      expect(find.text('Esperando · R3/5'), findsOneWidget);
      await tester.tap(find.text('Cerradas'));
      await esperar(tester);
      expect(find.text('Rechazada'), findsOneWidget);
      await tester.tap(find.text('Ganadas 0'));
      await esperar(tester);
      expect(find.text('Aún no ganaste ninguna'), findsOneWidget);
    });

    testWidgets('la tarjeta con tu turno lleva borde ámbar', (tester) async {
      await abrir(tester);
      final tarjetas = tester
          .widgetList<SuperficieMarketplace>(find.byType(SuperficieMarketplace))
          .toList();
      expect(tarjetas.where((t) => t.colorBorde != null), hasLength(1));
    });

    testWidgets('cada negociación se titula con la zona de su solicitud', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text('Santa Cruz de la Sierra'), findsOneWidget);
      expect(find.text('Solicitud 4'), findsNothing);
    });

    testWidgets(
      'aceptar la contraoferta del cliente deja la solicitud ganada',
      (tester) async {
        await abrir(tester);
        await tester.tap(find.text('Santa Cruz de la Sierra'));
        await esperar(tester);
        expect(find.text('Negociación con el cliente'), findsOneWidget);
        await tester.tap(find.text('Aceptar 122'));
        await esperar(tester);
        expect(find.textContaining('la solicitud es tuya'), findsOneWidget);
        await golden(tester, 'ofertas_adjudicada_412x915_x1');
        await tester.tap(find.text('Ver mis ofertas'));
        await esperar(tester);
        expect(find.text('Ganadas 1'), findsOneWidget);
      },
    );

    testWidgets('retirar la oferta propia la cierra', (tester) async {
      await abrir(tester);
      await tester.tap(find.text('San Ignacio de Velasco'));
      await esperar(tester);
      await tester.tap(find.text('Retirar mi oferta'));
      await esperar(tester);
      expect(find.textContaining('Retiraste tu oferta'), findsOneWidget);
    });

    testWidgets('sin ofertas, el vacío lleva al mapa', (tester) async {
      entorno.almacenNegociacion.vaciarOfertas();
      var fueAlMapa = false;
      await montar(
        tester,
        MisOfertasPantalla(alIrAlMapa: () => fueAlMapa = true),
        dependencias: entorno.dependencias,
      );
      await esperar(tester);
      expect(find.text('Todavía no hiciste ofertas'), findsOneWidget);
      await tester.tap(find.text('Ver lotes en el mapa'));
      expect(fueAlMapa, isTrue);
    });

    testWidgets('sin conexión no deja responder y lo dice', (tester) async {
      entorno.almacenNegociacion.enLinea = false;
      await abrir(tester, tamano: telefonoChico);
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(find.textContaining('Sin señal ·'), findsWidgets);
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
