import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/conectividad/data/conectividad_falsa.dart';
import 'package:agrocom_field/nucleo/conectividad/domain/conectividad_servicio.dart';
import 'package:agrocom_field/nucleo/conectividad/presentation/con_banner_de_red.dart';
import 'package:agrocom_field/nucleo/conectividad/presentation/conectividad_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _montar(ConectividadFalsa servicio) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('es'),
  home: Scaffold(
    body: ConBannerDeRed(servicio: servicio, child: const Text('contenido')),
  ),
);

void main() {
  test('el cubit toma la lectura inicial y sigue los cambios', () async {
    final servicio = ConectividadFalsa(inicial: EstadoRed.sinRed);
    final cubit = ConectividadCubit(servicio);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, EstadoRed.sinRed);
    servicio.fijar(EstadoRed.conRed);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, EstadoRed.conRed);
    await cubit.close();
    await servicio.cerrar();
  });

  testWidgets('muestra «Sin señal» sin red y lo quita al volver', (
    tester,
  ) async {
    final servicio = ConectividadFalsa(inicial: EstadoRed.sinRed);
    addTearDown(servicio.cerrar);
    await tester.pumpWidget(_montar(servicio));
    await tester.pump();
    expect(find.textContaining('Sin señal'), findsOneWidget);
    expect(find.text('contenido'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Sin señal\\.')), findsOneWidget);

    servicio.fijar(EstadoRed.conRed);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Sin señal'), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('con red no muestra el banner', (tester) async {
    final servicio = ConectividadFalsa();
    addTearDown(servicio.cerrar);
    await tester.pumpWidget(_montar(servicio));
    await tester.pump();
    expect(find.textContaining('Sin señal'), findsNothing);
  });
}
