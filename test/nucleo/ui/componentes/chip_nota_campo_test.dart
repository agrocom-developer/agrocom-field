import 'package:agrocom_field/nucleo/ui/componentes/chip_nota_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('cada tipo de nota lleva su propio ícono, no solo color', (
    tester,
  ) async {
    const casos = {
      TipoNotaCampo.informacion: Icons.info_outline_rounded,
      TipoNotaCampo.exito: Icons.check_circle_outline_rounded,
      TipoNotaCampo.advertencia: Icons.warning_amber_rounded,
      TipoNotaCampo.error: Icons.error_outline_rounded,
      TipoNotaCampo.soloLectura: Icons.lock_outline_rounded,
    };
    for (final entrada in casos.entries) {
      await tester.pumpWidget(
        _envolver(ChipNotaCampo(texto: 'Aviso', tipo: entrada.key)),
      );
      expect(
        find.byIcon(entrada.value),
        findsOneWidget,
        reason: '${entrada.key}',
      );
    }
  });

  testWidgets('la variante banner muestra la acción a la derecha', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        ChipNotaCampo(
          texto: 'Sin conexión para sincronizar',
          tipo: TipoNotaCampo.advertencia,
          variante: VarianteNotaCampo.banner,
          accion: TextButton(onPressed: () {}, child: const Text('Reintentar')),
        ),
      ),
    );
    expect(find.text('Sin conexión para sincronizar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('solo lectura se lee como un candado, no como una alarma', (
    tester,
  ) async {
    await tester.pumpWidget(
      _envolver(
        const ChipNotaCampo(
          texto: 'Ya se calificó',
          tipo: TipoNotaCampo.soloLectura,
        ),
      ),
    );
    expect(find.text('Ya se calificó'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });
}
