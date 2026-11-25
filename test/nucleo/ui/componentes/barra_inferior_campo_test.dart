import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/ui/componentes/barra_inferior_campo.dart';
import 'package:agrocom_field/nucleo/ui/componentes/navegacion_adaptativa_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';

const _destinos = [
  DestinoCampo(
    icono: Icons.home_outlined,
    iconoActivo: Icons.home,
    etiqueta: 'Uno',
  ),
  DestinoCampo(
    icono: Icons.map_outlined,
    iconoActivo: Icons.map,
    etiqueta: 'Dos',
  ),
  DestinoCampo(
    icono: Icons.list,
    iconoActivo: Icons.list_alt,
    etiqueta: 'Tres',
  ),
  DestinoCampo(
    icono: Icons.person_outline,
    iconoActivo: Icons.person,
    etiqueta: 'Cuatro',
  ),
];

void main() {
  testWidgets(
    'el activo lleva el indicador tonal de 56 x 30 y avisa el toque',
    (tester) async {
      var tocado = -1;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
          home: Scaffold(
            bottomNavigationBar: BarraInferiorCampo(
              destinos: _destinos,
              indice: 1,
              onSeleccionar: (i) => tocado = i,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final indicador = tester.getSize(
        find
            .descendant(
              of: find.byType(BarraInferiorCampo),
              matching: find.byType(AnimatedContainer),
            )
            .at(1),
      );
      expect(indicador, const Size(56, 30));
      expect(find.text('Cuatro'), findsOneWidget);
      await tester.tap(find.text('Cuatro'));
      expect(tocado, 3);
    },
  );

  testWidgets('cada destino mide al menos 48 de alto y marca el activo', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
        home: Scaffold(
          bottomNavigationBar: BarraInferiorCampo(
            destinos: _destinos,
            indice: 0,
            onSeleccionar: (_) {},
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(InkWell).first).height,
      greaterThanOrEqualTo(48),
    );
    final nodo = tester.getSemantics(find.bySemanticsLabel('Uno'));
    expect(nodo.hint, '1 / 4');
    // ignore: deprecated_member_use
    expect(nodo.hasFlag(SemanticsFlag.isSelected), isTrue);
    semantica.dispose();
  });
}
