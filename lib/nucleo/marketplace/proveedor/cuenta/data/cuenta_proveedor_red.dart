import '../../../../api/marketplace_http.dart';
import '../../../dominio/dominio.dart' show EstadoAprobacion;
import '../domain/cuenta_proveedor.dart';

/// `/api/proveedores/mi`, `/documentos`, `/mi/reenviar` y
/// `/mi/disponibilidad` del contrato vigente.
class CuentaProveedorRed implements CuentaProveedorRepositorio {
  CuentaProveedorRed(this._http);

  final MarketplaceHttp _http;

  static EstadoAprobacion _aprobacion(Object? c) => switch (c) {
    'aprobado' => EstadoAprobacion.aprobado,
    'suspendido' || 'baja' => EstadoAprobacion.suspendido,
    'rechazado' => EstadoAprobacion.rechazado,
    _ => EstadoAprobacion.pendiente,
  };

  static DateTime? _fecha(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static EstadoDisponibilidad disponibilidad(Object? j) {
    final m = j is Map ? j : const {};
    return EstadoDisponibilidad(
      valor: Disponibilidad.deCodigo(m['valor'] as String?),
      cambiadaEn: _fecha(m['cambiada_en']),
      cambiadaPorPropia: m['cambiada_por_propia'] as bool?,
    );
  }

  static DocumentoEnviado documento(Map<dynamic, dynamic> j) =>
      DocumentoEnviado(
        id: (j['id'] as num).toInt(),
        tipo:
            TipoDocumentoProveedor.deCodigo(j['tipo'] as String?) ??
            TipoDocumentoProveedor.otro,
        estado: EstadoDocumentoEnviado.deCodigo(j['estado'] as String?),
        venceEn: _fecha(j['vence_en']),
        motivoRechazo: j['motivo_rechazo'] as String?,
      );

  @override
  Future<EstadoCuentaProveedor> estado() async {
    final mi = await _http.obtener('/api/proveedores/mi');
    final p = Map<String, dynamic>.from(mi['proveedor'] as Map);
    return EstadoCuentaProveedor(
      proveedorId: (p['id'] as num).toInt(),
      aprobacion: _aprobacion(p['estado']),
      motivo: p['motivo_estado'] as String?,
      // Un tipo que la app no conoce se ignora al pintar: el servidor manda.
      documentosFaltantes: [
        for (final d in (mi['documentos_faltantes'] as List? ?? const []))
          ?TipoDocumentoProveedor.deCodigo('$d'),
      ],
      siguientePaso: SiguientePasoProveedor.deCodigo(mi['siguiente_paso']),
      aptoParaOfertas: mi['apto_para_ofertas'] == true,
      disponibilidad: disponibilidad(mi['disponibilidad']),
      disponibilidadEmpresa: disponibilidad(mi['disponibilidad_empresa']),
    );
  }

  @override
  Future<List<DocumentoEnviado>> documentos(int proveedorId) async {
    final r = await _http.obtener(
      '/api/proveedores/documentos',
      query: {'sujeto_tipo': 'proveedor', 'sujeto_id': proveedorId},
    );
    return [
      for (final d in (r['data'] as List? ?? const []))
        documento(d as Map<dynamic, dynamic>),
    ];
  }

  @override
  Future<DocumentoEnviado> subirDocumento(
    int proveedorId,
    DocumentoPorSubir documento,
  ) async {
    final venceEn = documento.venceEn;
    final r = await _http.subir(
      '/api/proveedores/documentos',
      campos: {
        'sujeto_tipo': 'proveedor',
        'sujeto_id': proveedorId,
        'tipo': documento.tipo.codigo,
        if (venceEn != null) 'vence_en': fechaIso(venceEn),
      },
      campoArchivo: 'archivo',
      bytes: documento.bytes,
      nombreArchivo: '${documento.tipo.codigo}.jpg',
    );
    return CuentaProveedorRed.documento(r['documento'] as Map);
  }

  /// `AAAA-MM-DD`, como pide el contrato.
  static String fechaIso(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-'
      '${f.month.toString().padLeft(2, '0')}-'
      '${f.day.toString().padLeft(2, '0')}';

  @override
  Future<void> reenviarARevision() async {
    await _http.enviar('/api/proveedores/mi/reenviar');
  }

  @override
  Future<EstadoDisponibilidad> cambiarDisponibilidad(
    Disponibilidad valor,
  ) async {
    final r = await _http.guardar(
      '/api/proveedores/mi/disponibilidad',
      datos: {'disponibilidad': valor.codigo},
    );
    return disponibilidad(r['disponibilidad']);
  }
}
