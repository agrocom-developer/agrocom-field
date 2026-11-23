import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/dron/data/drones_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/data/estado_red_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/ofertas/data/ofertas_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/data/perfil_demo.dart';

void main() {
  late AlmacenDemoProveedor almacen;
  late OfertasDemo ofertas;
  setUp(() {
    almacen = AlmacenDemoProveedor();
    ofertas = OfertasDemo(almacen, latencia: Duration.zero);
  });

  test('aceptar una oferta la pasa a servicios asignados', () async {
    final r = await ofertas.aceptar('of-1', claveIdempotencia: 'k1');
    expect(r, ResultadoRespuestaOferta.aceptada);
    final asignados = await almacen.observarAsignados().first;
    expect(asignados.length, 2);
    expect(
      (await ofertas.observar().first).any((o) => o.id == 'of-1'),
      isFalse,
    );
  });

  test('reintentar con la misma clave devuelve el mismo resultado', () async {
    final a = await ofertas.aceptar('of-1', claveIdempotencia: 'k1');
    final b = await ofertas.aceptar('of-1', claveIdempotencia: 'k1');
    expect(b, a);
    expect(almacen.asignados.length, 2);
  });

  test('una oferta puede perderse frente a otro proveedor', () async {
    final r = await ofertas.aceptar(
      ofertaPerdidaEnDemo,
      claveIdempotencia: 'k2',
    );
    expect(r, ResultadoRespuestaOferta.perdida);
    expect(almacen.asignados.length, 1);
  });

  test('rechazar quita la oferta sin asignar nada', () async {
    final r = await ofertas.rechazar('of-3', claveIdempotencia: 'k3');
    expect(r, ResultadoRespuestaOferta.rechazada);
    expect(almacen.asignados.length, 1);
  });

  test('sin red no se responde y la oferta sigue en la bandeja', () async {
    almacen.enLinea = false;
    expect(
      await ofertas.aceptar('of-1', claveIdempotencia: 'k1'),
      ResultadoRespuestaOferta.sinConexion,
    );
    expect(
      await ofertas.rechazar('of-1', claveIdempotencia: 'k1'),
      ResultadoRespuestaOferta.sinConexion,
    );
    expect(almacen.oferta('of-1'), isNotNull);
    expect(almacen.asignados.length, 1);

    // Al volver la red, la misma clave resuelve la oferta una sola vez.
    almacen.enLinea = true;
    expect(
      await ofertas.aceptar('of-1', claveIdempotencia: 'k1'),
      ResultadoRespuestaOferta.aceptada,
    );
    expect(almacen.asignados.length, 2);
  });

  test('el estado de red emite el valor actual y cada cambio', () async {
    final emitidos = <bool>[];
    final sub = EstadoRedDemo(almacen).observar().listen(emitidos.add);
    await Future<void>.delayed(Duration.zero);
    almacen.enLinea = false;
    almacen.enLinea = false;
    almacen.enLinea = true;
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(emitidos, [true, false, true]);
  });

  test('perfil, drones e historial del proveedor tienen datos', () async {
    final perfil = await PerfilDemo(almacen).perfil();
    expect(perfil.tipo, TipoProveedor.propioAgrocom);
    expect(perfil.resenas, isNotEmpty);
    expect((await PerfilDemo(almacen).hectareasPorMes()).length, 6);
    expect((await PerfilDemo(almacen).historial()), isNotEmpty);
    expect((await DronesDemo(almacen).observar().first).length, 2);
  });

  test(
    'el perfil trae aprobación, auxiliares, métricas y calificaciones',
    () async {
      final repo = PerfilDemo(almacen);
      final perfil = await repo.perfil();
      expect(perfil.aprobacion, EstadoAprobacion.aprobado);
      expect(perfil.auxiliares.first.aprobacion.habilitado, isTrue);
      expect(
        perfil.documentosConAccion.single.estado,
        EstadoDocumento.porVencer,
      );

      final metricas = await repo.metricas();
      expect(metricas.hectareasAtendidas, isA<Decimal>());
      expect(metricas.tasaAceptacion, inInclusiveRange(0, 100));
      expect(metricas.tasaCancelacion, inInclusiveRange(0, 100));

      final calificaciones = await repo.calificaciones();
      expect(
        calificaciones.porPuntaje.values.reduce((a, b) => a + b),
        calificaciones.total,
      );
      expect(calificaciones.recientes, isNotEmpty);
    },
  );

  group('Dron', () {
    Dron dron(int ciclos, {int maximo = 400}) => Dron(
      id: 'd',
      matricula: 'M',
      modelo: 'X',
      capacidadLitros: Decimal.fromInt(40),
      estado: EstadoDron.disponible,
      propiedad: PropiedadDron.tercero,
      ciclosBateria: ciclos,
      cicloMaximoBateria: maximo,
    );

    test('avisa del recambio desde tres cuartos de vida útil', () {
      expect(dron(299).bateriaPorAgotarse, isFalse);
      expect(dron(300).bateriaPorAgotarse, isTrue);
      expect(dron(300).ciclosRestantes, 100);
    });

    test('una batería pasada de ciclos no da valores fuera de rango', () {
      expect(dron(450).desgasteBateria, 1);
      expect(dron(450).ciclosRestantes, 0);
      expect(dron(10, maximo: 0).desgasteBateria, 0);
    });
  });
}
