import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../../red/fuente_solicitudes.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/problema_repositorio.dart';

/// Problemas que el cliente reporta, contra las disputas de la API
/// (`/api/solicitudes/{id}/disputas` y `/disputa`). Hay una por servicio: si
/// ya existe, abrirla de nuevo devuelve la misma.
class ProblemaRed implements ProblemaRepositorio {
  ProblemaRed(this._http, this._fuente);

  final ClienteHttp _http;
  final FuenteSolicitudes _fuente;

  static const _motivosApi = {
    MotivoProblema.coberturaIncompleta: 'cobertura_incompleta',
    MotivoProblema.malaAplicacion: 'mala_aplicacion',
    MotivoProblema.danoCultivos: 'dano_a_cultivos_o_terceros',
    MotivoProblema.productoDistinto: 'producto_distinto',
    MotivoProblema.equipoAusente: 'equipo_ausente',
    MotivoProblema.evidenciaFaltante: 'evidencia_faltante',
    MotivoProblema.cobroIndebido: 'cobro_indebido',
    MotivoProblema.tratoInadecuado: 'trato_inadecuado',
  };

  @override
  Future<ProblemaReportado?> delServicio(String servicioId) async {
    final r = await _http.obtenerOpcional(
      '/api/solicitudes/$servicioId/disputa',
    );
    final d = r?['disputa'];
    return d is Map ? _problema(Map<String, dynamic>.from(d)) : null;
  }

  @override
  Future<ProblemaReportado> reportar(ReporteProblema reporte) async {
    final r = await _http.enviar(
      '/api/solicitudes/${reporte.servicioId}/disputas',
      datos: {
        'motivo': _motivosApi[reporte.motivo],
        'detalle': reporte.detalle.trim(),
      },
      conflictoComoExito: true,
    );
    final d = r['disputa'];
    final ProblemaReportado caso;
    if (d is Map) {
      caso = _problema(Map<String, dynamic>.from(d));
    } else {
      // 409: el servicio ya tenía una disputa; esa es la que se devuelve.
      final previo = await delServicio(reporte.servicioId);
      if (previo == null) {
        throw const OperacionRechazada(
          'No pudimos registrar el problema. Intenta de nuevo.',
        );
      }
      caso = previo;
    }
    await _fuente.invalidar();
    return caso;
  }

  ProblemaReportado _problema(Map<String, dynamic> d) {
    final motivo = _motivosApi.entries
        .where((e) => e.value == d['motivo'])
        .map((e) => e.key)
        .firstOrNull;
    return ProblemaReportado(
      numeroCaso: 'D-${d['id']}',
      servicioId: '${d['solicitud_id']}',
      motivo: motivo ?? MotivoProblema.coberturaIncompleta,
      detalle: '${d['detalle']}',
      abiertoEn: MapeoSolicitud.fecha(d['creada_en']) ?? DateTime.now(),
      estado: switch (d['estado']) {
        'en_revision' => EstadoProblema.enRevision,
        'resuelta' || 'retirada' => EstadoProblema.resuelto,
        _ => EstadoProblema.abierto,
      },
    );
  }
}
