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

  group('IconoAgrocomId.deModeloDron mapea los seis modelos', () {
    const casos = <String, IconoAgrocomId>{
      'T10': IconoAgrocomId.dronT10,
      'T10 ': IconoAgrocomId.dronT10,
      'dji agras t10': IconoAgrocomId.dronT10,
      'DJI-T20': IconoAgrocomId.dronT20,
      'Agras T20P': IconoAgrocomId.dronT20,
      'Agras T25': IconoAgrocomId.dronT25,
      '  t25 ': IconoAgrocomId.dronT25,
      'DJI Agras T30': IconoAgrocomId.dronT30,
      'T30': IconoAgrocomId.dronT30,
      't40': IconoAgrocomId.dronT40,
      'DJI Agras T40': IconoAgrocomId.dronT40,
      'T-50': IconoAgrocomId.dronT50,
      'DJI Agras T50': IconoAgrocomId.dronT50,
      't50': IconoAgrocomId.dronT50,
    };
    casos.forEach((modelo, esperado) {
      test('«$modelo» es ${esperado.name}', () {
        expect(IconoAgrocomId.deModeloDron(modelo), esperado);
      });
    });

    for (final modelo in ['', '   ', 'Mavic 3', 'T2', 'modelo desconocido']) {
      test('«$modelo» cae en el T30', () {
        expect(IconoAgrocomId.deModeloDron(modelo), IconoAgrocomId.dronT30);
      });
    }
  });

  testWidgets('los 14 íconos tienen etiqueta semántica en español', (
    tester,
  ) async {
    expect(IconoAgrocomId.values, hasLength(14));
    late AppLocalizations l10n;
    await tester.pumpWidget(
      _envolver(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    final etiquetas = <String>{};
    for (final id in IconoAgrocomId.values) {
      final etiqueta = id.etiquetaPorDefecto(l10n);
      expect(etiqueta.trim(), isNotEmpty, reason: id.name);
      expect(etiquetas.add(etiqueta), isTrue, reason: 'repetida: ${id.name}');
      await tester.pumpWidget(_envolver(IconoAgrocom(id)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(etiqueta), findsOneWidget, reason: id.name);
    }
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
