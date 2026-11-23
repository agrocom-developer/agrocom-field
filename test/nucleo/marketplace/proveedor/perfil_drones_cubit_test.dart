import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/dron/domain/drones_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/dron/presentation/drones_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/data/perfil_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/domain/perfil_repositorio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/presentation/perfil_cubit.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/presentation/perfil_estado.dart';

class _PerfilQueFalla extends PerfilDemo {
  _PerfilQueFalla(super.almacen);

  bool falla = true;

  @override
  Future<MetricasProveedor> metricas() =>
      falla ? Future.error(StateError('sin red')) : super.metricas();
}

class _DronesFijos implements DronesRepositorio {
  _DronesFijos(this._crear);

  final Stream<List<Dron>> Function() _crear;

  @override
  Stream<List<Dron>> observar() => _crear();
}

Dron _dron(
  String id, {
  int ciclos = 100,
  EstadoDron estado = EstadoDron.disponible,
  EstadoAprobacion aprobacion = EstadoAprobacion.aprobado,
}) => Dron(
  id: id,
  matricula: id.toUpperCase(),
  modelo: 'Dron $id',
  capacidadLitros: Decimal.fromInt(40),
  estado: estado,
  propiedad: PropiedadDron.tercero,
  ciclosBateria: ciclos,
  cicloMaximoBateria: 400,
  aprobacion: aprobacion,
);

void main() {
  group('PerfilCubit', () {
    blocTest<PerfilCubit, PerfilEstado>(
      'carga proveedor, métricas, calificaciones y hectáreas',
      build: () => PerfilCubit(PerfilDemo(AlmacenDemoProveedor())),
      act: (c) => c.cargar(),
      expect: () => [isA<PerfilListo>()],
      verify: (c) {
        final listo = c.state as PerfilListo;
        expect(listo.proveedor.nombre, 'Rodrigo Sandoval Justiniano');
        expect(listo.metricas.serviciosCompletados, 142);
        expect(listo.calificaciones.total, 128);
        expect(listo.hectareasPorMes, hasLength(6));
      },
    );

    test('si una lectura falla queda en error y se puede reintentar', () async {
      final PerfilRepositorio repo = _PerfilQueFalla(AlmacenDemoProveedor());
      final cubit = PerfilCubit(repo);
      await cubit.cargar();
      expect(cubit.state, isA<PerfilError>());

      (repo as _PerfilQueFalla).falla = false;
      final estados = <PerfilEstado>[];
      final sub = cubit.stream.listen(estados.add);
      await cubit.cargar();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(estados, [isA<PerfilCargando>(), isA<PerfilListo>()]);
      await cubit.close();
    });
  });

  group('DronesCubit', () {
    blocTest<DronesCubit, DronesEstado>(
      'ordena primero los drones que piden atención',
      build: () => DronesCubit(
        _DronesFijos(
          () => Stream.value([
            _dron('ok'),
            _dron('taller', estado: EstadoDron.mantenimiento),
            _dron('bateria', ciclos: 350),
            _dron('sin-aprobar', aprobacion: EstadoAprobacion.pendiente),
            _dron('ok-2'),
          ]),
        ),
      ),
      act: (c) => c.iniciar(),
      expect: () => [isA<DronesListos>()],
      verify: (c) {
        expect((c.state as DronesListos).drones.map((d) => d.id), [
          'sin-aprobar',
          'bateria',
          'taller',
          'ok',
          'ok-2',
        ]);
      },
    );

    blocTest<DronesCubit, DronesEstado>(
      'sin drones queda en lista vacía, no en error',
      build: () => DronesCubit(_DronesFijos(() => Stream.value(const []))),
      act: (c) => c.iniciar(),
      expect: () => [isA<DronesListos>()],
      verify: (c) => expect((c.state as DronesListos).drones, isEmpty),
    );

    test('un error de lectura se puede reintentar', () async {
      var falla = true;
      final cubit = DronesCubit(
        _DronesFijos(
          () => falla
              ? Stream.error(StateError('sin red'))
              : Stream.value([_dron('ok')]),
        ),
      )..iniciar();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<DronesError>());

      falla = false;
      cubit.iniciar();
      expect(cubit.state, isA<DronesCargando>());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<DronesListos>());
      await cubit.close();
    });
  });
}
