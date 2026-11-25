// La negociación del piloto como conversación (pantalla 15): rondas en
// burbujas, stepper de ±1 Bs/ha con el total en vivo, aceptar y enviar con
// red, «Sin señal» cuando falla, y todos sus estados.

import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/domain/negociacion.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/negociacion/presentation/negociacion_pantalla.dart';
import 'package:decimal/decimal.dart';
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

  Future<void> abrir(
    WidgetTester tester,
    int id, {
    Size tamano = telefonoGrande,
    double escala = 1.0,
    bool conFila = true,
  }) async {
    final solicitud = entorno.almacenNegociacion.solicitudes.firstWhere(
      (s) => s.id == id,
    );
    await montar(
      tester,
      NegociacionPantalla(
        solicitudId: id,
        solicitud: conFila ? solicitud : null,
      ),
      dependencias: entorno.dependencias,
      tamano: tamano,
      escala: escala,
      envolverEnScaffold: false,
    );
    await esperar(tester);
  }

  group('Primera contraoferta (desde el mapa)', () {
    for (final (tamano, escala) in matriz) {
      testWidgets('se lee completo en ${sufijo(tamano, escala)}', (
        tester,
      ) async {
        await abrir(tester, 1, tamano: tamano, escala: escala);
        expect(find.text('Negociación con el cliente'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await golden(tester, 'negociacion_primera_${sufijo(tamano, escala)}');
      });
    }

    testWidgets('muestra la solicitud publicada como R1 y la ronda 2', (
      tester,
    ) async {
      await abrir(tester, 1);
      expect(find.text('R1 · CLIENTE'), findsOneWidget);
      expect(find.text('Publicado'), findsOneWidget);
      expect(find.text('Ronda 2 de 5'), findsOneWidget);
      expect(find.textContaining('Tu turno'), findsOneWidget);
    });

    testWidgets('el stepper sube y baja de a 1 y recalcula el total', (
      tester,
    ) async {
      await abrir(tester, 1);
      // 40 ha al precio del cliente: 121 Bs/ha.
      expect(find.text('121'), findsWidgets);
      expect(find.text('total Bs 4.840'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(find.text('Enviar 119'), findsOneWidget);
      expect(find.text('total Bs 4.760'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(find.text('total Bs 4.800'), findsOneWidget);
    });

    testWidgets('con el precio del cliente, enviar queda apagado', (
      tester,
    ) async {
      await abrir(tester, 1);
      final boton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Enviar 121'),
      );
      expect(boton.onPressed, isNull);
    });

    testWidgets('enviar manda la contraoferta y queda esperando al cliente', (
      tester,
    ) async {
      await abrir(tester, 1);
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      await tester.tap(find.text('Enviar 120'));
      await esperar(tester);
      expect(find.textContaining('Esperando al cliente'), findsOneWidget);
      expect(find.text('R2 · TÚ'), findsOneWidget);
      expect(find.text('Ver mis ofertas'), findsOneWidget);
      final oferta = entorno.almacenNegociacion.ofertas.first;
      expect(oferta.solicitudId, 1);
      expect(oferta.precioHa, Decimal.fromInt(120));
      await golden(tester, 'negociacion_enviada_412x915_x1');
    });

    testWidgets('aceptar el precio del cliente envía la oferta', (
      tester,
    ) async {
      await abrir(tester, 1);
      await tester.tap(find.text('Aceptar 121'));
      await esperar(tester);
      expect(find.textContaining('Esperando al cliente'), findsOneWidget);
      expect(
        entorno.almacenNegociacion.ofertas.first.tipo,
        TipoOferta.aceptaPropuesta,
      );
    });

    testWidgets('sin red avisa «Sin señal», conserva el precio y reintenta', (
      tester,
    ) async {
      await abrir(tester, 1);
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      entorno.almacenNegociacion.enLinea = false;
      await tester.tap(find.text('Enviar 120'));
      await esperar(tester);
      expect(
        find.textContaining('Sin señal · ofertar necesita red'),
        findsOneWidget,
      );
      expect(find.text('Reintentar 120'), findsOneWidget);
      await golden(tester, 'negociacion_sin_red_412x915_x1');
      entorno.almacenNegociacion.enLinea = true;
      await tester.tap(find.text('Reintentar 120'));
      await esperar(tester);
      expect(find.textContaining('Esperando al cliente'), findsOneWidget);
      expect(entorno.almacenNegociacion.ofertas, hasLength(4));
    });

    testWidgets('sin la fila del mapa pide el detalle y carga igual', (
      tester,
    ) async {
      await abrir(tester, 1, conFila: false);
      expect(find.text('Ronda 2 de 5'), findsOneWidget);
    });

    testWidgets('sin red al abrir, explica y deja reintentar', (tester) async {
      entorno.almacenNegociacion.enLinea = false;
      await abrir(tester, 1, tamano: telefonoChico, conFila: false);
      expect(find.text('Sin conexión'), findsOneWidget);
      await golden(tester, 'negociacion_sin_red_abrir_360x640_x1');
      entorno.almacenNegociacion.enLinea = true;
      await tester.tap(find.text('Reintentar'));
      await esperar(tester);
      expect(find.text('Ronda 2 de 5'), findsOneWidget);
    });
  });

  group('Respuesta a la oferta del cliente', () {
    testWidgets('lista las rondas y acepta la última del cliente', (
      tester,
    ) async {
      await abrir(tester, 4);
      // R1 publicada (125) y la contraoferta del cliente (ronda 3, 122).
      expect(find.text('R1 · CLIENTE'), findsOneWidget);
      expect(find.text('R3 · CLIENTE'), findsOneWidget);
      expect(find.text('Ronda 4 de 5'), findsOneWidget);
      expect(
        find.text('Tu turno · después solo queda la ronda 5'),
        findsOneWidget,
      );
      await golden(tester, 'negociacion_respuesta_412x915_x1');
      await tester.tap(find.text('Aceptar 122'));
      await esperar(tester);
      expect(find.textContaining('la solicitud es tuya'), findsOneWidget);
    });

    testWidgets('contraofertar de vuelta agrega la ronda del piloto', (
      tester,
    ) async {
      await abrir(tester, 4);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.tap(find.text('Enviar 123'));
      await esperar(tester);
      expect(find.text('R4 · TÚ'), findsOneWidget);
      expect(find.textContaining('Esperando al cliente'), findsOneWidget);
    });

    testWidgets('con la oferta propia vigente se puede retirar', (
      tester,
    ) async {
      await abrir(tester, 5);
      expect(find.textContaining('Esperando al cliente'), findsOneWidget);
      await tester.tap(find.text('Retirar mi oferta'));
      await esperar(tester);
      expect(find.textContaining('Retiraste tu oferta'), findsOneWidget);
    });

    testWidgets('la oferta definitiva solo se acepta o se rechaza', (
      tester,
    ) async {
      final base = entorno.almacenNegociacion.ofertas.firstWhere(
        (o) => o.id == 501,
      );
      entorno.almacenNegociacion.reemplazarOferta(
        OfertaNegociada(
          id: base.id,
          uuidCliente: base.uuidCliente,
          solicitudId: base.solicitudId,
          numero: base.numero,
          autor: base.autor,
          tipo: base.tipo,
          precioHa: base.precioHa,
          monto: base.monto,
          estado: base.estado,
          esDefinitiva: true,
          venceEn: base.venceEn,
          zona: base.zona,
        ),
      );
      await abrir(tester, 4);
      expect(find.textContaining('ronda final'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.text('Aceptar 122'), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
      await tester.tap(find.text('Rechazar'));
      await esperar(tester);
      expect(find.textContaining('Rechazaste la oferta'), findsOneWidget);
    });

    testWidgets('una negociación cerrada no admite ofertar', (tester) async {
      await abrir(tester, 2);
      expect(find.textContaining('ya se cerró'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);
      expect(find.text('Aceptar 115'), findsNothing);
    });
  });
}
