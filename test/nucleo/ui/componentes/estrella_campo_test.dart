import 'package:agrocom_field/nucleo/ui/componentes/estrella_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _en(ModoVisualCampo modo, Widget hijo) => MaterialApp(
  theme: AgrocomThemeCampo.construir(modo: modo),
  home: Scaffold(body: hijo),
);

Icon _icono(WidgetTester tester) => tester.widget<Icon>(
  find.descendant(of: find.byType(EstrellaCampo), matching: find.byType(Icon)),
);

void main() {
  for (final modo in ModoVisualCampo.values) {
    testWidgets('la estrella es dorada en ${modo.name}, llena o vacía', (
      tester,
    ) async {
      final dorado = PaletaCampo.deModo(modo).ambar;
      await tester.pumpWidget(_en(modo, const EstrellaCampo()));
      expect(_icono(tester).icon, Icons.star_rounded);
      expect(_icono(tester).color, dorado);

      await tester.pumpWidget(_en(modo, const EstrellaCampo(llena: false)));
      expect(_icono(tester).icon, Icons.star_outline_rounded);
      expect(_icono(tester).color, dorado);

      await tester.pumpWidget(_en(modo, const EstrellaCampo(media: true)));
      expect(_icono(tester).icon, Icons.star_half_rounded);
      expect(_icono(tester).color, dorado);
    });
  }
}
