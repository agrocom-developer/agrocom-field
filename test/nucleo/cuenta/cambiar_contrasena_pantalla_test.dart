import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/cuenta/data/contrasena_demo.dart';
import 'package:agrocom_field/nucleo/cuenta/domain/contrasena_repositorio.dart';
import 'package:agrocom_field/nucleo/cuenta/presentation/cambiar_contrasena_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/ajustes/ajustes_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ContrasenaDemo> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = ContrasenaDemo(latencia: const Duration(milliseconds: 10));
  await tester.pumpWidget(
    RepositoryProvider<ContrasenaRepositorio>.value(
      value: repo,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CambiarContrasenaPantalla(),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _alCodigo(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('contrasena-enviar-codigo')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ofrece los tres canales y pide el código por el elegido', (
    tester,
  ) async {
    await _abrir(tester);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Mensaje de texto'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    await tester.tap(find.byKey(const Key('contrasena-canal-correo')));
    await tester.pump();
    await _alCodigo(tester);
    expect(find.text('Escribe el código'), findsOneWidget);
    expect(find.text('Lo enviamos a h••••@agrocom.demo.'), findsOneWidget);
  });

  testWidgets('un canal sin destino avisa qué hacer y se queda en el paso', (
    tester,
  ) async {
    await _abrir(tester);
    await tester.tap(find.byKey(const Key('contrasena-canal-sms')));
    await tester.pump();
    await _alCodigo(tester);
    expect(find.byKey(const Key('contrasena-aviso')), findsOneWidget);
    expect(find.textContaining('Elige otro medio'), findsOneWidget);
    expect(find.text('¿Dónde te enviamos el código?'), findsOneWidget);
  });

  testWidgets('valida el código y la contraseña antes de enviar', (
    tester,
  ) async {
    await _abrir(tester);
    await _alCodigo(tester);
    await tester.enterText(find.byKey(const Key('contrasena-codigo')), '123');
    await tester.enterText(find.byKey(const Key('contrasena-nueva')), 'abc');
    await tester.enterText(find.byKey(const Key('contrasena-repetir')), 'abd');
    await tester.tap(find.byKey(const Key('contrasena-guardar')));
    await tester.pumpAndSettle();
    expect(find.text('El código tiene 6 números.'), findsOneWidget);
    expect(find.text('Usa al menos 4 caracteres.'), findsWidgets);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });

  testWidgets('el código incorrecto se marca junto al campo', (tester) async {
    await _abrir(tester);
    await _alCodigo(tester);
    await tester.enterText(
      find.byKey(const Key('contrasena-codigo')),
      '000000',
    );
    await tester.enterText(find.byKey(const Key('contrasena-nueva')), 'nueva1');
    await tester.enterText(
      find.byKey(const Key('contrasena-repetir')),
      'nueva1',
    );
    await tester.tap(find.byKey(const Key('contrasena-guardar')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pide uno nuevo'), findsWidgets);
    expect(find.text('Escribe el código'), findsOneWidget);
  });

  testWidgets('el flujo completo confirma y vuelve a Ajustes', (tester) async {
    final repo = await _abrir(tester);
    await _alCodigo(tester);
    await tester.enterText(
      find.byKey(const Key('contrasena-codigo')),
      '482913',
    );
    await tester.enterText(find.byKey(const Key('contrasena-nueva')), 'nueva1');
    await tester.enterText(
      find.byKey(const Key('contrasena-repetir')),
      'nueva1',
    );
    await tester.tap(find.byKey(const Key('contrasena-guardar')));
    await tester.pumpAndSettle();
    expect(repo.ultimaContrasena, 'nueva1');
    expect(find.text('Listo, cambiamos tu contraseña'), findsOneWidget);
    await tester.tap(find.byKey(const Key('contrasena-volver')));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('los campos de contraseña ocultan lo escrito y piden autofill', (
    tester,
  ) async {
    await _abrir(tester);
    await _alCodigo(tester);
    final campos = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(campos[1].obscureText, isTrue);
    expect(campos[2].obscureText, isTrue);
    expect(campos[1].autofillHints, contains(AutofillHints.newPassword));
  });

  group('fila en Ajustes', () {
    Widget ajustes({required bool conRepositorio}) {
      final app = MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
        home: const AjustesPantalla(),
      );
      return conRepositorio
          ? RepositoryProvider<ContrasenaRepositorio>.value(
              value: ContrasenaDemo(latencia: Duration.zero),
              child: app,
            )
          : app;
    }

    testWidgets('con repositorio, abre el cambio de contraseña', (
      tester,
    ) async {
      await tester.pumpWidget(ajustes(conRepositorio: true));
      await tester.tap(find.byKey(const Key('ajustes-cambiar-contrasena')));
      await tester.pumpAndSettle();
      expect(find.text('¿Dónde te enviamos el código?'), findsOneWidget);
    });

    testWidgets('sin repositorio, la fila no aparece', (tester) async {
      await tester.pumpWidget(ajustes(conRepositorio: false));
      expect(find.byKey(const Key('ajustes-cambiar-contrasena')), findsNothing);
    });
  });
}
