import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/boton_envio_campo.dart';
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
  testWidgets('inactivo muestra el texto y se puede tocar', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      _envolver(
        BotonEnvioCampo(
          texto: 'Aceptar servicio',
          estado: EstadoEnvioCampo.inactivo,
          onPressed: () => toques++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aceptar servicio'), findsOneWidget);
    await tester.tap(find.byType(BotonEnvioCampo));
    expect(toques, 1);
  });

  testWidgets('enviando muestra el indicador y bloquea el botón', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        BotonEnvioCampo(
          texto: 'Aceptar servicio',
          estado: EstadoEnvioCampo.enviando,
          onPressed: () {},
        ),
      ),
    );
    // `CircularProgressIndicator` indeterminado nunca se asienta: se usa
    // `pump` simple, no `pumpAndSettle`.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Enviando…'), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
  });

  testWidgets('éxito muestra la tilde', (tester) async {
    await tester.pumpWidget(
      _envolver(
        BotonEnvioCampo(
          texto: 'Aceptar servicio',
          estado: EstadoEnvioCampo.exito,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Listo'), findsOneWidget);
  });

  testWidgets('error muestra un botón de contorno para reintentar', (
    tester,
  ) async {
    var reintentos = 0;
    await tester.pumpWidget(
      _envolver(
        BotonEnvioCampo(
          texto: 'Aceptar servicio',
          estado: EstadoEnvioCampo.error,
          onPressed: () => reintentos++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OutlinedButton), findsOneWidget);
    await tester.tap(find.byType(BotonEnvioCampo));
    expect(reintentos, 1);
  });
}
