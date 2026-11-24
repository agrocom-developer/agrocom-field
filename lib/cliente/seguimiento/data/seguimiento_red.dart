import 'dart:async';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/fuente_servicios.dart';
import '../domain/seguimiento_repositorio.dart';

/// Seguimiento de un servicio activo leyendo la solicitud cada
/// [intervalo]. La API no expone la posición del dron ni las hectáreas ya
/// cubiertas al cliente (ver `docs/gestion/brechas-api.md`): el fotograma
/// muestra el estado real del servicio, ubica el dron en el centro del lote y
/// no dibuja estela.
///
/// El flujo termina cuando el servicio deja de estar activo. Si una lectura
/// falla, el error llega al `Stream` y la pantalla conserva el último
/// fotograma («sin señal»).
class SeguimientoRed implements SeguimientoRepositorio {
  SeguimientoRed(this._fuente, {this.intervalo = const Duration(seconds: 10)});

  final FuenteServicios _fuente;
  final Duration intervalo;

  @override
  Stream<SeguimientoVivo> observar(String servicioId) async* {
    while (true) {
      final servicio = await _fuente.detalle(servicioId);
      if (servicio == null) return;
      yield SeguimientoVivo(
        estado: servicio.estado,
        posicionDron: servicio.lote.centro,
        hectareasCubiertas: servicio.hectareasCubiertas,
        hectareasDeclaradas: servicio.hectareasDeclaradas,
        trazado: const [],
        etaMinutos: servicio.etaMinutos,
      );
      if (!servicio.estado.activo) return;
      await Future<void>.delayed(intervalo);
    }
  }
}
