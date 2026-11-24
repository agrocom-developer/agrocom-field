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
        negociacion: deps.negociacion,
        ejecucion: deps.ejecucion,
        drones: deps.drones,
        perfil: _PerfilEnRevision(almacen, almacen.piloto),
        referencias: deps.referencias,
        fotoPerfil: deps.fotoPerfil,
        pagos: deps.pagos,
        preparadorFoto: deps.preparadorFoto,
        push: deps.push,
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
        negociacion: deps.negociacion,
        ejecucion: deps.ejecucion,
        drones: _SinDrones(),
        perfil: deps.perfil,
        referencias: deps.referencias,
        fotoPerfil: deps.fotoPerfil,
        pagos: deps.pagos,
        preparadorFoto: deps.preparadorFoto,
        push: deps.push,
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
