import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/cliente/ofertas/domain/oferta_recibida.dart';
import 'package:agrocom_field/cliente/ofertas/presentation/perfil_proveedor_pantalla.dart';
import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';

OfertaRecibida _oferta({bool conDron = true}) => OfertaRecibida(
  id: 'of-1',
  solicitudId: '31',
  numero: 1,
  autor: AutorOferta.proveedor,
  precioHa: Decimal.parse('64'),
  montoEstimado: Decimal.parse('7680'),
  estado: EstadoOferta.vigente,
  proveedor: ProveedorOfertante(
    id: 'p1',
    nombre: 'Marcelo Rojas',
    calificacion: 4.9,
    calificaciones: 64,
    tasaCancelacion: 0.02,
    marcaDron: conDron ? 'DJI' : null,
    modeloDron: conDron ? 'Agras T50' : null,
    anioDron: conDron ? 2023 : null,
    capacidadLitros: conDron ? Decimal.parse('40') : null,
  ),
);

Future<bool?> _abrir(
  WidgetTester tester,
  OfertaRecibida o, {
  bool puedeElegir = true,
}) async {
  bool? resultado;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              resultado = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => PerfilProveedorPantalla(
                    oferta: o,
                    nombreLote: 'El Tajibo Norte',
                    puedeElegir: puedeElegir,
                  ),
                ),
              ),
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

void main() {
  testWidgets('muestra solo lo que trae el contrato y Elegir devuelve true', (
    tester,
  ) async {
    await _abrir(tester, _oferta());
    expect(find.text('Oferta para El Tajibo Norte'), findsOneWidget);
    expect(find.text('Marcelo Rojas'), findsOneWidget);
    expect(find.text('4,9'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
    expect(find.text('2 %'), findsOneWidget);
    expect(find.text('DJI Agras T50 · 40 L'), findsOneWidget);
    expect(find.text('Año 2023'), findsOneWidget);
    // Lo que el contrato no ofrece no se inventa.
    expect(find.text('Licencia verificada'), findsNothing);
    expect(find.textContaining('RESEÑAS'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('perfil-publico-elegir')));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('sin vigencia no ofrece Elegir; sin dron lo dice', (
    tester,
  ) async {
    await _abrir(tester, _oferta(conDron: false), puedeElegir: false);
    expect(find.byKey(const ValueKey('perfil-publico-elegir')), findsNothing);
    expect(find.text('Este piloto aún no muestra su dron.'), findsOneWidget);
  });
}
