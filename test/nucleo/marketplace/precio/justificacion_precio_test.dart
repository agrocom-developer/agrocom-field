import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/precio/justificacion_precio.dart';
import 'package:agrocom_field/nucleo/marketplace/precio/presentation/campo_justificacion_precio.dart';
import 'package:agrocom_field/nucleo/marketplace/precio/presentation/total_solo_lectura.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget hijo) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: hijo),
  ),
);

void main() {
  group('JustificacionPrecio.normalizar', () {
    test('un texto vacío o en blanco no se envía', () {
      expect(JustificacionPrecio.normalizar(null), isNull);
      expect(JustificacionPrecio.normalizar('   \n  '), isNull);
    });

    test('quita saltos de línea y espacios repetidos', () {
      expect(
        JustificacionPrecio.normalizar(
          '  Incluye\ntraslado   y\r\ndos pasadas ',
        ),
        'Incluye traslado y dos pasadas',
      );
    });

    test('recorta a 500 caracteres', () {
      final largo = 'a' * 700;
      expect(JustificacionPrecio.normalizar(largo)!.length, 500);
    });
  });

  test('el total estimado es decimal exacto, sin redondeo binario', () {
    expect(
      totalEstimado(Decimal.parse('80.1'), Decimal.parse('118.3')),
      Decimal.parse('9475.83'),
    );
    expect(totalEstimado(null, Decimal.one), isNull);
  });

  testWidgets('el campo no admite saltos de línea y cuenta los caracteres', (
    tester,
  ) async {
    final c = TextEditingController();
    await tester.pumpWidget(_app(CampoJustificacionPrecio(controller: c)));
    await tester.enterText(
      find.byKey(const ValueKey('campo-justificacion-precio')),
      'Dos\npasadas',
    );
    await tester.pump();
    expect(c.text, 'Dospasadas');
    expect(find.text('10 de 500'), findsOneWidget);
  });

  testWidgets('el campo se detiene en 500 caracteres', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(_app(CampoJustificacionPrecio(controller: c)));
    await tester.enterText(
      find.byKey(const ValueKey('campo-justificacion-precio')),
      'x' * 600,
    );
    await tester.pump();
    expect(c.text.length, 500);
    expect(find.text('500 de 500'), findsOneWidget);
  });

  testWidgets('el total de solo lectura muestra hectáreas por precio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TotalSoloLectura(
          hectareas: Decimal.parse('80'),
          precioHa: Decimal.parse('118'),
        ),
      ),
    );
    expect(find.text('Total estimado'), findsOneWidget);
    expect(find.textContaining('9.440'), findsWidgets);
    // No hay ningún campo editable en el total.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('sin precio el total pide escribirlo', (tester) async {
    await tester.pumpWidget(
      _app(TotalSoloLectura(hectareas: Decimal.parse('80'), precioHa: null)),
    );
    expect(find.text('Escribe el precio'), findsOneWidget);
  });
}
