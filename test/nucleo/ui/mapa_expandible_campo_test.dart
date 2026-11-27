import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_expandible_campo.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _lote = Lote(
  id: 'lote-1',
  nombre: 'La Nena',
  zona: 'Cuatro Cañadas',
  cultivo: 'Soja',
  hectareas: Decimal.parse('42.5'),
  poligono: const [
    GeoPunto(-17.70, -63.10),
    GeoPunto(-17.70, -63.08),
    GeoPunto(-17.72, -63.08),
    GeoPunto(-17.72, -63.10),
  ],
);

void main() {
  setUp(() => ConfiguracionMapa.teselas = false);

  testWidgets(
    'tocar la miniatura abre el mapa a pantalla completa con controles',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MapaExpandibleCampo(lotes: [_lote])),
        ),
      );

      expect(find.byType(MapaLote), findsOneWidget);

      await tester.tap(find.byType(MapaExpandibleCampo));
      await tester.pumpAndSettle();

      // Ahora hay dos `MapaLote`: la miniatura (debajo) y el mapa de la
      // pantalla completa recién apilada.
      expect(find.byType(MapaLote), findsWidgets);
      expect(find.byTooltip('Cerrar el mapa'), findsOneWidget);
      expect(find.byTooltip('Acercar'), findsOneWidget);
      expect(find.byTooltip('Alejar'), findsOneWidget);
      expect(find.byTooltip('Centrar en el lote'), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar el mapa'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Cerrar el mapa'), findsNothing);
    },
  );
}
