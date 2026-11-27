import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/menu_acciones_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(appBar: AppBar(actions: [child])),
  );
}

void main() {
  testWidgets('abre el menú y elige una acción', (tester) async {
    var elegido = 0;
    await tester.pumpWidget(
      _envolver(
        MenuAccionesCampo(
          acciones: [
            AccionMenuCampo(
              texto: 'Reportar',
              icono: Icons.flag_outlined,
              onElegir: () => elegido++,
            ),
            const AccionMenuCampo(
              texto: 'Deshabilitada',
              icono: Icons.block,
              onElegir: null,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(MenuAccionesCampo));
    await tester.pumpAndSettle();
    expect(find.text('Reportar'), findsOneWidget);
    expect(find.text('Deshabilitada'), findsOneWidget);

    await tester.tap(find.text('Reportar'));
    await tester.pumpAndSettle();
    expect(elegido, 1);
  });

  testWidgets('una acción destructiva no se puede tocar si onElegir es null', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        MenuAccionesCampo(
          acciones: const [
            AccionMenuCampo(
              texto: 'Eliminar',
              icono: Icons.delete_outline,
              onElegir: null,
              destructiva: true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(MenuAccionesCampo));
    await tester.pumpAndSettle();
    final item = tester.widget<PopupMenuItem<AccionMenuCampo>>(
      find.byType(PopupMenuItem<AccionMenuCampo>),
    );
    expect(item.enabled, isFalse);
  });
}
