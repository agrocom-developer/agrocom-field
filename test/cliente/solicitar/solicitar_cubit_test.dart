import 'dart:async';

import 'package:agrocom_field/cliente/solicitar/presentation/busqueda_proveedor_cubit.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_cubit.dart';
import 'package:agrocom_field/cliente/solicitar/presentation/solicitar_estado.dart';
import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayudas_solicitar.dart';

void main() {
  late RepositorioEspia repo;
  late SolicitarCubit cubit;

  setUp(() {
    repo = RepositorioEspia();
    cubit = crearCubit(repo);
  });
  tearDown(() => cubit.close());

  test(
    'cargar trae lotes, productos, cultivos y fechas desde mañana',
    () async {
      expect(cubit.state.carga, CargaSolicitud.cargando);
      await cubit.cargar();
      expect(cubit.state.carga, CargaSolicitud.lista);
      expect(cubit.state.lotes, hasLength(5));
      expect(cubit.state.productos, isNotEmpty);
      expect(cubit.state.cultivos, contains('Soya'));
      expect(cubit.state.fechas.first, DateTime(2026, 11, 24));
      expect(cubit.state.puedeAvanzar, isFalse);
    },
  );

  test('si la carga falla queda en error y se puede reintentar', () async {
    repo.fallaLaCarga = true;
    await cubit.cargar();
    expect(cubit.state.carga, CargaSolicitud.error);
    repo.fallaLaCarga = false;
    await cubit.cargar();
    expect(cubit.state.carga, CargaSolicitud.lista);
  });

  test('sin lotes guardados el formulario abre en modo dibujo', () async {
    final vacio = RepositorioEspia(lotes: const []);
    final c = crearCubit(vacio);
    await c.cargar();
    expect(c.state.modoLote, ModoLote.dibujo);
    await c.close();
  });

  test('elegir un lote propone sus hectáreas y su cultivo', () async {
    await cubit.cargar();
    cubit.elegirLote(cubit.state.lotes[1]);
    expect(cubit.state.hectareasTexto, '85,5');
    expect(cubit.state.hectareas, Decimal.parse('85.5'));
    expect(cubit.state.cultivo, 'Maíz');
    expect(cubit.state.puedeAvanzar, isTrue);
  });

  test('dibujar el contorno calcula hectáreas decimales', () async {
    await cubit.cargar();
    cubit.cambiarModoLote(ModoLote.dibujo);
    expect(cubit.state.lote, isNull);
    for (final p in contornoDePrueba.take(2)) {
      cubit.agregarVertice(p);
    }
    expect(
      cubit.state.puedeAvanzar,
      isFalse,
      reason: 'dos esquinas no cierran',
    );
    cubit.agregarVertice(contornoDePrueba[2]);
    expect(cubit.state.puedeAvanzar, isTrue);
    final triangulo = cubit.state.hectareas!;
    cubit.agregarVertice(contornoDePrueba[3]);
    final cuadrado = cubit.state.hectareas!;
    expect(cuadrado, greaterThan(triangulo));
    expect(cuadrado, greaterThan(Decimal.parse('99')));
    expect(cuadrado, lessThan(Decimal.parse('101')));
    expect(cubit.state.lote!.poligono, contornoDePrueba);

    cubit.moverVertice(0, const GeoPunto(-16.9450, -62.6300));
    expect(cubit.state.hectareas, greaterThan(cuadrado));

    cubit.deshacerVertice();
    expect(cubit.state.vertices, hasLength(3));
    cubit.borrarContorno();
    expect(cubit.state.vertices, isEmpty);
    expect(cubit.state.hectareasTexto, isEmpty);
    expect(cubit.state.puedeAvanzar, isFalse);
  });

  test(
    'las hectáreas se pueden editar y un valor inválido no deja seguir',
    () async {
      await cubit.cargar();
      cubit
        ..elegirLote(cubit.state.lotes[1])
        ..elegirProducto('Insecticida piretroide');
      await cubit.avanzar();
      expect(cubit.state.paso, PasoSolicitud.aplicacion);

      cubit.cambiarHectareas('40,25');
      expect(cubit.state.hectareas, Decimal.parse('40.25'));
      expect(cubit.state.litrosTotales, Decimal.parse('40.25'));
      expect(cubit.state.puedeAvanzar, isTrue);

      cubit.cambiarHectareas('cuarenta');
      expect(cubit.state.errorHectareas, isNotNull);
      expect(cubit.state.puedeAvanzar, isFalse);
      await cubit.avanzar();
      expect(cubit.state.paso, PasoSolicitud.aplicacion);
    },
  );

  test('cambiar de lote descarta la edición manual de hectáreas', () async {
    await cubit.cargar();
    cubit
      ..elegirLote(cubit.state.lotes[1])
      ..cambiarHectareas('40')
      ..elegirLote(cubit.state.lotes[0]);
    expect(cubit.state.hectareasTexto, '120');
  });

  test('la dosis sube y baja de a 0,1 y no llega a cero', () async {
    cubit
      ..subirDosis()
      ..subirDosis();
    expect(cubit.state.dosisEfectiva, Decimal.parse('1.2'));
    for (var i = 0; i < 30; i++) {
      cubit.bajarDosis();
    }
    expect(cubit.state.dosisEfectiva, Decimal.parse('0.1'));
  });

  test('fecha inválida: no se acepta y explica por qué', () async {
    await cubit.cargar();
    cubit.elegirFecha(ahoraDePrueba);
    expect(cubit.state.fecha, isNull);
    expect(cubit.state.errorFecha, isNotNull);

    cubit.elegirFecha(DateTime(2026, 12, 25));
    expect(cubit.state.fecha, isNull);

    cubit.elegirFecha(DateTime(2026, 11, 26, 15, 30));
    expect(cubit.state.fecha, DateTime(2026, 11, 26));
    expect(cubit.state.errorFecha, isNull);
  });

  test('el resumen estima con las hectáreas editadas, sin recargo', () async {
    await completarHastaResumen(cubit);
    expect(cubit.state.paso, PasoSolicitud.resumen);
    final e = cubit.state.estimacion!;
    expect(e.precio, Decimal.parse('7695'));
    expect(e.recargos, isEmpty);
    expect(e.litros, Decimal.parse('85.5'));
  });

  test('pedir para mañana suma el recargo por urgencia, visible', () async {
    await completarHastaResumen(cubit, urgente: true);
    final e = cubit.state.estimacion!;
    expect(cubit.fechaUrgente, isTrue);
    expect(e.subtotal, Decimal.parse('7695'));
    expect(e.recargos.single.monto, Decimal.parse('769.5'));
    expect(e.precio, Decimal.parse('8464.5'));
  });

  test(
    'si la estimación falla no se puede confirmar hasta recalcular',
    () async {
      repo.fallaLaEstimacion = true;
      await completarHastaResumen(cubit);
      expect(cubit.state.falloEstimacion, isTrue);
      expect(cubit.state.puedeAvanzar, isFalse);
      repo.fallaLaEstimacion = false;
      await cubit.estimar();
      expect(cubit.state.estimacion, isNotNull);
      expect(cubit.state.puedeAvanzar, isTrue);
    },
  );

  test('volver atrás conserva lo elegido', () async {
    await completarHastaResumen(cubit);
    cubit
      ..retroceder()
      ..retroceder();
    expect(cubit.state.paso, PasoSolicitud.aplicacion);
    expect(cubit.state.avanza, isFalse);
    expect(cubit.state.producto, 'Insecticida piretroide');
    expect(cubit.state.fecha, DateTime(2026, 11, 26));
    expect(cubit.state.ventana, VentanaHoraria.amanecer);
  });

  test('doble envío: una sola solicitud y un solo servicio', () async {
    await completarHastaResumen(cubit);
    final antes = repo.almacen.servicios.length;
    // Dos toques seguidos sobre «Confirmar solicitud».
    final primero = cubit.avanzar();
    final segundo = cubit.avanzar();
    expect(cubit.state.enviando, isTrue);
    await Future.wait([primero, segundo]);

    expect(repo.clavesEnviadas, ['clave-1']);
    expect(repo.almacen.servicios.length, antes + 1);
    final servicio = cubit.state.servicio!;
    expect(servicio.estado, EstadoServicio.buscandoProveedor);
    expect(servicio.hectareasDeclaradas, Decimal.parse('85.5'));
    expect(servicio.precio, Decimal.parse('7695'));

    // Un tercer toque, ya con el servicio creado, tampoco envía.
    await cubit.enviar();
    expect(repo.clavesEnviadas, hasLength(1));
  });

  test(
    'sin red conserva el formulario y el reintento usa la misma clave',
    () async {
      await completarHastaResumen(cubit);
      cubit.cambiarHectareas('60');
      final antes = repo.almacen.servicios.length;
      repo.demo.sinConexion = true;
      await cubit.enviar();

      expect(cubit.state.falloEnvio, FalloEnvio.sinConexion);
      expect(cubit.state.enviando, isFalse);
      expect(cubit.state.servicio, isNull);
      expect(cubit.state.paso, PasoSolicitud.resumen);
      expect(cubit.state.hectareasTexto, '60');
      expect(cubit.state.producto, 'Insecticida piretroide');
      expect(cubit.state.fecha, DateTime(2026, 11, 26));
      expect(cubit.state.loteGuardado!.nombre, 'Maíz La Curva');
      expect(repo.almacen.servicios.length, antes);

      repo.demo.sinConexion = false;
      await cubit.avanzar();
      expect(cubit.state.falloEnvio, isNull);
      expect(cubit.state.servicio, isNotNull);
      expect(repo.clavesEnviadas, ['clave-1', 'clave-1']);
      expect(repo.almacen.servicios.length, antes + 1);
      expect(cubit.state.servicio!.hectareasDeclaradas, Decimal.fromInt(60));
    },
  );

  test('un lote dibujado viaja con su contorno y sus hectáreas', () async {
    await cubit.cargar();
    cubit.cambiarModoLote(ModoLote.dibujo);
    contornoDePrueba.forEach(cubit.agregarVertice);
    await cubit.avanzar();
    cubit
      ..elegirCultivo('Soya')
      ..elegirProducto('Fertilizante foliar');
    await cubit.avanzar();
    cubit.elegirFecha(cubit.state.fechas[3]);
    await cubit.avanzar();
    await cubit.avanzar();
    final servicio = cubit.state.servicio!;
    expect(servicio.lote.poligono, contornoDePrueba);
    expect(servicio.lote.cultivo, 'Soya');
    expect(servicio.hectareasDeclaradas, hectareasDePoligono(contornoDePrueba));
  });

  group('búsqueda de proveedor', () {
    /// Completa y envía dentro del reloj falso de `testWidgets`.
    Future<Servicio> solicitar(WidgetTester tester) async {
      await completarHastaResumen(cubit);
      final envio = cubit.avanzar();
      // La latencia de la demo es un temporizador: hay que mover el reloj.
      await tester.pump(const Duration(milliseconds: 1));
      await envio;
      return cubit.state.servicio!;
    }

    testWidgets('la demo ofrece a propios, después a terceros, y asigna', (
      tester,
    ) async {
      final servicio = await solicitar(tester);
      final busqueda = BusquedaProveedorCubit(repo, servicio.id)..iniciar();
      final fases = <FaseBusqueda>[];
      final escucha = busqueda.stream.listen((b) => fases.add(b.fase));
      await tester.pump();
      expect(busqueda.state.fase, FaseBusqueda.propios);

      await tester.pump(const Duration(seconds: 4));
      expect(busqueda.state.fase, FaseBusqueda.terceros);
      expect(busqueda.state.radioKm, 50);

      await tester.pump(const Duration(seconds: 4));
      expect(busqueda.state.fase, FaseBusqueda.asignado);
      expect(busqueda.state.terminada, isTrue);
      expect(
        busqueda.state.proveedor!.tipo,
        isNot(TipoProveedor.propioAgrocom),
      );
      expect(fases, [
        FaseBusqueda.propios,
        FaseBusqueda.terceros,
        FaseBusqueda.asignado,
      ]);

      final guardado = repo.almacen.porId(servicio.id)!;
      expect(guardado.estado, EstadoServicio.asignado);
      expect(guardado.proveedor, isNotNull);
      // Sin `await`: la cancelación devuelve un futuro de la zona raíz y
      // esperarlo saca a la prueba del reloj falso.
      unawaited(escucha.cancel());
      await busqueda.close();
    });

    testWidgets(
      'cerrar la pantalla a mitad de la búsqueda no deja nada corriendo',
      (tester) async {
        final servicio = await solicitar(tester);
        final busqueda = BusquedaProveedorCubit(repo, servicio.id)..iniciar();
        await tester.pump();
        await busqueda.close();
        // Un temporizador vivo haría fallar la prueba al terminar.
        await tester.pump(const Duration(seconds: 30));
        expect(
          repo.almacen.porId(servicio.id)!.estado,
          EstadoServicio.buscandoProveedor,
        );
      },
    );

    test('un servicio ya asignado informa su proveedor de inmediato', () async {
      final asignado = repo.almacen.servicios.firstWhere(
        (s) => s.proveedor != null,
      );
      final cuadro = await repo.observarBusqueda(asignado.id).first;
      expect(cuadro.fase, FaseBusqueda.asignado);
      expect(cuadro.proveedor!.id, asignado.proveedor!.id);
    });
  });
}
