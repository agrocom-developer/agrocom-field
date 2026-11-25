// Componentes de marketplace del sistema visual: comportamiento y golden
// tests (oferta entrante, calificación, esqueleto) en modo claro y campo.
//
// Los golden se regeneran con `flutter test --update-goldens`; solo se
// versionan los de este archivo (test/nucleo/ui/goldens/).

import 'dart:io' show Platform;

import 'package:agrocom_field/nucleo/ui/componentes/componentes_campo.dart';
import 'package:agrocom_field/nucleo/ui/paleta_campo.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// El render de texto difiere entre macOS y Linux: los golden de referencia
/// se generan en macOS y en CI (Linux) se omiten en vez de dar falsos rojos.
final String? _saltarGolden = Platform.isMacOS
    ? null
    : 'golden de referencia generado en macOS';

Widget _envolver(Widget child, {ModoVisualCampo modo = ModoVisualCampo.claro}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AgrocomThemeCampo.construir(modo: modo),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
      child: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

OfertaServicioCampo _oferta({
  Duration restante = const Duration(seconds: 47),
  VoidCallback? onAceptar,
  VoidCallback? onRechazar,
}) {
  return OfertaServicioCampo(
    titulo: 'Soja · 42 ha',
    detalle: 'Lote 14, a 12 km de tu base',
    distancia: '12 km',
    monto: 'Bs 3.150',
    restante: restante,
    total: const Duration(seconds: 90),
    onAceptar: onAceptar ?? () {},
    onRechazar: onRechazar ?? () {},
  );
}

Future<void> _cargarFuente(String familia, String ruta) async {
  final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
  await cargador.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sin esto `flutter test` pinta todo el texto con la fuente de bloques
  // Ahem y el golden no dice nada de la tipografía.
  setUpAll(() async {
    await _cargarFuente('Manrope', 'assets/fonts/Manrope.ttf');
    await _cargarFuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
    await _cargarFuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  });

  group('OfertaServicioCampo', () {
    testWidgets('muestra pago, tiempo y dispara aceptar y rechazar', (
      tester,
    ) async {
      var aceptada = false;
      var rechazada = false;
      await tester.pumpWidget(
        _envolver(
          SingleChildScrollView(
            child: _oferta(
              onAceptar: () => aceptada = true,
              onRechazar: () => rechazada = true,
            ),
          ),
        ),
      );
      expect(find.text('Bs 3.150'), findsOneWidget);
      expect(find.text('00:47'), findsOneWidget);

      await tester.tap(find.text('Aceptar servicio'));
      await tester.tap(find.text('Rechazar'));
      expect(aceptada, isTrue);
      expect(rechazada, isTrue);
    });

    testWidgets('anuncia la oferta completa a los lectores de pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(SingleChildScrollView(child: _oferta())),
      );
      expect(
        find.bySemanticsLabel(RegExp('Oferta de servicio: Soja · 42 ha')),
        findsOneWidget,
      );
    });

    testWidgets('el botón de aceptar mide al menos 56 px (guantes)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(SingleChildScrollView(child: _oferta())),
      );
      final tamano = tester.getSize(
        find.widgetWithText(FilledButton, 'Aceptar servicio'),
      );
      expect(tamano.height, greaterThanOrEqualTo(56));
    });

    testWidgets('golden claro', skip: _saltarGolden != null, (tester) async {
      await tester.pumpWidget(
        _envolver(SingleChildScrollView(child: _oferta())),
      );
      await expectLater(
        find.byType(OfertaServicioCampo),
        matchesGoldenFile('../goldens/oferta_servicio_claro.png'),
      );
    });

    testWidgets('golden campo', skip: _saltarGolden != null, (tester) async {
      await tester.pumpWidget(
        _envolver(
          SingleChildScrollView(child: _oferta()),
          modo: ModoVisualCampo.campo,
        ),
      );
      await expectLater(
        find.byType(OfertaServicioCampo),
        matchesGoldenFile('../goldens/oferta_servicio_campo.png'),
      );
    });
  });

  group('CalificacionCampo', () {
    testWidgets('interactiva: toca la tercera estrella y notifica 3', (
      tester,
    ) async {
      int? elegido;
      await tester.pumpWidget(
        _envolver(CalificacionCampo(valor: 1, onCambio: (v) => elegido = v)),
      );
      await tester.tap(find.bySemanticsLabel('3 estrellas'));
      expect(elegido, 3);
    });

    testWidgets('solo lectura: anuncia el valor y no es tocable', (
      tester,
    ) async {
      await tester.pumpWidget(_envolver(const CalificacionCampo(valor: 4)));
      expect(find.bySemanticsLabel('Calificación: 4 de 5'), findsOneWidget);
      expect(find.byType(InkResponse), findsNothing);
    });

    testWidgets('golden claro', skip: _saltarGolden != null, (tester) async {
      await tester.pumpWidget(
        _envolver(Center(child: CalificacionCampo(valor: 4, onCambio: (_) {}))),
      );
      await expectLater(
        find.byType(CalificacionCampo),
        matchesGoldenFile('../goldens/calificacion_claro.png'),
      );
    });
  });

  group('EsqueletoCampo', () {
    testWidgets('con movimiento reducido queda estático', (tester) async {
      await tester.pumpWidget(
        _envolver(const EsqueletoCampo(ancho: 120, alto: 16)),
      );
      // pumpAndSettle termina: no hay animación en curso.
      await tester.pumpAndSettle();
      expect(find.byType(EsqueletoCampo), findsOneWidget);
    });

    testWidgets('golden oscuro', skip: _saltarGolden != null, (tester) async {
      await tester.pumpWidget(
        _envolver(
          Row(
            children: [
              const EsqueletoCampo(ancho: 48, alto: 48, radio: 24),
              const SizedBox(width: 12),
              Expanded(child: EsqueletoCampo.texto(lineas: 3)),
            ],
          ),
          modo: ModoVisualCampo.oscuro,
        ),
      );
      await expectLater(
        find.byType(Row).first,
        matchesGoldenFile('../goldens/esqueleto_oscuro.png'),
      );
    });
  });

  group('NavegacionAdaptativaCampo', () {
    const destinos = [
      DestinoCampo(
        icono: Icons.home_outlined,
        iconoActivo: Icons.home,
        etiqueta: 'Inicio',
      ),
      DestinoCampo(
        icono: Icons.list_alt_outlined,
        iconoActivo: Icons.list_alt,
        etiqueta: 'Servicios',
      ),
    ];

    Future<void> montar(WidgetTester tester, Size tamano) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AgrocomThemeCampo.construir(modo: ModoVisualCampo.claro),
          home: NavegacionAdaptativaCampo(
            destinos: destinos,
            indice: 0,
            onSeleccionar: (_) {},
            cuerpo: const Text('contenido'),
          ),
        ),
      );
    }

    testWidgets('teléfono: barra inferior', (tester) async {
      await montar(tester, const Size(390, 844));
      expect(find.byType(BarraInferiorCampo), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('iPad: riel lateral', (tester) async {
      await montar(tester, const Size(834, 1194));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BarraInferiorCampo), findsNothing);
    });
  });
}
