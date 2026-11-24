import 'package:uuid/uuid.dart';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../../red/fuente_solicitudes.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/calificacion_repositorio.dart';

/// Calificaciones del cliente contra la API.
///
/// - Escribir: `POST /api/solicitudes/{id}/calificaciones` (solo al
///   proveedor; el cliente no califica al piloto ni al auxiliar desde esta
///   pantalla). El `uuid_cliente` se deriva del servicio, así que un
///   reintento es el mismo registro y el servidor responde `409` o `200`.
/// - Leer lo emitido: `GET /api/solicitudes/{id}/calificaciones`.
/// - Lo que el cliente recibe: el promedio de su ficha. Las calificaciones
///   de los proveedores al cliente son privadas y no llegan a la app.
class CalificacionRed implements CalificacionRepositorio {
  CalificacionRed(this._http, this._fuente, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final ClienteHttp _http;
  final FuenteSolicitudes _fuente;
  final Uuid _uuid;

  static const _etiquetasApi = {
    EtiquetaCalificacion.puntualidad: 'puntualidad',
    EtiquetaCalificacion.coberturaPareja: 'cobertura_pareja',
    EtiquetaCalificacion.comunicacion: 'comunicacion',
    EtiquetaCalificacion.cuidadoDelEntorno: 'cuidado_entorno',
    EtiquetaCalificacion.ordenEnElLote: 'orden_lote',
  };

  @override
  Future<void> calificarProveedor({
    required String servicioId,
    required int puntaje,
    Set<EtiquetaCalificacion> etiquetas = const {},
    String? comentario,
  }) async {
    final texto = comentario?.trim();
    await _http.enviar(
      '/api/solicitudes/$servicioId/calificaciones',
      datos: {
        'calificaciones': [
          {
            'uuid_cliente': _uuid.v5(
              Namespace.url.value,
              'calificacion-proveedor-$servicioId',
            ),
            'sujeto_tipo': 'proveedor',
            'estrellas': puntaje,
            'etiquetas': [for (final e in etiquetas) _etiquetasApi[e]!],
            if (texto != null && texto.isNotEmpty) 'comentario': texto,
          },
        ],
      },
      // Ya calificado: repetir la llamada no cambia nada.
      conflictoComoExito: true,
    );
    _fuente.registrarPuntaje(servicioId, puntaje);
    await _fuente.invalidar();
  }

  @override
  Future<CalificacionEmitida?> emitida(String servicioId) async {
    final r = await _http.obtener(
      '/api/solicitudes/$servicioId/calificaciones',
    );
    final sujetos = r['sujetos'];
    if (sujetos is! List) return null;
    for (final s in sujetos) {
      if (s is! Map || s['tipo'] != 'proveedor') continue;
      final c = s['calificacion'];
      if (c is! Map) return null;
      final etiquetas = <EtiquetaCalificacion>{};
      final crudas = c['etiquetas'];
      if (crudas is List) {
        for (final e in _etiquetasApi.entries) {
          if (crudas.contains(e.value)) etiquetas.add(e.key);
        }
      }
      return CalificacionEmitida(
        servicioId: servicioId,
        puntaje: (c['estrellas'] as int?) ?? 0,
        etiquetas: etiquetas,
        fecha: MapeoSolicitud.fecha(c['creada_en']) ?? DateTime.now(),
        comentario: c['comentario'] as String?,
      );
    }
    return null;
  }

  @override
  Future<ResumenCalificaciones> recibidas() async {
    final r = await _http.obtener('/api/clientes/mi');
    final cliente = r['cliente'];
    if (cliente is! Map) {
      return const ResumenCalificaciones(promedio: 0, total: 0, recientes: []);
    }
    return ResumenCalificaciones(
      promedio: double.tryParse('${cliente['calificacion_promedio']}') ?? 0,
      total: (cliente['calificaciones_conteo'] as int?) ?? 0,
      recientes: const [],
    );
  }
}
