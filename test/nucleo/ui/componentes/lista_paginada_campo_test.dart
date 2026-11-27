import 'package:agrocom_field/l10n/app_localizations.dart';
import 'package:agrocom_field/nucleo/ui/componentes/esqueleto_variantes_campo.dart';
import 'package:agrocom_field/nucleo/ui/componentes/lista_paginada_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

ListaPaginadaCampo<String> _lista({
  required EstadoListaPaginadaCampo<String> estado,
  Future<void> Function()? onRefrescar,
  VoidCallback? onCargarMas,
}) {
  return ListaPaginadaCampo<String>(
    estado: estado,
    constructorItem: (context, item, indice) => ListTile(title: Text(item)),
    onRefrescar: onRefrescar ?? () async {},
    onCargarMas: onCargarMas,
  );
}

void main() {
  testWidgets('carga inicial muestra tres esqueletos de fila', (tester) async {
    await tester.pumpWidget(
      _envolver(
        _lista(estado: const EstadoListaPaginadaCampo(cargandoInicial: true)),
      ),
    );
    expect(find.byType(EsqueletoFilaListaCampo), findsNWidgets(3));
  });

  testWidgets('vacía muestra el estado vacío por defecto', (tester) async {
    await tester.pumpWidget(
      _envolver(_lista(estado: const EstadoListaPaginadaCampo())),
    );
    expect(find.text('Todavía no hay nada para mostrar aquí.'), findsOneWidget);
  });

  testWidgets('error inicial muestra el mensaje y reintenta al tocar', (
    tester,
  ) async {
    var reintentos = 0;
    await tester.pumpWidget(
      _envolver(
        _lista(
          estado: const EstadoListaPaginadaCampo(
            errorInicial: 'No se pudo cargar la lista',
          ),
          onRefrescar: () async {
            reintentos++;
          },
        ),
      ),
    );
    expect(find.text('No se pudo cargar la lista'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(reintentos, 1);
  });

  testWidgets('sin red con la lista vacía ofrece reintentar', (tester) async {
    await tester.pumpWidget(
      _envolver(_lista(estado: const EstadoListaPaginadaCampo(sinRed: true))),
    );
    expect(
      find.text('Sin conexión. Conéctate para ver esta lista.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('con ítems y sin más páginas muestra el fin de la lista', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        _lista(
          estado: const EstadoListaPaginadaCampo(
            items: ['Oferta 1', 'Oferta 2'],
            hayMasPaginas: false,
          ),
        ),
      ),
    );
    expect(find.text('Oferta 1'), findsOneWidget);
    expect(find.text('Oferta 2'), findsOneWidget);
    expect(find.text('No hay más resultados'), findsOneWidget);
  });

  testWidgets('cargando la página siguiente muestra un esqueleto al pie', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        _lista(
          estado: const EstadoListaPaginadaCampo(
            items: ['Oferta 1'],
            cargandoMas: true,
          ),
        ),
      ),
    );
    expect(find.byType(EsqueletoFilaListaCampo), findsOneWidget);
  });

  testWidgets('error de página ofrece reintentar sin perder los ítems', (
    tester,
  ) async {
    var cargasMas = 0;
    await tester.pumpWidget(
      _envolver(
        _lista(
          estado: const EstadoListaPaginadaCampo(
            items: ['Oferta 1'],
            errorPagina: 'No se pudo cargar la página',
          ),
          onCargarMas: () => cargasMas++,
        ),
      ),
    );
    expect(find.text('Oferta 1'), findsOneWidget);
    expect(find.text('No se pudo cargar la página'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(cargasMas, 1);
  });

  testWidgets('con ítems, el pull-to-refresh está disponible', (tester) async {
    await tester.pumpWidget(
      _envolver(
        _lista(estado: const EstadoListaPaginadaCampo(items: ['Oferta 1'])),
      ),
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
