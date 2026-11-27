import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/selector_opciones_hoja_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('elegir una opción cierra la hoja y devuelve el valor', (
    tester,
  ) async {
    String? elegido;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                elegido = await mostrarSelectorOpcionesCampo<String>(
                  context: context,
                  titulo: 'Ordenar por',
                  seleccionado: 'recomendado',
                  opciones: const [
                    OpcionHojaCampo(valor: 'recomendado', texto: 'Recomendado'),
                    OpcionHojaCampo(valor: 'precio', texto: 'Precio'),
                  ],
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar por'), findsOneWidget);
    expect(find.text('Recomendado'), findsOneWidget);
    expect(find.text('Precio'), findsOneWidget);

    await tester.tap(find.text('Precio'));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar por'), findsNothing);
    expect(elegido, 'precio');
  });

  testWidgets('la opción elegida muestra la tilde', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => mostrarSelectorOpcionesCampo<String>(
                context: context,
                titulo: 'Ordenar por',
                seleccionado: 'precio',
                opciones: const [
                  OpcionHojaCampo(valor: 'recomendado', texto: 'Recomendado'),
                  OpcionHojaCampo(valor: 'precio', texto: 'Precio'),
                ],
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
