import 'dart:async';

import 'package:agrocom_field/nucleo/permisos/permiso_app.dart';
import 'package:agrocom_field/nucleo/permisos/permisos_servicio.dart';
import 'package:agrocom_field/nucleo/permisos/ubicacion_puntual.dart';

/// Configuración común de las pruebas: los permisos del sistema y la
/// ubicación no tienen canal de plataforma, así que arrancan concedidos y sin
/// lectura. Una prueba de permisos inyecta su propio `PermisosServicioFalso`.
Future<void> testExecutable(FutureOr<void> Function() pruebas) async {
  PermisosServicio.instancia = PermisosServicioFalso(
    inicial: EstadoPermiso.concedido,
  );
  UbicacionPuntual.instancia = const _SinUbicacion();
  await pruebas();
}

class _SinUbicacion implements UbicacionPuntual {
  const _SinUbicacion();

  @override
  Future<({double latitud, double longitud})?> obtener() async => null;
}
