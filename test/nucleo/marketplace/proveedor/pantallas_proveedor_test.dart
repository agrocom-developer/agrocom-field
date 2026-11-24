// Pantallas del proveedor (bandeja de ofertas, detalle, perfil y drones) en
// modo campo: comportamiento, legibilidad con el texto al 200 % y goldens.
//
// Cada combinación de pantalla, tamaño y escala de texto se monta siempre
// (un desborde de layout hace fallar la prueba en cualquier plataforma); la
// comparación contra el golden solo corre en macOS, donde se generan las
// referencias (`flutter test --update-goldens`).

import 'dart:io' show Platform;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/demo/datos_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/di/dependencias_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/dron/domain/drones_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/dron/presentation/drones_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/data/estado_red_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/data/ofertas_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/domain/ofertas_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/presentation/ofertas_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/data/perfil_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/presentation/perfil_pantalla.dart';
import 'package:agrocom_field/nucleo/marketplace/ui/mapa_lote.dart';
import 'package:agrocom_field/nucleo/ui/tema_campo.dart';

final bool _conGoldens = Platform.isMacOS;

const _telefonoChico = Size(360, 640);
const _telefonoGrande = Size(412, 915);

/// Las cuatro combinaciones que exige el sistema visual (§11).
const _matriz = [
  (_telefonoChico, 1.0),
  (_telefonoChico, 2.0),
  (_telefonoGrande, 1.0),
  (_telefonoGrande, 2.0),
];

String _sufijo(Size t, double escala) =>
    '${t.width.toInt()}x${t.height.toInt()}_x${escala.toInt()}';

class _OfertasQueFallan implements OfertasRepositorio {
  _OfertasQueFallan(this._base);

  final OfertasRepositorio _base;
  bool falla = true;

  @override
  Stream<List<Oferta>> observar() =>
      falla ? Stream.error(StateError('sin bandeja')) : _base.observar();

  @override
  Future<ResultadoRespuestaOferta> aceptar(
    String ofertaId, {
    required String claveIdempotencia,
  }) => _base.aceptar(ofertaId, claveIdempotencia: claveIdempotencia);

  @override
  Future<ResultadoRespuestaOferta> rechazar(
    String ofertaId, {
    required String claveIdempotencia,
  }) => _base.rechazar(ofertaId, claveIdempotencia: claveIdempotencia);
}

class _PerfilEnRevision extends PerfilDemo {
  _PerfilEnRevision(super.almacen, this._base);

  final Proveedor _base;

  @override
  Future<Proveedor> perfil() async => Proveedor(
    id: _base.id,
    nombre: _base.nombre,
    tipo: TipoProveedor.independiente,
    calificacion: 0,
    serviciosCompletados: 0,
    zonas: _base.zonas,
    aprobacion: EstadoAprobacion.pendiente,
    documentos: const [
      DocumentoProveedor(
        nombre: 'Licencia de piloto remoto',
        estado: EstadoDocumento.enRevision,
      ),
      DocumentoProveedor(
        nombre: 'Seguro de responsabilidad civil',
        estado: EstadoDocumento.rechazado,
        motivoRechazo: 'La póliza no cubre aplicación aérea.',
      ),
    ],
  );

  @override
  Future<ResumenCalificaciones> calificaciones() async =>
      const ResumenCalificaciones(promedio: 0, total: 0, recientes: []);

  @override
  Future<MetricasProveedor> metricas() async => MetricasProveedor(
    serviciosCompletados: 0,
    hectareasAtendidas: Decimal.zero,
    tasaAceptacion: 0,
    tasaCancelacion: 0,
  );

  @override
  Future<List<HectareasMensuales>> hectareasPorMes() async => const [];
}

class _SinDrones implements DronesRepositorio {
  @override
  Stream<List<Dron>> observar() => Stream.value(const []);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var ahora = DateTime(2026, 11, 23, 9);
  late AlmacenDemoProveedor almacen;
  late DependenciasProveedor deps;

  setUpAll(() async {
    Future<void> fuente(String familia, String ruta) async {
      final cargador = FontLoader(familia)..addFont(rootBundle.load(ruta));
      await cargador.load();
    }

    await fuente('Manrope', 'assets/fonts/Manrope.ttf');
    await fuente('JetBrains Mono', 'assets/fonts/JetBrainsMono.ttf');
    await fuente('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  });

  setUp(() {
    ahora = DateTime(2026, 11, 23, 9);
    almacen = AlmacenDemoProveedor(datos: DatosDemo(reloj: () => ahora));
    deps = DependenciasProveedor.demo(almacen);
  });

  /// Monta [pantalla] con el tema de modo campo, como en el shell del flavor.
  Future<void> montar(
    WidgetTester tester,
    Widget pantalla, {
    Size tamano = _telefonoGrande,
    double escala = 1.0,
    DependenciasProveedor? dependencias,
  }) async {
    ConfiguracionMapa.teselas = false;
    tester.view.physicalSize = tamano * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      ConfiguracionMapa.teselas = true;
    });
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AgrocomThemeCampo.construir(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(escala),
            disableAnimations: true,
          ),
          child: (dependencias ?? deps).proveer(child: child!),
        ),
        home: Scaffold(body: SafeArea(child: pantalla)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> golden(WidgetTester tester, String nombre) async {
    if (!_conGoldens) return;
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$nombre.png'),
    );
  }

  Finder lista() => find.byType(Scrollable).first;

  /// Lleva [destino] a la vista: lo construye desplazando la lista y lo
  /// centra para que un toque le pegue.
  Future<void> irA(WidgetTester tester, Finder destino) async {
    await tester.scrollUntilVisible(destino, 200, scrollable: lista());
    await Scrollable.ensureVisible(tester.element(destino), alignment: 0.5);
    await tester.pump();
  }

  group('Bandeja de ofertas', () {
    testWidgets('muestra hectáreas, zona, pago, distancia y mapa por oferta', (
      tester,
    ) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      expect(find.text('3 ofertas vigentes'), findsOneWidget);
      expect(find.text('210 ha · Trigo'), findsOneWidget);
      expect(find.textContaining('Colonia Okinawa'), findsOneWidget);
      expect(find.text('Bs 1.890'), findsOneWidget);
      expect(find.text('14,2 km'), findsOneWidget);
      expect(find.text('03:00'), findsOneWidget);
      expect(find.byType(MapaLote), findsWidgets);
      expect(find.textContaining('flota de Agrocom'), findsOneWidget);
    });

    testWidgets('la cuenta regresiva avanza cada segundo', (tester) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      ahora = ahora.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('02:59'), findsOneWidget);
    });

    testWidgets('aceptar y rechazar miden al menos 56 px (guantes)', (
      tester,
    ) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      for (final boton in [
        find.widgetWithText(FilledButton, 'Aceptar servicio').first,
        find.widgetWithText(OutlinedButton, 'Rechazar').first,
      ]) {
        expect(tester.getSize(boton).height, greaterThanOrEqualTo(56));
      }
    });

    testWidgets('aceptar deja el botón en espera y avisa el resultado', (
      tester,
    ) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Aceptar servicio').first,
      );
      await tester.pump();
      expect(find.text('Enviando…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      expect(find.text('Enviando…'), findsNothing);
      expect(find.textContaining('Servicio aceptado'), findsOneWidget);
      expect(find.text('2 ofertas vigentes'), findsOneWidget);
      expect(almacen.asignados, hasLength(2));
    });

    testWidgets('sin red los botones se apagan y la bandeja lo dice', (
      tester,
    ) async {
      almacen.enLinea = false;
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      expect(find.byKey(const Key('bandeja-sin-conexion')), findsOneWidget);
      expect(find.byKey(const Key('oferta-sin-conexion')), findsWidgets);
      final aceptar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Aceptar servicio').first,
      );
      final rechazar = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Rechazar').first,
      );
      expect(aceptar.onPressed, isNull);
      expect(rechazar.onPressed, isNull);
      // Las ofertas se siguen viendo.
      expect(find.text('3 ofertas vigentes'), findsOneWidget);

      almacen.enLinea = true;
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('bandeja-sin-conexion')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Aceptar servicio').first,
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('una oferta que tomó otro proveedor queda como tomada', (
      tester,
    ) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      final tarjeta = find.byKey(const ValueKey('oferta-$ofertaPerdidaEnDemo'));
      final aceptar = find.descendant(
        of: tarjeta,
        matching: find.widgetWithText(FilledButton, 'Aceptar servicio'),
      );
      await irA(tester, aceptar);
      await tester.tap(aceptar);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      final cerrada = find.byKey(
        const ValueKey('cerrada-$ofertaPerdidaEnDemo'),
      );
      await irA(tester, cerrada);
      expect(find.text('Ya la tomó otro proveedor'), findsOneWidget);
      expect(tarjeta, findsNothing);

      final quitar = find.byTooltip('Quitar');
      await irA(tester, quitar);
      await tester.tap(quitar);
      await tester.pump();
      expect(cerrada, findsNothing);
    });

    testWidgets('una oferta vencida se cuenta sin alarma', (tester) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      ahora = ahora.add(const Duration(minutes: 3));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('2 ofertas vigentes'), findsOneWidget);
      final cerrada = find.byKey(const ValueKey('cerrada-of-1'));
      await irA(tester, cerrada);
      expect(find.text('Oferta vencida'), findsOneWidget);
    });

    testWidgets('sin ofertas orienta sobre cómo llegan', (tester) async {
      ahora = ahora.add(const Duration(hours: 1));
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      expect(find.text('Sin ofertas por ahora'), findsOneWidget);
      expect(find.textContaining('flota de Agrocom'), findsOneWidget);
      await golden(tester, 'ofertas_vacia_360x640_x1');
    });

    testWidgets('un error de carga ofrece reintentar', (tester) async {
      final ofertas = _OfertasQueFallan(deps.ofertas);
      final conFalla = DependenciasProveedor(
        ofertas: ofertas,
        estadoRed: EstadoRedDemo(almacen),
        drones: deps.drones,
        perfil: deps.perfil,
      );
      await montar(
        tester,
        OfertasPantalla(reloj: () => ahora),
        dependencias: conFalla,
      );
      expect(find.text('No pudimos cargar las ofertas'), findsOneWidget);

      ofertas.falla = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('3 ofertas vigentes'), findsOneWidget);
    });

    for (final (tamano, escala) in _matriz) {
      final id = _sufijo(tamano, escala);
      testWidgets('se lee completa en $id', (tester) async {
        await montar(
          tester,
          OfertasPantalla(reloj: () => ahora),
          tamano: tamano,
          escala: escala,
        );
        await golden(tester, 'ofertas_$id');
        // Recorre la lista entera: ningún tramo desborda.
        await tester.drag(lista(), const Offset(0, -4000));
        await tester.pump();
      });
    }

    testWidgets('golden: sin conexión', (tester) async {
      almacen.enLinea = false;
      await montar(
        tester,
        OfertasPantalla(reloj: () => ahora),
        tamano: _telefonoChico,
      );
      await tester.drag(lista(), const Offset(0, -330));
      await tester.pump();
      await golden(tester, 'ofertas_sin_conexion_360x640_x1');
    });

    testWidgets('golden: ofertas cerradas', (tester) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora));
      ahora = ahora.add(const Duration(minutes: 9));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.drag(lista(), const Offset(0, -4000));
      await tester.pump();
      expect(find.text('Oferta vencida'), findsNWidgets(2));
      await golden(tester, 'ofertas_cerradas_412x915_x1');
    });
  });

  group('Detalle de la oferta', () {
    Future<void> abrir(WidgetTester tester, {double escala = 1.0}) async {
      await montar(tester, OfertasPantalla(reloj: () => ahora), escala: escala);
      final detalle = find.widgetWithText(TextButton, 'Ver detalle y mapa');
      await irA(tester, detalle.first);
      await tester.tap(detalle.first);
      await tester.pumpAndSettle();
    }

    testWidgets('muestra el lote, el pago, la fecha y el producto', (
      tester,
    ) async {
      await abrir(tester);
      expect(find.text('Detalle de la oferta'), findsOneWidget);
      expect(find.text('Pago estimado'), findsOneWidget);
      expect(find.text('Bs 1.890'), findsOneWidget);
      expect(find.text('24 nov 2026'), findsOneWidget);
      expect(find.text('Herbicida de preemergencia'), findsOneWidget);
      expect(find.text('03:00'), findsOneWidget);
      await golden(tester, 'oferta_detalle_412x915_x1');
    });

    testWidgets('aceptar desde el detalle vuelve a la bandeja', (tester) async {
      await abrir(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Aceptar servicio'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de la oferta'), findsNothing);
      expect(almacen.asignados, hasLength(2));
      expect(find.textContaining('Servicio aceptado'), findsOneWidget);
    });

    testWidgets('sin red el detalle apaga los botones y dice por qué', (
      tester,
    ) async {
      await abrir(tester);
      almacen.enLinea = false;
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('detalle-sin-conexion')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Aceptar servicio'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('si vence con el detalle abierto lo cuenta y deja volver', (
      tester,
    ) async {
      await abrir(tester);
      ahora = ahora.add(const Duration(minutes: 3));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Oferta vencida'), findsOneWidget);
      await tester.tap(find.text('Volver a la bandeja'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de la oferta'), findsNothing);
    });

    testWidgets('se lee con el texto al 200 %', (tester) async {
      await abrir(tester, escala: 2.0);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await tester.pump();
    });
  });

  group('Perfil del proveedor', () {
    testWidgets('muestra aprobación, métricas, documentos y equipo', (
      tester,
    ) async {
      await montar(tester, PerfilPantalla(reloj: () => ahora));
      expect(find.text('Rodrigo Sandoval Justiniano'), findsOneWidget);
      expect(find.bySemanticsLabel('Estado: Aprobado'), findsWidgets);
      expect(
        find.text('Estás habilitado para recibir ofertas.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('perfil-documentos-accion')), findsOneWidget);
      expect(find.text('92 %'), findsOneWidget);
      expect(find.text('11.847'), findsOneWidget);

      await irA(tester, find.text('Edwin Mamani Quispe'));
      expect(find.text('Mi equipo'), findsOneWidget);
      expect(find.text('Auxiliar · 96 servicios juntos'), findsOneWidget);

      await irA(tester, find.byKey(const Key('perfil-calificaciones')));
      expect(find.text('128 calificaciones'), findsOneWidget);
      expect(find.bySemanticsLabel('5 estrellas: 108'), findsOneWidget);
    });

    testWidgets('un perfil en revisión explica que todavía no opera', (
      tester,
    ) async {
      final enRevision = DependenciasProveedor(
        ofertas: deps.ofertas,
        estadoRed: deps.estadoRed,
        drones: deps.drones,
        perfil: _PerfilEnRevision(almacen, almacen.piloto),
      );
      await montar(
        tester,
        PerfilPantalla(reloj: () => ahora),
        dependencias: enRevision,
        tamano: _telefonoChico,
      );
      expect(find.bySemanticsLabel('Estado: En revisión'), findsWidgets);
      expect(
        find.textContaining('Un administrador está revisando'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('perfil-documentos-accion')), findsNothing);
      expect(find.text('Todavía sin calificaciones'), findsOneWidget);
      await golden(tester, 'perfil_en_revision_360x640_x1');

      await irA(tester, find.textContaining('La póliza no cubre'));
      await irA(tester, find.textContaining('No tenés un auxiliar asociado'));
    });

    testWidgets('la fila de drones solo aparece si el flavor la pide', (
      tester,
    ) async {
      var abiertos = 0;
      await montar(
        tester,
        PerfilPantalla(reloj: () => ahora, onVerDrones: () => abiertos++),
      );
      final fila = find.byKey(const Key('perfil-ver-drones'));
      await irA(tester, fila);
      expect(find.text('Mis drones · 2 drones'), findsOneWidget);
      expect(tester.getSize(fila).height, greaterThanOrEqualTo(56));
      await tester.tap(fila);
      expect(abiertos, 1);
    });

    for (final (tamano, escala) in _matriz) {
      final id = _sufijo(tamano, escala);
      testWidgets('se lee completo en $id', (tester) async {
        await montar(
          tester,
          PerfilPantalla(reloj: () => ahora),
          tamano: tamano,
          escala: escala,
        );
        await golden(tester, 'perfil_$id');
        await tester.drag(lista(), const Offset(0, -6000));
        await tester.pump();
      });
    }

    testWidgets('golden: equipo y calificaciones', (tester) async {
      await montar(tester, PerfilPantalla(reloj: () => ahora));
      await irA(tester, find.byKey(const Key('perfil-calificaciones')));
      await tester.drag(lista(), const Offset(0, -260));
      await tester.pump();
      await golden(tester, 'perfil_calificaciones_412x915_x1');
    });
  });

  group('Mis drones', () {
    testWidgets('muestra estado y ciclos de batería de cada dron', (
      tester,
    ) async {
      await montar(tester, const DronesPantalla());
      expect(find.text('2 drones registrados'), findsOneWidget);
      expect(find.text('DJI Agras T50'), findsOneWidget);
      expect(find.bySemanticsLabel('Estado: Disponible'), findsOneWidget);
      expect(find.bySemanticsLabel('Estado: En servicio'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Batería: 318 de 400 ciclos, 80 por')),
        findsOneWidget,
      );
      expect(
        find.text('Quedan 82 ciclos. Planificá el recambio.'),
        findsOneWidget,
      );
      // El de batería por agotarse va primero.
      final t40 = tester.getTopLeft(find.text('DJI Agras T40')).dy;
      final t50 = tester.getTopLeft(find.text('DJI Agras T50')).dy;
      expect(t40, lessThan(t50));
    });

    testWidgets('sin drones explica qué hace falta', (tester) async {
      final sinDrones = DependenciasProveedor(
        ofertas: deps.ofertas,
        estadoRed: deps.estadoRed,
        drones: _SinDrones(),
        perfil: deps.perfil,
      );
      await montar(tester, const DronesPantalla(), dependencias: sinDrones);
      expect(find.text('Todavía no registraste drones'), findsOneWidget);
      expect(find.textContaining('Sin un dron aprobado'), findsOneWidget);
    });

    for (final (tamano, escala) in _matriz) {
      final id = _sufijo(tamano, escala);
      testWidgets('se lee completa en $id', (tester) async {
        await montar(
          tester,
          const DronesPantalla(),
          tamano: tamano,
          escala: escala,
        );
        await golden(tester, 'drones_$id');
        await tester.drag(lista(), const Offset(0, -3000));
        await tester.pump();
      });
    }
  });
}
