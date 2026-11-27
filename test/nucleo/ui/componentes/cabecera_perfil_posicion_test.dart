import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'el ícono del menú queda al mismo margen del borde que la insignia',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.oscuro),
          home: Scaffold(
            body: ListView(
              children: [
                CabeceraPerfilCampo(
                  avatar: const SizedBox(width: 88, height: 88),
                  nombre: 'Rodrigo',
                  insignia: const InsigniaCabeceraCampo(
                    icono: Icons.check,
                    etiqueta: 'Aprobado',
                  ),
                  accion: MenuPerfilCampo(
                    alAjustes: () {},
                    alApariencia: () {},
                    alSalir: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final icono = tester.getRect(find.byIcon(Icons.more_vert_rounded));
      final insignia = tester.getRect(find.byType(InsigniaCabeceraCampo));
      expect(393 - icono.right, moreOrLessEquals(insignia.left));
    },
  );

  testWidgets(
    'el texto y el ícono de la insignia quedan centrados en vertical',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
          home: const Scaffold(
            body: Center(
              child: InsigniaCabeceraCampo(
                icono: Icons.verified_rounded,
                etiqueta: 'Aprobado',
                intensa: true,
              ),
            ),
          ),
        ),
      );
      final pildora = tester.getRect(find.byType(InsigniaCabeceraCampo));
      final icono = tester.getRect(find.byIcon(Icons.verified_rounded));
      final texto = tester.getRect(find.text('Aprobado'));
      expect(
        icono.center.dy,
        moreOrLessEquals(pildora.center.dy, epsilon: 0.5),
      );
      expect(
        texto.center.dy,
        moreOrLessEquals(pildora.center.dy, epsilon: 0.5),
      );
    },
  );
}
