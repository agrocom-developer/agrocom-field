import 'package:flutter/material.dart';

import 'auxiliar/app_auxiliar_demo.dart';
import 'auxiliar/di/dependencias_auxiliar.dart';
import 'nucleo/di/composicion_proveedor.dart';
import 'nucleo/entorno/modo_demo.dart';
import 'nucleo/flavor.dart';
import 'nucleo/marketplace/proveedor/acceso/presentation/app_proveedor.dart';

/// Entrypoint del flavor `auxiliar`.
///
/// Con `MODO_DEMO` corre contra repositorios en memoria con datos ficticios,
/// sin red ni `drift` (ADR 0010). Sin él, corre contra la API de
/// `API_BASE_URL` (ADR 0004): el auxiliar entra por usuario, ve el servicio
/// adjudicado de su equipo y sube fotos de avance. No se registra solo: lo
/// registra su piloto y lo aprueba un administrador.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (modoDemo) {
    runApp(AppAuxiliarDemo(dependencias: DependenciasAuxiliar.demo()));
    return;
  }

  final c = await componerProveedor(Flavor.auxiliar);
  runApp(
    AppProveedor(
      proveedor: c.proveedor,
      acceso: c.acceso,
      selectorImagen: c.selectorImagen,
      permiteRegistro: false,
      construirShell: (context, alSalir) => ShellAuxiliar(alSalir: alSalir),
    ),
  );
}
