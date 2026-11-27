import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/data/bandeja_demo.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/domain/bandeja_repositorio.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/domain/notificacion.dart';
import 'package:agrocom_field/nucleo/notificaciones/bandeja/presentation/bandeja_notificaciones_pantalla.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Vacia implements BandejaRepositorio {
  @override
  Future<List<Notificacion>> listar() async => const [];

  @override
  Future<void> marcarLeida(int id) async {}

  @override
  Future<void> marcarTodasLeidas() async {}
}

Future<void> _abrir(WidgetTester tester, BandejaRepositorio repo) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepositoryProvider<BandejaRepositorio>.value(
      value: repo,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
        home: const BandejaNotificacionesPantalla(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('agrupa por día, marca las no leídas y filtra', (tester) async {
    await _abrir(tester, BandejaDemo(latencia: Duration.zero));
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);
    expect(find.text('Tu solicitud recibió 3 ofertas'), findsOneWidget);
    expect(find.byKey(const Key('bandeja-punto-1')), findsOneWidget);
    expect(find.byKey(const Key('bandeja-punto-3')), findsNothing);

    await tester.tap(find.byKey(const Key('bandeja-filtro-mensajes')));
    await tester.pumpAndSettle();
    expect(find.text('Tu solicitud recibió 3 ofertas'), findsNothing);
    expect(find.text('Rosario Antelo'), findsOneWidget);
  });

  testWidgets('abrir un aviso le quita el punto de no leído', (tester) async {
    await _abrir(tester, BandejaDemo(latencia: Duration.zero));
    await tester.tap(find.byKey(const Key('bandeja-aviso-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bandeja-punto-1')), findsNothing);
  });

  testWidgets('marcar todas quita todos los puntos y el botón', (tester) async {
    await _abrir(tester, BandejaDemo(latencia: Duration.zero));
    await tester.tap(find.byKey(const Key('bandeja-marcar-todas')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bandeja-punto-1')), findsNothing);
    expect(find.byKey(const Key('bandeja-punto-2')), findsNothing);
    expect(find.byKey(const Key('bandeja-marcar-todas')), findsNothing);
  });

  testWidgets('sin avisos orienta en vez de quedar vacía', (tester) async {
    await _abrir(tester, _Vacia());
    expect(find.text('Aquí te avisamos lo importante'), findsOneWidget);
  });
}
