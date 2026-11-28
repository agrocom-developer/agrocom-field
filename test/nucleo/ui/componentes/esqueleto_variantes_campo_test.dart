import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/esqueleto_variantes_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('EsqueletoTarjetaOfertaCampo anuncia «Cargando»', (tester) async {
    await tester.pumpWidget(_envolver(const EsqueletoTarjetaOfertaCampo()));
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
  });

  testWidgets('EsqueletoFilaListaCampo se construye sin errores', (
    tester,
  ) async {
    await tester.pumpWidget(_envolver(const EsqueletoFilaListaCampo()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('EsqueletoPerfilCampo se construye sin errores', (tester) async {
    await tester.pumpWidget(_envolver(const EsqueletoPerfilCampo()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('EsqueletoMapaCampo respeta el alto pedido', (tester) async {
    await tester.pumpWidget(_envolver(const EsqueletoMapaCampo(alto: 220)));
    final tamano = tester.getSize(find.byType(EsqueletoMapaCampo));
    expect(tamano.height, 220);
  });
}
