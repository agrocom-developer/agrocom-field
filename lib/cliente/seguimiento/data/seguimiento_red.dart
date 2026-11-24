import 'dart:typed_data';

import '../../../nucleo/marketplace/dominio/dominio.dart';
import '../../red/cliente_http.dart';
import '../../red/mapeo_solicitud.dart';
import '../domain/seguimiento.dart';
import '../domain/seguimiento_repositorio.dart';

/// Seguimiento contra la API: avance con fotos
/// (`GET /api/solicitudes/{id}/avance`), última ubicación del piloto
/// (`…/ubicacion-piloto`) y chat (`…/mensajes`, paginado por cursor).
class SeguimientoRed implements SeguimientoRepositorio {
  SeguimientoRed(this._http);

  final ClienteHttp _http;

  @override
  Future<AvanceServicio> avance(String solicitudId) async {
    final r = await _http.obtener('/api/solicitudes/$solicitudId/avance');
    final a = r['avance'];
    if (a is! Map) {
      throw const OperacionRechazada('No encontramos el avance.');
    }
    final registros = <RegistroAvance>[];
    if (a['registros'] is List) {
      for (final g in a['registros'] as List) {
        if (g is! Map) continue;
        final momento = MapeoSolicitud.fecha(g['registrado_en']);
        if (momento == null) continue;
        registros.add(
          RegistroAvance(
            id: '${g['id']}',
            tipo: '${g['tipo']}',
            momento: momento,
            hectareas: MapeoSolicitud.decimalOpcional(
              g['hectareas_ejecutadas'],
            ),
            porcentaje: MapeoSolicitud.decimalOpcional(g['porcentaje']),
            nota: g['nota'] as String?,
          ),
        );
      }
    }
    final notas = {
      for (final g in registros)
        if (g.nota != null) g.id: g.nota!,
    };
    final fotos = <FotoAvance>[];
    if (a['fotos'] is List) {
      for (final f in a['fotos'] as List) {
        if (f is! Map || f['url'] is! String) continue;
        final subida = MapeoSolicitud.fecha(f['subida_en']);
        if (subida == null) continue;
        fotos.add(
          FotoAvance(
            id: '${f['id']}',
            ruta: f['url'] as String,
            subidaEn: subida,
            nota: notas['${f['avance_id']}'],
          ),
        );
      }
    }
    return AvanceServicio(
      hectareasSolicitadas: MapeoSolicitud.decimal(a['hectareas_solicitadas']),
      hectareasEjecutadas: MapeoSolicitud.decimalOpcional(
        a['hectareas_ejecutadas'],
      ),
      porcentaje: MapeoSolicitud.decimalOpcional(a['porcentaje_avance']),
      precioHaAcordado: MapeoSolicitud.decimalOpcional(a['precio_ha_acordado']),
      montoFinal: MapeoSolicitud.decimalOpcional(a['monto_final']),
      iniciadaEn: MapeoSolicitud.fecha(a['iniciada_en']),
      ultimoAvanceEn: MapeoSolicitud.fecha(a['ultimo_avance_en']),
      finalizadaEn: MapeoSolicitud.fecha(a['finalizada_en']),
      registros: registros,
      fotos: fotos,
    );
  }

  @override
  Future<UbicacionPiloto?> ubicacionDelPiloto(String solicitudId) async {
    final r = await _http.obtenerOpcional(
      '/api/solicitudes/$solicitudId/ubicacion-piloto',
    );
    final u = r?['ubicacion'];
    if (u is! Map) return null;
    final lat = double.tryParse('${u['latitud']}');
    final lng = double.tryParse('${u['longitud']}');
    final cuando = MapeoSolicitud.fecha(u['capturado_en']);
    if (lat == null || lng == null || cuando == null) return null;
    return UbicacionPiloto(
      punto: GeoPunto(lat, lng),
      capturadaEn: cuando,
      vigente: u['vigente'] == true,
      precisionMetros: (u['precision_m'] as num?)?.toInt(),
    );
  }

  @override
  Future<PaginaMensajes> mensajes(String solicitudId, {String? despues}) async {
    final r = await _http.obtener(
      '/api/solicitudes/$solicitudId/mensajes',
      query: {'despues': ?despues, 'limite': 50},
    );
    final lista = r['mensajes'];
    return PaginaMensajes(
      mensajes: [
        if (lista is List)
          for (final m in lista)
            if (m is Map) ?_mensaje(Map<String, dynamic>.from(m)),
      ],
      cursor: r['cursor'] == null ? despues : '${r['cursor']}',
      soloLectura: r['solo_lectura'] == true,
    );
  }

  MensajeChat? _mensaje(Map<String, dynamic> m) {
    final creado = MapeoSolicitud.fecha(m['creado_en']);
    if (creado == null) return null;
    return MensajeChat(
      id: '${m['id']}',
      texto: '${m['texto']}',
      creadoEn: creado,
      propio: m['propio'] == true,
      claveCliente: m['uuid_cliente'] as String?,
    );
  }

  @override
  Future<MensajeChat> enviarMensaje(
    String solicitudId, {
    required String texto,
    required String claveCliente,
  }) async {
    final r = await _http.enviar(
      '/api/solicitudes/$solicitudId/mensajes',
      datos: {'uuid_cliente': claveCliente, 'texto': texto.trim()},
    );
    final m = r['mensaje'];
    final mensaje = m is Map ? _mensaje(Map<String, dynamic>.from(m)) : null;
    if (mensaje == null) {
      throw const OperacionRechazada('No pudimos enviar el mensaje.');
    }
    return mensaje;
  }

  @override
  Future<Uint8List> archivo(String ruta) async =>
      Uint8List.fromList(await _http.descargar(ruta));

  @override
  Future<void> marcarLeidos(String solicitudId, String cursor) async {
    await _http.enviar(
      '/api/solicitudes/$solicitudId/mensajes/leidos',
      datos: {'hasta': int.tryParse(cursor) ?? 0},
    );
  }
}
