// Identidad de cada app: el encabezado de marca («DronAgro» con el distintivo
// «Piloto» o «Cliente») y la lista «Qué puedes hacer como …» por flavor.

import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(
  Widget child, {
  ModoVisualCampo modo = ModoVisualCampo.oscuro,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    theme: AgrocomThemeCampo.construir(modo: modo),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('EncabezadoDeMarca', () {
    testWidgets('el piloto muestra «DronAgro» con el distintivo «Piloto»', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        _envolver(const EncabezadoDeMarca(rol: RolApp.piloto)),
      );
      expect(find.text('DronAgro'), findsOneWidget);
      expect(find.text('Piloto'), findsOneWidget);
      expect(find.text('Cliente'), findsNothing);
      expect(find.bySemanticsLabel('DronAgro, app para pilotos'), findsOne);
      semantica.dispose();
    });

    testWidgets('el cliente muestra «DronAgro» con el distintivo «Cliente»', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        _envolver(
          const EncabezadoDeMarca(rol: RolApp.cliente),
          modo: ModoVisualCampo.claro,
        ),
      );
      expect(find.text('DronAgro'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Piloto'), findsNothing);
      expect(find.bySemanticsLabel('DronAgro, app para clientes'), findsOne);
      semantica.dispose();
    });

    testWidgets('el ícono de cada rol es distinto', (tester) async {
      expect(RolApp.piloto.icono, IconoAgrocomId.piloto);
      expect(RolApp.cliente.icono, isNot(RolApp.piloto.icono));
    });

    testWidgets('compacto y sobre foto no desbordan con texto al 200 %', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _envolver(
            const Column(
              children: [
                EncabezadoDeMarca(rol: RolApp.piloto, compacto: true),
                EncabezadoDeMarca(rol: RolApp.cliente, sobreFoto: true),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('DistintivoRol', () {
    testWidgets('lleva texto e ícono, no solo color', (tester) async {
      await tester.pumpWidget(
        _envolver(const DistintivoRol(rol: RolApp.piloto)),
      );
      expect(find.text('Piloto'), findsOneWidget);
      expect(find.byType(IconoAgrocom), findsOneWidget);
    });
  });

  group('ListaDeCapacidades', () {
    testWidgets('piloto: título y cinco capacidades de piloto', (tester) async {
      await tester.pumpWidget(
        _envolver(const ListaDeCapacidades(rol: RolApp.piloto)),
      );
      expect(find.text('Qué puedes hacer como piloto'), findsOneWidget);
      expect(find.text('Qué puedes hacer como cliente'), findsNothing);
      expect(find.textContaining('solicitudes abiertas'), findsOneWidget);
      expect(find.textContaining('precio por hectárea con tu dron'), findsOne);
      expect(find.textContaining('sin señal'), findsOneWidget);
      expect(find.textContaining('inicio, el avance y el cierre'), findsOne);
      expect(find.textContaining('calificaciones que recibes'), findsOne);
    });

    testWidgets('cliente: título y cinco capacidades de cliente', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(
          const ListaDeCapacidades(rol: RolApp.cliente),
          modo: ModoVisualCampo.claro,
        ),
      );
      expect(find.text('Qué puedes hacer como cliente'), findsOneWidget);
      expect(find.text('Qué puedes hacer como piloto'), findsNothing);
      expect(find.textContaining('Publica una solicitud'), findsOneWidget);
      expect(find.textContaining('Compara las ofertas'), findsOneWidget);
      expect(find.textContaining('contraoferta o acepta'), findsOneWidget);
      expect(find.textContaining('fotos, avance y chat'), findsOneWidget);
      expect(find.textContaining('Califica al piloto'), findsOneWidget);
    });

    testWidgets('el título es un encabezado semántico', (tester) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        _envolver(const ListaDeCapacidades(rol: RolApp.piloto)),
      );
      expect(
        tester.getSemantics(find.text('Qué puedes hacer como piloto')),
        matchesSemantics(label: 'Qué puedes hacer como piloto', isHeader: true),
      );
      semantica.dispose();
    });

    testWidgets('cada rol tiene entre tres y cinco capacidades', (
      tester,
    ) async {
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
      for (final rol in RolApp.values) {
        expect(capacidadesDeRol(rol, l10n).length, inInclusiveRange(3, 5));
      }
    });
  });
}
