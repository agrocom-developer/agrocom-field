import 'package:decimal/decimal.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../../red/fuente_servicios.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/conformidad_repositorio.dart';

/// Acta de conformidad armada con la solicitud del servidor.
///
/// La API no entrega al cliente un acta ni evidencias: el estado del acta
/// sale del estado de la solicitud (`ejecutada` espera la firma,
/// `en_disputa` está observada, `completada` está firmada), y las fechas, del
/// historial. Firmar es `POST /api/solicitudes/{id}/conformidad`, que es
/// idempotente. Las evidencias quedan vacías hasta que el contrato las
/// exponga (ver `docs/gestion/brechas-api.md`).
class ConformidadRed implements ConformidadRepositorio {
  ConformidadRed(this._http, this._fuente);

  final ClienteHttp _http;
  final FuenteServicios _fuente;

  /// Plazo de conformidad tácita desde que el servicio queda ejecutado
  /// (72 horas por defecto en el servidor).
  static const plazoConformidad = Duration(hours: 72);

  @override
  Future<ExpedienteServicio> expediente(String servicioId) async {
    final crudo = await _fuente.crudo(servicioId);
    final acta = actaDe(crudo);
    return acta == null
        ? ExpedienteServicio.vacio
        : ExpedienteServicio(acta: acta, evidencias: const []);
  }

  @override
  Future<ActaConformidad> firmar({
    required String servicioId,
    required String claveIdempotencia,
  }) async {
    // El servidor es idempotente: firmar dos veces devuelve la misma
    // solicitud completada, así que la clave del cliente no se envía.
    final r = await _http.enviar('/api/solicitudes/$servicioId/conformidad');
    final s = r['solicitud'];
    if (s is! Map) {
      throw const OperacionRechazada('No pudimos registrar tu conformidad.');
    }
    final acta = actaDe(Map<String, dynamic>.from(s));
    if (acta == null) {
      throw const OperacionRechazada('Este servicio todavía no tiene acta.');
    }
    await _fuente.invalidar();
    return acta;
  }

  /// El acta que corresponde a la solicitud, o `null` si el servicio aún no
  /// llegó a ejecutarse.
  static ActaConformidad? actaDe(Map<String, dynamic> j) {
    final estado = switch (j['estado']) {
      'ejecutada' => EstadoActa.pendiente,
      'en_disputa' => EstadoActa.observada,
      'completada' => EstadoActa.firmada,
      _ => null,
    };
    if (estado == null) return null;

    final (producto, dosis) = MapeoSolicitud.productoYDosis(
      '${j['producto_indicado']}',
    );
    final solicitadas = MapeoSolicitud.decimal(j['hectareas_solicitadas']);
    final tarifa = MapeoSolicitud.decimal(j['tarifa_hectarea']);
    final montoFinal = j['monto_final'];
    // Con el monto final congelado, las hectáreas confirmadas son las
    // facturadas: monto final entre tarifa por hectárea.
    final confirmadas = montoFinal != null && tarifa > Decimal.zero
        ? (MapeoSolicitud.decimal(montoFinal) / tarifa)
              .toDecimal(scaleOnInfinitePrecision: 4)
              .round(scale: 2)
        : solicitadas;

    final inicio =
        MapeoSolicitud.momentoDe(j, 'en_ejecucion') ??
        MapeoSolicitud.momentoDe(j, 'borrador') ??
        DateTime.now();
    final fin = MapeoSolicitud.momentoDe(j, 'ejecutada') ?? inicio;
    final terreno = j['terreno'];
    final lugar = terreno is Map ? ' sobre ${terreno['nombre']}' : '';
    return ActaConformidad(
      servicioId: '${j['id']}',
      estado: estado,
      hectareasConfirmadas: confirmadas,
      litrosAplicados: dosis * confirmadas,
      inicio: inicio,
      fin: fin,
      resumen: 'Aplicación de $producto$lugar.',
      venceConformidad: fin.add(plazoConformidad),
      firmadaEn: estado == EstadoActa.firmada
          ? MapeoSolicitud.momentoDe(j, 'completada')
          : null,
    );
  }
}
