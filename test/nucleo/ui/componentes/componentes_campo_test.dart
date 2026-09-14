// Catálogo de componentes del modo "campo" (ADR 0008) — smoke test de cada
// widget montado bajo `AgrocomThemeCampo.construir()`, más el comportamiento
// interactivo de los que lo tienen (selector segmentado, grid de evidencias).

import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget child) {
  return MaterialApp(
    theme: AgrocomThemeCampo.construir(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('BotonPrimarioCampo muestra el texto y dispara onPressed', (
    tester,
  ) async {
    var presionado = false;
    await tester.pumpWidget(
      _envolver(
        BotonPrimarioCampo(
          texto: 'Comenzar',
          onPressed: () => presionado = true,
        ),
      ),
    );

    expect(find.text('Comenzar'), findsOneWidget);
    await tester.tap(find.text('Comenzar'));
    expect(presionado, isTrue);
  });

  testWidgets(
    'BotonPrimarioCampo cargando muestra spinner y deshabilita el tap',
    (tester) async {
      var presionado = false;
      await tester.pumpWidget(
        _envolver(
          BotonPrimarioCampo(
            texto: 'Comenzar',
            cargando: true,
            onPressed: () => presionado = true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(
        find.byType(CircularProgressIndicator),
        warnIfMissed: false,
      );
      expect(presionado, isFalse);
    },
  );

  testWidgets('BotonSecundarioCampo muestra el texto', (tester) async {
    await tester.pumpWidget(
      _envolver(
        BotonSecundarioCampo(texto: 'Volver a medir', onPressed: () {}),
      ),
    );

    expect(find.text('Volver a medir'), findsOneWidget);
  });

  testWidgets('TarjetaCampo renderiza su contenido', (tester) async {
    await tester.pumpWidget(
      _envolver(const TarjetaCampo(child: Text('contenido'))),
    );

    expect(find.text('contenido'), findsOneWidget);
  });

  testWidgets('StatChipCampo muestra etiqueta, valor, unidad y nota', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        const StatChipCampo(
          etiqueta: 'Viento',
          valor: '9',
          unidad: 'km/h',
          notaAlerta: 'Ráfagas 21',
        ),
      ),
    );

    expect(find.text('VIENTO'), findsOneWidget);
    expect(find.text('Ráfagas 21'), findsOneWidget);
  });

  testWidgets('BadgeEstadoCampo muestra el texto en mayúscula', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const BadgeEstadoCampo(
          texto: 'pend',
          estado: EstadoBadgeCampo.pendiente,
        ),
      ),
    );

    expect(find.text('PEND'), findsOneWidget);
  });

  testWidgets('SelectorSegmentadoCampo cambia la selección al tocar', (
    tester,
  ) async {
    String seleccionado = 'liquido';
    await tester.pumpWidget(
      _envolver(
        StatefulBuilder(
          builder: (context, setState) => SelectorSegmentadoCampo<String>(
            opciones: const [('liquido', 'Líquido'), ('solido', 'Sólido')],
            seleccionado: seleccionado,
            onSeleccionar: (valor) => setState(() => seleccionado = valor),
          ),
        ),
      ),
    );

    expect(seleccionado, 'liquido');
    await tester.tap(find.text('Sólido'));
    await tester.pump();
    expect(seleccionado, 'solido');
  });

  testWidgets('BarraProgresoCampo no explota con fracción fuera de rango', (
    tester,
  ) async {
    await tester.pumpWidget(_envolver(const BarraProgresoCampo(fraccion: 1.4)));
    expect(find.byType(BarraProgresoCampo), findsOneWidget);
  });

  testWidgets('ItemListaCampo muestra título, subtítulo, valor e iniciales', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        const ItemListaCampo(
          titulo: 'Glifosato',
          subtitulo: 'herbicida',
          valor: '3,0 L',
          iniciales: 'GLI',
        ),
      ),
    );

    expect(find.text('Glifosato'), findsOneWidget);
    expect(find.text('herbicida'), findsOneWidget);
    expect(find.text('3,0 L'), findsOneWidget);
    expect(find.text('GLI'), findsOneWidget);
  });

  testWidgets('BotonAgregarPunteadoCampo dispara onPressed', (tester) async {
    var presionado = false;
    await tester.pumpWidget(
      _envolver(
        BotonAgregarPunteadoCampo(
          texto: 'Agregar producto',
          onPressed: () => presionado = true,
        ),
      ),
    );

    await tester.tap(find.text('Agregar producto'));
    expect(presionado, isTrue);
  });

  testWidgets('BannerAlertaCampo muestra texto y valor', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const BannerAlertaCampo(
          texto: 'SIN CONEXIÓN · LOTE',
          valor: '4 pendientes ↑',
        ),
      ),
    );

    expect(find.text('SIN CONEXIÓN · LOTE'), findsOneWidget);
    expect(find.text('4 pendientes ↑'), findsOneWidget);
  });

  testWidgets('NotaTecnicaCampo muestra el texto', (tester) async {
    await tester.pumpWidget(
      _envolver(
        const NotaTecnicaCampo(
          texto: 'registro_mezcla · pendiente · se sube junto a la aplicación',
        ),
      ),
    );

    expect(find.textContaining('registro_mezcla'), findsOneWidget);
  });

  testWidgets('EncabezadoCampo muestra título, subtítulo y vuelve atrás', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AgrocomThemeCampo.construir(),
        home: Scaffold(
          appBar: const EncabezadoCampo(
            titulo: 'Mezcla del caldo',
            subtitulo: 'Tanque 600 L · vuelo 1 de 6',
          ),
          body: Builder(
            builder: (context) => Center(
              child: BotonPrimarioCampo(
                texto: 'Abrir',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      appBar: EncabezadoCampo(titulo: 'Detalle'),
                      body: SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mezcla del caldo'), findsOneWidget);
    expect(find.text('Tanque 600 L · vuelo 1 de 6'), findsOneWidget);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Mezcla del caldo'), findsOneWidget);
  });

  testWidgets('BarraNavegacionCampo marca el ítem activo y dispara acciones', (
    tester,
  ) async {
    var indiceSeleccionado = -1;
    var accionCentralDisparada = false;

    await tester.pumpWidget(
      _envolver(
        BarraNavegacionCampo(
          items: const [
            ItemBarraNavegacionCampo(icono: Icons.home, etiqueta: 'Inicio'),
            ItemBarraNavegacionCampo(icono: Icons.list, etiqueta: 'Órdenes'),
            ItemBarraNavegacionCampo(icono: Icons.hub, etiqueta: 'Equipos'),
            ItemBarraNavegacionCampo(
              icono: Icons.sync,
              etiqueta: 'Sync',
              insignia: 4,
            ),
          ],
          indiceActivo: 0,
          onSeleccionar: (indice) => indiceSeleccionado = indice,
          onAccionCentral: () => accionCentralDisparada = true,
        ),
      ),
    );

    expect(find.textContaining('Sync 4'), findsOneWidget);

    await tester.tap(find.text('Órdenes'));
    expect(indiceSeleccionado, 1);

    await tester.tap(find.byIcon(Icons.add));
    expect(accionCentralDisparada, isTrue);
  });

  testWidgets(
    'GridEvidenciasCampo muestra slots pendientes y dispara onAgregar',
    (tester) async {
      int? indiceAgregado;
      await tester.pumpWidget(
        _envolver(
          SizedBox(
            width: 360,
            child: GridEvidenciasCampo(
              celdas: const [
                CeldaEvidenciaCampo(etiqueta: 'foto de control'),
                CeldaEvidenciaCampo(etiqueta: 'ciclo de batería'),
              ],
              onAgregar: (indice) => indiceAgregado = indice,
            ),
          ),
        ),
      );

      expect(find.text('foto de control'), findsOneWidget);
      await tester.tap(find.text('ciclo de batería'));
      expect(indiceAgregado, 1);
    },
  );
}
