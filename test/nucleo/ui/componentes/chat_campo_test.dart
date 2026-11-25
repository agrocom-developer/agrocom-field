import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/ui/componentes/chat_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';

Future<void> _montar(
  WidgetTester tester,
  Widget hijo, {
  ModoVisualCampo modo = ModoVisualCampo.claro,
  double ancho = 360,
}) async {
  tester.view.physicalSize = Size(ancho, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AgrocomThemeCampo.construir(modo: modo),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: hijo),
      ),
    ),
  );
}

void main() {
  testWidgets('la burbuja con foto mide 200 de ancho en un teléfono chico', (
    tester,
  ) async {
    await _montar(
      tester,
      const BurbujaFotoChatCampo(
        foto: ColoredBox(color: Colors.green),
        propio: false,
        hora: '10:32',
        pie: 'Así queda el punto de carga.',
        etiquetaSemantica: 'Piloto, 10:32: foto',
      ),
    );
    final burbuja = find.descendant(
      of: find.byType(BurbujaFotoChatCampo),
      matching: find.byType(Container),
    );
    expect(tester.getSize(burbuja.first).width, 200);
    expect(find.text('10:32'), findsOneWidget);
    expect(find.text('Así queda el punto de carga.'), findsOneWidget);
  });

  testWidgets('el evento del sistema es una píldora acentoContenedor', (
    tester,
  ) async {
    await _montar(
      tester,
      const EventoSistemaChatCampo(texto: 'La solicitud quedó adjudicada.'),
    );
    final contexto = tester.element(find.byType(EventoSistemaChatCampo));
    final caja = tester.widget<Container>(
      find.descendant(
        of: find.byType(EventoSistemaChatCampo),
        matching: find.byType(Container),
      ),
    );
    final decoracion = caja.decoration! as BoxDecoration;
    expect(decoracion.color, contexto.paleta.acentoContenedor);
    expect(find.text('La solicitud quedó adjudicada.'), findsOneWidget);
  });

  for (final modo in ModoVisualCampo.values) {
    testWidgets('la burbuja de texto propia usa el acento en ${modo.name}', (
      tester,
    ) async {
      await _montar(
        tester,
        const BurbujaTextoChatCampo(
          texto: 'Llego el lunes temprano.',
          propio: true,
          hora: '09:10',
          etiquetaSemantica: 'Tú, 09:10: Llego el lunes temprano.',
        ),
        modo: modo,
      );
      expect(find.text('Llego el lunes temprano.'), findsOneWidget);
      expect(find.text('09:10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
