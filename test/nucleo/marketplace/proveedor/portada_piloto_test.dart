// Portada de la app del piloto: dice que es la app DE PILOTO y lista lo que
// un piloto puede hacer; las acciones quedan al alcance con guantes.

import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/acceso/presentation/portada_piloto_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:agrocom_field/nucleo/ui/tokens_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home, {double escala = 1}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  theme: AgrocomThemeCampo.construir(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(escala)),
    child: child!,
  ),
  home: home,
);

void main() {
  testWidgets('se identifica como la app de piloto y lista sus capacidades', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(PortadaPilotoPantalla(alEntrar: () {}, alRegistrarse: () {})),
    );
    expect(find.text('DronAgro'), findsOneWidget);
    expect(find.text('Piloto'), findsOneWidget);
    expect(find.text('Qué puedes hacer como piloto'), findsOneWidget);
    expect(find.text('Cliente'), findsNothing);
    expect(find.textContaining('Publica una solicitud'), findsNothing);
  });

  testWidgets('entrar y registrarse llaman a su acción', (tester) async {
    var entrar = 0;
    var registro = 0;
    await tester.pumpWidget(
      _app(
        PortadaPilotoPantalla(
          alEntrar: () => entrar++,
          alRegistrarse: () => registro++,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('portada-piloto-entrar')));
    await tester.tap(find.byKey(const Key('portada-piloto-registro')));
    expect(entrar, 1);
    expect(registro, 1);
  });

  testWidgets('sin registro abierto no ofrece el alta', (tester) async {
    await tester.pumpWidget(_app(PortadaPilotoPantalla(alEntrar: () {})));
    expect(find.byKey(const Key('portada-piloto-registro')), findsNothing);
  });

  testWidgets('los botones miden 56 dp o más', (tester) async {
    await tester.pumpWidget(
      _app(PortadaPilotoPantalla(alEntrar: () {}, alRegistrarse: () {})),
    );
    for (final clave in ['portada-piloto-entrar', 'portada-piloto-registro']) {
      final alto = tester.getSize(find.byKey(Key(clave))).height;
      expect(alto, greaterThanOrEqualTo(ObjetivoTactilCampo.guantes));
    }
  });

  testWidgets(
    'con texto al 200 % no desborda y los botones siguen a la vista',
    (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          PortadaPilotoPantalla(alEntrar: () {}, alRegistrarse: () {}),
          escala: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('portada-piloto-entrar')), findsOneWidget);
    },
  );
}
