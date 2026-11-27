import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/tarjeta_notificacion_campo.dart';
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
  testWidgets('muestra título, cuerpo y cuándo llegó', (tester) async {
    await tester.pumpWidget(
      _envolver(
        TarjetaNotificacionCampo(
          canal: CanalNotificacionCampo.ofertas,
          titulo: 'Nueva oferta por tu solicitud',
          cuerpo: 'Un piloto ofertó Bs 120 por hectárea',
          cuando: 'Hace 5 min',
        ),
      ),
    );
    expect(find.text('Nueva oferta por tu solicitud'), findsOneWidget);
    expect(find.text('Un piloto ofertó Bs 120 por hectárea'), findsOneWidget);
    expect(find.text('Hace 5 min'), findsOneWidget);
    expect(find.byIcon(Icons.local_offer_rounded), findsOneWidget);
  });

  testWidgets('no leída muestra el punto de aviso', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const TarjetaNotificacionCampo(
          canal: CanalNotificacionCampo.servicio,
          titulo: 'El piloto llegó al lote',
          cuerpo: 'Empezó la fumigación',
          cuando: 'Hace 2 min',
          leida: false,
        ),
      ),
    );
    expect(find.byIcon(Icons.flight_takeoff_rounded), findsOneWidget);
  });

  testWidgets('el toque dispara onTap', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      _envolver(
        TarjetaNotificacionCampo(
          canal: CanalNotificacionCampo.sistema,
          titulo: 'Agrocom',
          cuerpo: 'Actualiza la app para seguir operando',
          cuando: 'Ayer',
          onTap: () => toques++,
        ),
      ),
    );
    await tester.tap(find.byType(TarjetaNotificacionCampo));
    expect(toques, 1);
  });

  testWidgets('cada canal tiene un nombre propio vía l10n', (tester) async {
    await tester.pumpWidget(
      _envolver(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(CanalNotificacionCampo.sincronizacion.nombre(l10n));
          },
        ),
      ),
    );
    expect(find.text('Sincronización'), findsOneWidget);
  });
}
