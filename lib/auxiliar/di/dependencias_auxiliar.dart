import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../demo/almacen_demo_auxiliar.dart';
import '../mezcla/data/mezcla_demo.dart';
import '../mezcla/domain/mezcla_repositorio.dart';
import '../servicio_asignado/data/servicio_asignado_auxiliar_demo.dart';
import '../servicio_asignado/domain/servicio_asignado_auxiliar_repositorio.dart';

/// Repositorios del flavor auxiliar para la superficie del marketplace.
/// Hoy solo existe la implementación demo (`MODO_DEMO`, ADR 0010); la real
/// lee y escribe en `drift` con outbox.
class DependenciasAuxiliar {
  const DependenciasAuxiliar({
    required this.servicioAsignado,
    required this.mezcla,
  });

  factory DependenciasAuxiliar.demo() {
    final almacen = AlmacenDemoAuxiliar();
    return DependenciasAuxiliar(
      servicioAsignado: ServicioAsignadoAuxiliarDemo(almacen),
      mezcla: MezclaDemo(almacen),
    );
  }

  final ServicioAsignadoAuxiliarRepositorio servicioAsignado;
  final MezclaRepositorio mezcla;

  Widget proveer({required Widget child}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ServicioAsignadoAuxiliarRepositorio>.value(
        value: servicioAsignado,
      ),
      RepositoryProvider<MezclaRepositorio>.value(value: mezcla),
    ],
    child: child,
  );
}
