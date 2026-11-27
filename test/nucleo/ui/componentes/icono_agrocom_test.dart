import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/icono_agrocom.dart';
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
  testWidgets('IconoAgrocom usa la etiqueta por defecto del ícono', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(const IconoAgrocom(IconoAgrocomId.dronT30)),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Dron Agras T30'), findsOneWidget);
  });

  testWidgets('IconoAgrocom respeta un semanticLabel propio', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const IconoAgrocom(
          IconoAgrocomId.bateria,
          semanticLabel: 'Batería del dron 2',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Batería del dron 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Batería'), findsNothing);
  });

  testWidgets('IconoAgrocom con excluirSemantica no anuncia nada', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        const IconoAgrocom(IconoAgrocomId.lote, excluirSemantica: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Lote'), findsNothing);
  });

  test('IconoAgrocomId.deModeloDron reconoce el código del modelo', () {
    expect(
      IconoAgrocomId.deModeloDron('DJI Agras T30'),
      IconoAgrocomId.dronT30,
    );
    expect(IconoAgrocomId.deModeloDron('t50'), IconoAgrocomId.dronT50);
    expect(
      IconoAgrocomId.deModeloDron('modelo desconocido'),
      IconoAgrocomId.dronT30,
    );
  });

  testWidgets('cada ícono de la flota carga sin lanzar errores', (
    tester,
  ) async {
    for (final id in IconoAgrocomId.values) {
      await tester.pumpWidget(_envolver(IconoAgrocom(id)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'ícono ${id.name}');
    }
  });
}
