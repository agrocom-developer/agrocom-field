import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrocom_field/nucleo/marketplace/dominio/dominio.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/demo/almacen_demo_proveedor.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/dron/data/drones_demo.dart';
import 'package:agrocom_field/nucleo/marketplace/proveedor/perfil/data/perfil_demo.dart';

void main() {
  late AlmacenDemoProveedor almacen;
  setUp(() {
    almacen = AlmacenDemoProveedor();
  });

  test('perfil, drones e historial del proveedor tienen datos', () async {
    final perfil = await PerfilDemo(almacen).perfil();
    expect(perfil.tipo, TipoProveedor.propioAgrocom);
    expect(perfil.resenas, isNotEmpty);
    expect((await PerfilDemo(almacen).hectareasPorMes()).length, 6);
    expect((await PerfilDemo(almacen).historial()), isNotEmpty);
    expect((await DronesDemo(almacen).observar().first).length, 2);
  });

  test('el perfil trae aprobación, métricas y calificaciones', () async {
    final repo = PerfilDemo(almacen);
    final perfil = await repo.perfil();
    expect(perfil.aprobacion, EstadoAprobacion.aprobado);
    expect(perfil.documentosConAccion.single.estado, EstadoDocumento.porVencer);

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
  });

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
