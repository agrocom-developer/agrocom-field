import 'package:agrocom_field/nucleo/ui/colores_campo.dart';
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
    testWidgets('la estrella es de oro (no ámbar) en ${modo.name}', (
      tester,
    ) async {
      await tester.pumpWidget(_en(modo, const EstrellaCampo()));
      expect(_icono(tester).icon, Icons.star_rounded);
      // El color lo pone el degradado dorado, no el ámbar de los botones.
      expect(
        find.descendant(
          of: find.byType(EstrellaCampo),
          matching: find.byType(ShaderMask),
        ),
        findsOneWidget,
      );
      expect(ColoresCampo.gradienteDorado, hasLength(3));
      expect(
        ColoresCampo.gradienteDorado,
        isNot(contains(PaletaCampo.deModo(modo).ambar)),
      );

      await tester.pumpWidget(_en(modo, const EstrellaCampo(llena: false)));
      expect(_icono(tester).icon, Icons.star_outline_rounded);

      await tester.pumpWidget(_en(modo, const EstrellaCampo(media: true)));
      expect(_icono(tester).icon, Icons.star_half_rounded);
    });
  }

  testWidgets('con color explícito (apoyo tenue) no lleva degradado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _en(ModoVisualCampo.claro, const EstrellaCampo(color: Colors.grey)),
    );
    expect(_icono(tester).color, Colors.grey);
    expect(
      find.descendant(
        of: find.byType(EstrellaCampo),
        matching: find.byType(ShaderMask),
      ),
      findsNothing,
    );
  });
}
