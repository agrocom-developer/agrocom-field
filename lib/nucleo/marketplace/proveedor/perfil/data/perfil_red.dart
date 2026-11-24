import 'package:decimal/decimal.dart';

import '../../../../api/marketplace_http.dart';
import '../../../dominio/dominio.dart';
import '../../dron/data/drones_red.dart';
import '../../negociacion/data/mapeo_negociacion.dart';
import '../domain/perfil_repositorio.dart';

/// Perfil del proveedor contra la API: `GET /api/auth/sesion`,
/// `/api/proveedores/mi`, `/api/proveedores/drones`, `/api/reputacion` y
/// `/api/calificaciones/recibidas`.
///
/// Una cuenta con rol `piloto` (un piloto de Agrocom, por ejemplo) consulta
/// `proveedores/mi` y `proveedores/drones` en solo lectura: recibe el
/// proveedor al que pertenece. Si una cuenta aún no pertenece a ninguno
/// (`403` o `404`), el perfil muestra a la persona con su reputación y sin
/// drones propios.
class PerfilRed implements PerfilRepositorio {
  PerfilRed(this._http);

  final MarketplaceHttp _http;

  Future<Map<String, dynamic>?> _opcional(String ruta) async {
    try {
      return await _http.obtener(ruta);
    } on OperacionRechazada catch (e) {
      if (e.codigo == 403 || e.codigo == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Proveedor> perfil() async {
    final sesion = await _http.obtener('/api/auth/sesion');
    final usuario = Map<String, dynamic>.from(sesion['usuario'] as Map);
    final mi = await _opcional('/api/proveedores/mi');
    final reputacion = await _opcional('/api/reputacion');
    final promedio = MapeoNegociacion.decimal(
      (reputacion?['reputacion'] as Map?)?['calificacion_promedio'],
    ).toDouble();
    final conteo =
        ((reputacion?['reputacion'] as Map?)?['adjudicadas'] as num?)
            ?.toInt() ??
        0;
    if (mi == null) {
      return Proveedor(
        id: '${usuario['id']}',
        nombre: '${usuario['name']}',
        tipo: TipoProveedor.propioAgrocom,
        calificacion: promedio,
        serviciosCompletados: conteo,
        zonas: const [],
        fotoUrl: usuario['foto_url'] as String?,
      );
    }
    final p = Map<String, dynamic>.from(mi['proveedor'] as Map);
    final drones = await DronesRed(_http).leer();
    return Proveedor(
      id: '${p['id']}',
      nombre: '${p['razon_social'] ?? usuario['name']}',
      tipo: switch (p['tipo']) {
        'independiente' => TipoProveedor.independiente,
        'tercero' => TipoProveedor.duenoDeDrones,
        _ => TipoProveedor.propioAgrocom,
      },
      calificacion: MapeoNegociacion.decimal(
        p['calificacion_promedio'],
      ).toDouble(),
      serviciosCompletados: conteo,
      zonas: const [],
      drones: drones,
      fotoUrl: usuario['foto_url'] as String?,
      aprobacion: switch (p['estado']) {
        'aprobado' => EstadoAprobacion.aprobado,
        'suspendido' || 'baja' => EstadoAprobacion.suspendido,
        'rechazado' => EstadoAprobacion.rechazado,
        _ => EstadoAprobacion.pendiente,
      },
      motivoAprobacion: p['motivo_estado'] as String?,
      documentos: [
        for (final d in (mi['documentos_faltantes'] as List? ?? const []))
          DocumentoProveedor(
            nombre: '$d'.replaceAll('_', ' '),
            estado: EstadoDocumento.rechazado,
            motivoRechazo: 'Falta cargarlo o renovarlo.',
          ),
      ],
    );
  }

  @override
  Future<List<HectareasMensuales>> hectareasPorMes() async => const [];

  @override
  Future<List<Servicio>> historial() async => const [];

  @override
  Future<MetricasProveedor> metricas() async {
    final r = await _opcional('/api/reputacion');
    final rep = Map<String, dynamic>.from(
      (r?['reputacion'] as Map?) ?? const <String, dynamic>{},
    );
    final tasa = MapeoNegociacion.decimal(rep['tasa_cancelacion']);
    return MetricasProveedor(
      serviciosCompletados: (rep['adjudicadas'] as num?)?.toInt() ?? 0,
      hectareasAtendidas: Decimal.zero,
      // La aceptación no existe en la negociación: ya no hay ofertas que se
      // acepten o rechacen por tiempo.
      tasaAceptacion: 0,
      tasaCancelacion: (tasa * Decimal.fromInt(100)).round().toBigInt().toInt(),
    );
  }

  @override
  Future<ResumenCalificaciones> calificaciones() async {
    final r = await _opcional('/api/calificaciones/recibidas');
    if (r == null) {
      return const ResumenCalificaciones(promedio: 0, total: 0, recientes: []);
    }
    final resumen = Map<String, dynamic>.from(
      (r['resumen'] as Map?) ?? const <String, dynamic>{},
    );
    final porEstrellas = <int, int>{};
    ((resumen['por_estrellas'] as Map?) ?? const {}).forEach((k, v) {
      final estrellas = int.tryParse('$k');
      if (estrellas != null) porEstrellas[estrellas] = (v as num).toInt();
    });
    return ResumenCalificaciones(
      promedio: MapeoNegociacion.decimal(
        resumen['calificacion_promedio'],
      ).toDouble(),
      total: (resumen['calificaciones_conteo'] as num?)?.toInt() ?? 0,
      porPuntaje: porEstrellas,
      recientes: [
        for (final c in (r['calificaciones'] as List? ?? const []))
          CalificacionRecibida(
            servicioId: '${(c as Map)['solicitud_id']}',
            autor: 'Cliente',
            puntaje: (c['estrellas'] as num?)?.toInt() ?? 0,
            fecha: MapeoNegociacion.fecha(c['creada_en']) ?? DateTime.now(),
            comentario: c['comentario'] as String?,
          ),
      ],
    );
  }
}
