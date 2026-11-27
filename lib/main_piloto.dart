import 'package:flutter/material.dart';

import 'nucleo/conectividad/data/conectividad_real.dart';
import 'nucleo/di/composicion_proveedor.dart';
import 'nucleo/entorno/modo_demo.dart';
import 'nucleo/flavor.dart';
import 'nucleo/marketplace/proveedor/acceso/presentation/app_proveedor.dart';
import 'piloto/app_piloto_demo.dart';
import 'piloto/di/dependencias_piloto.dart';

/// Entrypoint del flavor `piloto`.
///
/// Con `MODO_DEMO` corre contra repositorios en memoria con datos ficticios,
/// sin red ni `drift` (`--dart-define-from-file=config/env.demo.json`,
/// ADR 0010). Sin él, corre contra la API de `API_BASE_URL`
/// (`config/env.local.json`, `env.staging.json`, `env.produccion.json`;
/// ADR 0004): ingreso por usuario, mapa de solicitudes, ofertas y, para lo
/// que ocurre en el lote, la base local `drift` (ADR 0016).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (modoDemo) {
    runApp(AppPilotoDemo(dependencias: DependenciasPiloto.demo()));
    return;
  }

  final c = await componerProveedor(Flavor.piloto);
  runApp(
    AppProveedor(
      proveedor: c.proveedor,
      acceso: c.acceso,
      selectorImagen: c.selectorImagen,
      construirShell: (context, alSalir) => ShellPiloto(
        conectividad: ConectividadReal(),
        alSalir: alSalir,
        bloqueo: c.acceso.bloqueo,
      ),
    ),
  );
}
