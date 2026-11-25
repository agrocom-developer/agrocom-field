import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ImagenRedCampo con un recurso inexistente cae al ícono', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 40,
            height: 40,
            child: ImagenRedCampo(referencia: 'assets/no_existe.png'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });

  testWidgets('EsqueletoListaCampo anuncia «Cargando»', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EsqueletoListaCampo(
            bloques: [BloqueEsqueleto(alto: 20), BloqueEsqueleto(alto: 40)],
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
  });
}
